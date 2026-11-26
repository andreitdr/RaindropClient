#ifndef RUNNER_RAINDROP_SHELL_H_
#define RUNNER_RAINDROP_SHELL_H_

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

// Raindrop outside its window on Linux: what closing the window does, and the
// tray icon, which shows the call while one is up.
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
// The tray is a StatusNotifierItem through libayatana-appindicator3, loaded
// when it is installed rather than linked, so the app starts without it. Where
// it is missing, or the desktop shows no tray (GNOME without its AppIndicator
// extension), closing the window minimises it during a call - there is nowhere
// else to come back from - and closes it otherwise.
//
// Nothing here quits or hangs up by itself. Quit closes the window for real,
// which Flutter turns into its exit request - where the call controller
// leaves the call first - and Leave is sent to Dart like a button press.

// Takes over what closing |window| does. Call before the Flutter view is
// created, so this sees a close before Flutter does.
void raindrop_shell_init(GtkWindow* window);

// Opens the channels on |messenger|, once the Flutter view exists.
void raindrop_shell_attach(FlBinaryMessenger* messenger);

#endif  // RUNNER_RAINDROP_SHELL_H_
