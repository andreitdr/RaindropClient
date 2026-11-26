#include "raindrop_shell.h"

#include <flutter/standard_method_codec.h>
#include <shellapi.h>

#include <utility>
#include <variant>

#include "resource.h"

namespace {

// The message the notification-area icon sends the window.
constexpr UINT kTrayMessage = WM_APP + 1;
constexpr UINT kTrayIconId = 1;

// The icon menu's commands.
enum MenuCommand : UINT {
  kOpen = 1,
  kMute,
  kDeafen,
  kLeave,
  kSettings,
  kQuit,
};

std::wstring Utf16FromUtf8(const std::string& utf8) {
  if (utf8.empty()) {
    return std::wstring();
  }
  const int length = ::MultiByteToWideChar(
      CP_UTF8, MB_ERR_INVALID_CHARS, utf8.data(),
      static_cast<int>(utf8.size()), nullptr, 0);
  if (length <= 0) {
    return std::wstring();
  }
  std::wstring utf16(static_cast<size_t>(length), L'\0');
  ::MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, utf8.data(),
                        static_cast<int>(utf8.size()), utf16.data(), length);
  return utf16;
}

const flutter::EncodableValue* Lookup(const flutter::EncodableMap& map,
                                      const char* key) {
  const auto found = map.find(flutter::EncodableValue(key));
  return found == map.end() ? nullptr : &found->second;
}

// Reads leniently, as every platform does: a missing or mistyped key is the
// quiet default, so a newer Dart side never breaks an older runner.
std::string StringAt(const flutter::EncodableMap& map, const char* key,
                     const std::string& fallback) {
  const flutter::EncodableValue* value = Lookup(map, key);
  const auto* string = value ? std::get_if<std::string>(value) : nullptr;
  return string ? *string : fallback;
}

bool BoolAt(const flutter::EncodableMap& map, const char* key, bool fallback) {
  const flutter::EncodableValue* value = Lookup(map, key);
  const auto* boolean = value ? std::get_if<bool>(value) : nullptr;
  return boolean ? *boolean : fallback;
}

void AppendItem(HMENU menu, UINT command, const std::wstring& title,
                UINT flags = MF_STRING) {
  ::AppendMenuW(menu, flags, command, title.c_str());
}

}  // namespace

RaindropShell::RaindropShell(HWND window, flutter::BinaryMessenger* messenger)
    : window_(window) {
  const auto& codec = flutter::StandardMethodCodec::GetInstance();

  residency_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "raindrop/residency", &codec);
  residency_->SetMethodCallHandler([this](const auto& call, auto result) {
    HandleResidency(call, std::move(result));
  });

  calls_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "raindrop/call_session", &codec);
  calls_->SetMethodCallHandler([this](const auto& call, auto result) {
    HandleCall(call, std::move(result));
  });

  // The app's own icon, at the size the notification area draws.
  icon_ = static_cast<HICON>(::LoadImageW(
      ::GetModuleHandleW(nullptr), MAKEINTRESOURCEW(IDI_APP_ICON), IMAGE_ICON,
      ::GetSystemMetrics(SM_CXSMICON), ::GetSystemMetrics(SM_CYSMICON),
      LR_DEFAULTCOLOR));
  taskbar_created_ = ::RegisterWindowMessageW(L"TaskbarCreated");

  Render();
}

RaindropShell::~RaindropShell() {
  if (icon_added_) {
    NOTIFYICONDATAW data = {};
    data.cbSize = sizeof(data);
    data.hWnd = window_;
    data.uID = kTrayIconId;
    ::Shell_NotifyIconW(NIM_DELETE, &data);
  }
  if (icon_) {
    ::DestroyIcon(icon_);
  }
  if (residency_) {
    residency_->SetMethodCallHandler(nullptr);
  }
  if (calls_) {
    calls_->SetMethodCallHandler(nullptr);
  }
}

std::optional<LRESULT> RaindropShell::HandleMessage(HWND hwnd, UINT message,
                                                    WPARAM wparam,
                                                    LPARAM lparam) {
  if (taskbar_created_ != 0 && message == taskbar_created_) {
    icon_added_ = false;
    Render();
    return std::nullopt;
  }

  switch (message) {
    // The close button, Alt+F4, the taskbar's Close window: hidden while the
    // app is to keep running. Otherwise - or when quitting - Flutter gets
    // the close, and turns it into its exit request.
    case WM_CLOSE:
      if (keep_running_ && !quitting_) {
        ::ShowWindow(hwnd, SW_HIDE);
        return 0;
      }
      return std::nullopt;

    case kTrayMessage:
      switch (LOWORD(lparam)) {
        case WM_LBUTTONUP:
          ShowWindowAgain();
          return 0;
        case WM_RBUTTONUP:
        case WM_CONTEXTMENU:
          ShowMenu();
          return 0;
      }
      return 0;
  }
  return std::nullopt;
}

void RaindropShell::HandleResidency(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (call.method_name() == "setKeepRunning") {
    const auto* arguments = std::get_if<flutter::EncodableMap>(call.arguments());
    keep_running_ = arguments ? BoolAt(*arguments, "keep", true) : true;
    Render();
    result->Success();
    return;
  }
  result->NotImplemented();
}

