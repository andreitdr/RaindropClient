#include "raindrop_shell.h"

#include <dlfcn.h>

#include <string>

namespace {

// ── libayatana-appindicator3, when it is there ──────────────────────────────

// Its own types and values, declared here because its headers are not needed
// to build: the library is opened at runtime.
typedef struct _AppIndicator AppIndicator;
constexpr int kCategoryCommunications = 1;  // APP_INDICATOR_CATEGORY_COMMUNICATIONS
constexpr int kStatusPassive = 0;           // APP_INDICATOR_STATUS_PASSIVE
constexpr int kStatusActive = 1;            // APP_INDICATOR_STATUS_ACTIVE

struct Indicators {
  AppIndicator* (*create)(const gchar* id, const gchar* icon, int category);
  void (*set_status)(AppIndicator* indicator, int status);
  void (*set_menu)(AppIndicator* indicator, GtkMenu* menu);
  void (*set_label)(AppIndicator* indicator, const gchar* label,
                    const gchar* guide);
  void (*set_title)(AppIndicator* indicator, const gchar* title);
};

// Opens the library once. False, for good, where it is not installed.
bool LoadIndicators(Indicators* out) {
  static bool tried = false;
  static bool loaded = false;
  static Indicators found = {};
  if (!tried) {
    tried = true;
    void* library = dlopen("libayatana-appindicator3.so.1", RTLD_LAZY);
    if (library == nullptr) {
      library = dlopen("libappindicator3.so.1", RTLD_LAZY);
    }
    if (library != nullptr) {
      found.create = reinterpret_cast<decltype(found.create)>(
          dlsym(library, "app_indicator_new"));
      found.set_status = reinterpret_cast<decltype(found.set_status)>(
          dlsym(library, "app_indicator_set_status"));
      found.set_menu = reinterpret_cast<decltype(found.set_menu)>(
          dlsym(library, "app_indicator_set_menu"));
      found.set_label = reinterpret_cast<decltype(found.set_label)>(
          dlsym(library, "app_indicator_set_label"));
      found.set_title = reinterpret_cast<decltype(found.set_title)>(
          dlsym(library, "app_indicator_set_title"));
      loaded = found.create != nullptr && found.set_status != nullptr &&
               found.set_menu != nullptr && found.set_label != nullptr &&
               found.set_title != nullptr;
    }
  }
  if (loaded) *out = found;
  return loaded;
}

// Whether the desktop is showing tray icons at all: some program is the
// StatusNotifierWatcher, and a host has registered with it. GNOME's
// AppIndicator extension still registers the older org.kde name, so both are
// asked.
bool HasTrayHost() {
  g_autoptr(GDBusConnection) bus =
      g_bus_get_sync(G_BUS_TYPE_SESSION, nullptr, nullptr);
  if (bus == nullptr) return false;
  for (const char* name :
       {"org.kde.StatusNotifierWatcher",
        "org.freedesktop.StatusNotifierWatcher"}) {
    g_autoptr(GVariant) reply = g_dbus_connection_call_sync(
        bus, name, "/StatusNotifierWatcher", "org.freedesktop.DBus.Properties",
        "Get", g_variant_new("(ss)", name, "IsStatusNotifierHostRegistered"),
        G_VARIANT_TYPE("(v)"), G_DBUS_CALL_FLAGS_NO_AUTO_START, 500, nullptr,
        nullptr);
    if (reply == nullptr) continue;
    g_autoptr(GVariant) value = nullptr;
    g_variant_get(reply, "(v)", &value);
    if (g_variant_is_of_type(value, G_VARIANT_TYPE_BOOLEAN) &&
        g_variant_get_boolean(value)) {
      return true;
    }
  }
  return false;
}

// ── The shell's state ────────────────────────────────────────────────────────

// The call as Dart last described it.
struct Call {
  std::string title;
  std::string body;
  gint64 connected_at_ms = 0;  // 0 before it has connected
  bool mic_on = true;
  bool deafened = false;
  bool reconnecting = false;
};

struct Shell {
  GtkWindow* window = nullptr;
  FlMethodChannel* residency = nullptr;
  FlMethodChannel* calls = nullptr;

  // On until Dart says otherwise, which it does at startup: that is the
  // setting's default, so a window closed in the moment before is not a
  // surprise quit.
  bool keep_running = true;

  // Set by Quit, so that the close it sends is let through to Flutter.
  bool quitting = false;

  bool in_call = false;
  Call call;

  Indicators api = {};
  AppIndicator* indicator = nullptr;

