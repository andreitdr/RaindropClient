#ifndef RUNNER_RAINDROP_SHELL_H_
#define RUNNER_RAINDROP_SHELL_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <windows.h>

#include <memory>
#include <optional>
#include <string>

// Raindrop outside its window on Windows: what closing the window does, and
// the icon in the notification area, which shows the call while one is up.
//
// Dart decides; this only carries it out, over two channels:
//
// * `raindrop/residency` - `setKeepRunning` (whether closing the window hides
//   it rather than quitting) from Dart, and `command` (`openSettings`) back.
//   See lib/core/platform/app_residency.dart.
// * `raindrop/call_session` - `begin`/`update` with the call's description,
//   and `end`, from Dart; `action` (`toggleMute`, `toggleDeafen`, `leave`)
//   back. See lib/core/voice/call_session_host.dart.
//
// Nothing here quits or hangs up by itself. Quit closes the window for real,
// which Flutter turns into its exit request - where the call controller
// leaves the call first - and Leave is sent to Dart like a button press.
class RaindropShell {
 public:
  RaindropShell(HWND window, flutter::BinaryMessenger* messenger);
  ~RaindropShell();

  RaindropShell(const RaindropShell&) = delete;
  RaindropShell& operator=(const RaindropShell&) = delete;

  // Gives the shell the main window's |message| before Flutter sees it.
  // Returns a result when the shell handled it.
  std::optional<LRESULT> HandleMessage(HWND hwnd, UINT message, WPARAM wparam,
                                       LPARAM lparam);

 private:
  // The call as Dart last described it.
  struct Call {
    std::wstring title;
    std::wstring body;
    bool mic_on = true;
    bool deafened = false;
    bool reconnecting = false;
  };

  void HandleResidency(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void HandleCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Adds, updates or removes the icon to match |keep_running_| and |call_|.
  void Render();
  std::wstring Tooltip() const;
  void ShowMenu();
  void ShowWindowAgain();
  void Quit();
  void SendAction(const char* action);

  HWND window_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> residency_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> calls_;

  // On until Dart says otherwise, which it does at startup: that is the
  // setting's default, so a window closed in the moment before is not a
  // surprise quit.
  bool keep_running_ = true;

  // Set by Quit, so that the close it sends is let through to Flutter.
  bool quitting_ = false;

  std::optional<Call> call_;
  bool icon_added_ = false;
  HICON icon_ = nullptr;

  // Explorer restarting forgets every notification-area icon; it broadcasts
  // this when it is back, and the icon is added again.
  UINT taskbar_created_ = 0;
};

#endif  // RUNNER_RAINDROP_SHELL_H_