void RaindropShell::HandleCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string& method = call.method_name();
  if (method == "begin" || method == "update") {
    const auto* arguments = std::get_if<flutter::EncodableMap>(call.arguments());
    Call next;
    if (arguments) {
      next.title = Utf16FromUtf8(
          StringAt(*arguments, "title", "In a voice call"));
      next.body = Utf16FromUtf8(StringAt(*arguments, "body", ""));
      next.mic_on = BoolAt(*arguments, "micOn", true);
      next.deafened = BoolAt(*arguments, "deafened", false);
      next.reconnecting = BoolAt(*arguments, "reconnecting", false);
    } else {
      next.title = L"In a voice call";
    }
    call_ = std::move(next);
    Render();
    result->Success();
    return;
  }
  if (method == "end") {
    call_.reset();
    Render();
    result->Success();
    return;
  }
  result->NotImplemented();
}

void RaindropShell::Render() {
  // The icon is there while the app keeps running with its window closed,
  // and during a call whatever that setting says: the call is shown in it.
  const bool wanted = keep_running_ || call_.has_value();

  NOTIFYICONDATAW data = {};
  data.cbSize = sizeof(data);
  data.hWnd = window_;
  data.uID = kTrayIconId;

  if (!wanted) {
    if (icon_added_) {
      ::Shell_NotifyIconW(NIM_DELETE, &data);
      icon_added_ = false;
    }
    return;
  }

  data.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
  data.uCallbackMessage = kTrayMessage;
  data.hIcon = icon_;
  const std::wstring tip = Tooltip();
  wcsncpy_s(data.szTip, ARRAYSIZE(data.szTip), tip.c_str(), _TRUNCATE);

  if (icon_added_) {
    ::Shell_NotifyIconW(NIM_MODIFY, &data);
  } else {
    icon_added_ = ::Shell_NotifyIconW(NIM_ADD, &data) != FALSE;
  }
}

std::wstring RaindropShell::Tooltip() const {
  if (!call_) {
    return L"Raindrop";
  }
  std::wstring tip = L"Raindrop — ";
  tip += call_->reconnecting ? L"Reconnecting…" : call_->title;
  if (!call_->body.empty()) {
    tip += L" (" + call_->body + L")";
  }
  if (call_->deafened) {
    tip += L", deafened";
  } else if (!call_->mic_on) {
    tip += L", muted";
  }
  return tip;
}

void RaindropShell::ShowMenu() {
  HMENU menu = ::CreatePopupMenu();
  if (!menu) {
    return;
  }

  AppendItem(menu, kOpen, L"Open Raindrop");
  ::SetMenuDefaultItem(menu, kOpen, FALSE);

  if (call_) {
    AppendItem(menu, 0, L"", MF_SEPARATOR);
    AppendItem(menu, 0, call_->title, MF_STRING | MF_GRAYED);
    if (!call_->body.empty()) {
      AppendItem(menu, 0, call_->body, MF_STRING | MF_GRAYED);
    }
    AppendItem(menu, kMute, call_->mic_on ? L"Mute" : L"Unmute");
    AppendItem(menu, kDeafen, call_->deafened ? L"Undeafen" : L"Deafen");
    AppendItem(menu, kLeave, L"Leave call");
  }

  AppendItem(menu, 0, L"", MF_SEPARATOR);
  AppendItem(menu, kSettings, L"Settings…");
  AppendItem(menu, kQuit, L"Quit Raindrop");

  // Without this the menu does not close when clicking elsewhere.
  POINT cursor;
  ::GetCursorPos(&cursor);
  ::SetForegroundWindow(window_);
  const UINT command = static_cast<UINT>(::TrackPopupMenu(
      menu, TPM_RETURNCMD | TPM_RIGHTBUTTON | TPM_NONOTIFY, cursor.x, cursor.y,
      0, window_, nullptr));
  ::PostMessageW(window_, WM_NULL, 0, 0);
  ::DestroyMenu(menu);

  switch (command) {
    case kOpen:
      ShowWindowAgain();
      break;
    case kMute:
      SendAction("toggleMute");
      break;
    case kDeafen:
      SendAction("toggleDeafen");
      break;
    case kLeave:
      SendAction("leave");
      break;
    case kSettings:
      ShowWindowAgain();
      residency_->InvokeMethod(
          "command", std::make_unique<flutter::EncodableValue>("openSettings"));
      break;
    case kQuit:
      Quit();
      break;
  }
}

void RaindropShell::ShowWindowAgain() {
  ::ShowWindow(window_, ::IsIconic(window_) ? SW_RESTORE : SW_SHOW);
  ::SetForegroundWindow(window_);
}

void RaindropShell::Quit() {
  quitting_ = true;
  ::PostMessageW(window_, WM_CLOSE, 0, 0);
}

void RaindropShell::SendAction(const char* action) {
  calls_->InvokeMethod("action",
                       std::make_unique<flutter::EncodableValue>(action));
}