  // Redraws the tray's call timer once a second while it shows one.
  guint clock = 0;
};

Shell* shell = nullptr;

// ── Reading what Dart sent ───────────────────────────────────────────────────

// Read leniently, as every platform does: a missing or mistyped key is the
// quiet default, so a newer Dart side never breaks an older runner.
std::string StringAt(FlValue* map, const char* key, const char* fallback) {
  FlValue* value = fl_value_lookup_string(map, key);
  return value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_STRING
             ? fl_value_get_string(value)
             : fallback;
}

bool BoolAt(FlValue* map, const char* key, bool fallback) {
  FlValue* value = fl_value_lookup_string(map, key);
  return value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_BOOL
             ? fl_value_get_bool(value)
             : fallback;
}

gint64 IntAt(FlValue* map, const char* key) {
  FlValue* value = fl_value_lookup_string(map, key);
  return value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_INT
             ? fl_value_get_int(value)
             : 0;
}

// ── The window ───────────────────────────────────────────────────────────────

void ShowWindow() { gtk_window_present(shell->window); }

// Through Flutter's exit request, like any other close: the call is left
// first.
void Quit() {
  shell->quitting = true;
  gtk_window_close(shell->window);
}

// The close button, Alt+F4, the window list's Close. Returning TRUE keeps the
// window; FALSE lets the close through to Flutter, which turns it into its
// exit request.
gboolean OnDelete(GtkWidget* widget, GdkEvent* event, gpointer data) {
  if (!shell->keep_running || shell->quitting) return FALSE;
  if (shell->indicator != nullptr && HasTrayHost()) {
    gtk_widget_hide(widget);
    return TRUE;
  }
  // No tray to come back from: a call is kept going in a minimised window,
  // and with no call the close is just a close.
  if (shell->in_call) {
    gtk_window_iconify(GTK_WINDOW(widget));
    return TRUE;
  }
  return FALSE;
}

// ── Telling Dart ─────────────────────────────────────────────────────────────

void Send(FlMethodChannel* channel, const char* method, const char* argument) {
  if (channel == nullptr) return;
  g_autoptr(FlValue) value = fl_value_new_string(argument);
  fl_method_channel_invoke_method(channel, method, value, nullptr, nullptr,
                                  nullptr);
}

void OnOpen(GtkMenuItem* item, gpointer data) { ShowWindow(); }
void OnMute(GtkMenuItem* item, gpointer data) {
  Send(shell->calls, "action", "toggleMute");
}
void OnDeafen(GtkMenuItem* item, gpointer data) {
  Send(shell->calls, "action", "toggleDeafen");
}
void OnLeave(GtkMenuItem* item, gpointer data) {
  Send(shell->calls, "action", "leave");
}
void OnSettings(GtkMenuItem* item, gpointer data) {
  ShowWindow();
  Send(shell->residency, "command", "openSettings");
}
void OnQuit(GtkMenuItem* item, gpointer data) { Quit(); }

// ── The tray ─────────────────────────────────────────────────────────────────

GtkWidget* AddItem(GtkWidget* menu, const std::string& title, GCallback action) {
  GtkWidget* item = gtk_menu_item_new_with_label(title.c_str());
  if (action != nullptr) {
    g_signal_connect(item, "activate", action, nullptr);
  } else {
    gtk_widget_set_sensitive(item, FALSE);
  }
  gtk_menu_shell_append(GTK_MENU_SHELL(menu), item);
  return item;
}

void AddSeparator(GtkWidget* menu) {
  gtk_menu_shell_append(GTK_MENU_SHELL(menu), gtk_separator_menu_item_new());
}

GtkMenu* BuildMenu() {
  GtkWidget* menu = gtk_menu_new();
  AddItem(menu, "Open Raindrop", G_CALLBACK(OnOpen));
  if (shell->in_call) {
    AddSeparator(menu);
    AddItem(menu, shell->call.title, nullptr);
    if (!shell->call.body.empty()) AddItem(menu, shell->call.body, nullptr);
    AddItem(menu, shell->call.mic_on ? "Mute" : "Unmute", G_CALLBACK(OnMute));
    AddItem(menu, shell->call.deafened ? "Undeafen" : "Deafen",
            G_CALLBACK(OnDeafen));
    AddItem(menu, "Leave call", G_CALLBACK(OnLeave));
  }
  AddSeparator(menu);
  AddItem(menu, "Settings\xE2\x80\xA6", G_CALLBACK(OnSettings));
  AddItem(menu, "Quit Raindrop", G_CALLBACK(OnQuit));
  gtk_widget_show_all(menu);
  return GTK_MENU(menu);
}

// The call's time, beside the icon where the tray draws labels (KDE Plasma,
// Ubuntu's): `4:07`, or `1:02:33` past the hour.
std::string Elapsed() {
  if (shell->call.reconnecting) return "Reconnecting\xE2\x80\xA6";
  if (shell->call.connected_at_ms <= 0) return "0:00";
  const gint64 now_ms = g_get_real_time() / 1000;
  const gint64 seconds =
      MAX(static_cast<gint64>(0), (now_ms - shell->call.connected_at_ms) / 1000);
  const gint64 hours = seconds / 3600;
  const gint64 minutes = (seconds % 3600) / 60;
  const gint64 rest = seconds % 60;
  g_autofree gchar* text =
      hours > 0 ? g_strdup_printf("%" G_GINT64_FORMAT ":%02" G_GINT64_FORMAT
                                  ":%02" G_GINT64_FORMAT,
                                  hours, minutes, rest)
                : g_strdup_printf("%" G_GINT64_FORMAT ":%02" G_GINT64_FORMAT,
                                  minutes, rest);
  return text;
}

void DrawLabel() {
  if (shell->indicator == nullptr) return;
  if (shell->in_call) {
    shell->api.set_label(shell->indicator, Elapsed().c_str(), "0:00:00");
  } else {
    shell->api.set_label(shell->indicator, nullptr, nullptr);
  }
}

gboolean OnClock(gpointer data) {
  DrawLabel();
  return G_SOURCE_CONTINUE;
}

// The tray icon's file, installed beside the app (linux/CMakeLists.txt), as
// a full path: the indicator takes a file where it is not a theme's icon.
std::string IconPath() {
  g_autofree gchar* executable = g_file_read_link("/proc/self/exe", nullptr);
  if (executable == nullptr) return "raindrop";
  g_autofree gchar* directory = g_path_get_dirname(executable);
  g_autofree gchar* path = g_build_filename(directory, "data", "tray",
                                            "raindrop-tray.png", nullptr);
  return path;
}

// Shows, updates or hides the tray icon to match |keep_running| and the call.
void Render() {
  // The icon is there while the app keeps running with its window closed,
  // and during a call whatever that setting says: the call is shown in it.
  const bool wanted = shell->keep_running || shell->in_call;

  if (shell->indicator == nullptr && wanted && LoadIndicators(&shell->api)) {
    shell->indicator = shell->api.create("raindrop", IconPath().c_str(),
                                         kCategoryCommunications);
  }

  if (shell->indicator != nullptr) {
    if (wanted) {
      std::string title = "Raindrop";
      if (shell->in_call) title += " \xE2\x80\x94 " + shell->call.title;
      shell->api.set_title(shell->indicator, title.c_str());
      // The indicator holds on to its menu; the old one is let go with it.
      shell->api.set_menu(shell->indicator, BuildMenu());
      DrawLabel();
    }
    shell->api.set_status(shell->indicator,
                          wanted ? kStatusActive : kStatusPassive);
  }

  if (shell->in_call && shell->indicator != nullptr) {
    if (shell->clock == 0) {
      shell->clock = g_timeout_add_seconds(1, OnClock, nullptr);
    }
  } else if (shell->clock != 0) {
    g_source_remove(shell->clock);
    shell->clock = 0;
  }
}

// ── The channels ─────────────────────────────────────────────────────────────

void OnResidency(FlMethodChannel* channel, FlMethodCall* call, gpointer data) {
  if (g_strcmp0(fl_method_call_get_name(call), "setKeepRunning") == 0) {
    FlValue* arguments = fl_method_call_get_args(call);
    shell->keep_running =
        arguments != nullptr &&
                fl_value_get_type(arguments) == FL_VALUE_TYPE_MAP
            ? BoolAt(arguments, "keep", true)
            : true;
    Render();
    fl_method_call_respond_success(call, nullptr, nullptr);
    return;
  }
  fl_method_call_respond_not_implemented(call, nullptr);
}

void OnCall(FlMethodChannel* channel, FlMethodCall* call, gpointer data) {
  const gchar* method = fl_method_call_get_name(call);
  if (g_strcmp0(method, "begin") == 0 || g_strcmp0(method, "update") == 0) {
    FlValue* arguments = fl_method_call_get_args(call);
    Call next;
    if (arguments != nullptr &&
        fl_value_get_type(arguments) == FL_VALUE_TYPE_MAP) {
      next.title = StringAt(arguments, "title", "In a voice call");
      next.body = StringAt(arguments, "body", "");
      next.connected_at_ms = IntAt(arguments, "connectedAt");
      next.mic_on = BoolAt(arguments, "micOn", true);
      next.deafened = BoolAt(arguments, "deafened", false);
      next.reconnecting = BoolAt(arguments, "reconnecting", false);
    } else {
      next.title = "In a voice call";
    }
    shell->call = next;
    shell->in_call = true;
    Render();
    fl_method_call_respond_success(call, nullptr, nullptr);
    return;
  }
  if (g_strcmp0(method, "end") == 0) {
    shell->call = Call();
    shell->in_call = false;
    Render();
    fl_method_call_respond_success(call, nullptr, nullptr);
    return;
  }
  fl_method_call_respond_not_implemented(call, nullptr);
}

}  // namespace

void raindrop_shell_init(GtkWindow* window) {
  if (shell == nullptr) shell = new Shell();
  shell->window = window;
  g_signal_connect(window, "delete-event", G_CALLBACK(OnDelete), nullptr);
}

void raindrop_shell_attach(FlBinaryMessenger* messenger) {
  if (shell == nullptr) return;
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();

  shell->residency = fl_method_channel_new(messenger, "raindrop/residency",
                                           FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(shell->residency, OnResidency,
                                            nullptr, nullptr);

  shell->calls = fl_method_channel_new(messenger, "raindrop/call_session",
                                       FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(shell->calls, OnCall, nullptr,
                                            nullptr);

  Render();
}
