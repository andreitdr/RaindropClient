# Background and live calls

Two wishes with one design: **show the ongoing call outside the app**, and **keep running in the
background**. A person in a call who switches to another app, locks the phone or closes the window
should still see the call, know whether they are muted, and be able to mute or hang up from there.

This is built in phases. **Phase 1, the shared foundation, phase 2, macOS, phase 3, Windows and Linux,
and phase 4, the iPhone and iPad Live Activity, are done; Android is not.** So today the three desktops
show the call outside the app and stay running with their window closed, an iPhone or iPad shows it as a
Live Activity, and no Android phone draws it beyond its ongoing notification. Everything marked *not
built yet* below is a plan, not behaviour. **Windows and Linux have been compiled in part but never built
or run, and the Live Activity has never been seen with a real call**; see their sections.

## On a Mac

### What a person sees

- **Closing the window hides it.** Raindrop stays signed in, online and in any call, and its Dock icon
  stays. Cmd+W does the same. The Dock icon, the menu bar item or the island's Open button brings the
  window back. Turn this off with **Keep running in the menu bar** in
  [Device settings](settings.md#background) (on by default); with it off, closing the window quits, as
  it always did.
- **A menu bar item** exists while it is kept running (and during a call on a Mac without a notch).
  Its menu has Open Raindrop; during a call the call's title and server (greyed out), Mute / Unmute,
  Deafen / Undeafen and Leave Call; Settings... (Cmd+,), which shows the window and opens Device
  settings, but only while the app is unlocked; and Quit Raindrop (Cmd+Q).
- **A call shows on a Mac for as long as it lasts**, and there is nothing to turn off, so the "show the
  call outside the app" setting is not offered. On a Mac with a notch, the call is an island around the
  notch: compact it shows the microphone on the left (red when nobody can hear you) and the call's
  timer on the right, plus a reconnect symbol while reconnecting. Hovering over it grows it into the
  call's title and server, screen-share and lock icons, the participant count, round Mute, Deafen and
  Leave buttons and an Open Raindrop button. On a Mac without a notch, the menu bar item becomes a
  pill: a microphone symbol (mic, mic.slash, or speaker.slash when deafened) and the elapsed time, or
  "Reconnecting...".
- **Quitting leaves the call.** Quit Raindrop and Cmd+Q go through Flutter's exit request, where
  `VoiceCallController.leaveNow` leaves the call first. Nothing native quits or hangs up by itself;
  Leave is sent to Dart as an action.

Known trade-off: the compact island's wings cover a strip of the menu bar beside the notch, so a menu bar
item crowded right up against the notch cannot be clicked while a call shows.

**Not yet verified on a real Mac with a real call:** hover and clicks on the island, close-to-hide, App
Nap behaviour and external displays. What has been checked is that `flutter analyze` is clean, that
`flutter build macos --debug` is clean (Runner's Swift treats warnings as errors), and that the island's
SwiftUI renders correctly off-screen in its compact and expanded states.

### How it is built

Dart side:

- `ChannelCallSessionHost` (in `call_session_host.dart`) is the shared channel logic of the hosts that
  talk to native code, over `raindrop/call_session`: `begin` and `update` carry `toMap()`, `end` ends
  it, and `action` comes back with an action's name. A missing plugin (`MissingPluginException`) is
  swallowed, so a build without the native side behaves as if there were no host.
  `AndroidCallSessionHost` extends it (adding `capture`); so does `DesktopCallSessionHost`, whose
  `setScreenCapture` answers true without asking and whose `showsCallOutsideApp` is false.
  `createCallSessionHost` returns it on macOS, Windows and Linux.
- `DesktopAppResidency` (in `app_residency.dart`) is the residency over `raindrop/residency`:
  `setKeepRunning` with `{keep}` goes to native, and `command` with a name comes back
  (`ResidencyCommand.named`; an unknown name is ignored). `createAppResidency` returns it on every
  desktop (`isDesktopPlatform`) and `NoAppResidency` on a phone. Both classes were `Macos…` until
  Windows and Linux shared them.

Native side, in `macos/Runner/`:

- `RaindropShell.swift`: a `@MainActor` singleton attached from `MainFlutterWindow.awakeFromNib`. It is
  the window's delegate: while `keepRunning` is set, `windowShouldClose` orders the window out instead
  of closing it, and `showWindow()` brings it back (from `AppDelegate.applicationShouldHandleReopen`,
  the menu bar item and the island's Open button). `AppDelegate.applicationShouldTerminateAfterLastWindowClosed`
  returns `!keepRunning`. It owns the `NSStatusItem` and its menu (built each time it opens). Settings
  sends `command openSettings`; Quit calls `NSApp.terminate`, which Flutter turns into its exit request.
- The call surface is chosen for the menu bar's screen (`NSScreen.screens.first`) and chosen again on
  `didChangeScreenParametersNotification`. A notched screen (`safeAreaInsets.top > 0`, with
  `auxiliaryTopLeftArea` and `auxiliaryTopRightArea`; the notch's width is the screen's width minus
  both) gets the island; any other becomes the status item pill, redrawn once a second.
- `NotchPanel.swift`: `NotchGeometry` (a wing is 60pt each side; compact is the notch plus two wings
  wide and the menu bar's height tall; expanded is at least 380 wide and 86 taller), `NotchPanel` (a
  borderless, non-activating `NSPanel` at the main menu level plus 3, on all Spaces and over full-screen
  apps, never key, so keyboard focus stays where the person is typing; `NotchHostingView` accepts the
  first mouse so a button works with one click), `NotchTrackingView` (hover through an `.activeAlways`
  tracking area, because SwiftUI's hover follows only the key window), `NotchController` and the SwiftUI
  `NotchView`. The controller grows the island after 150ms of hover and shrinks it 350ms after the
  pointer leaves; the panel takes its largest frame first and the island animates inside it, then the
  panel shrinks back so the menu bar beside it is clickable again. The compact timer is
  `Text(connectedAt, style: .timer)`, the system's clock, so nothing ticks. It is written from scratch;
  Boring Notch (GPL) was only read for how such panels are configured.
- `CallDescription.swift`: the Swift reading of `toMap()` (lenient: unknown keys are ignored and
  missing ones default) and `CallAction`.
- **App Nap**: `ProcessInfo.beginActivity(.userInitiatedAllowingIdleSystemSleep)` is held while the
  window is hidden with keep-running on, or while a call is up, so heartbeats (presence) and call
  timers are not throttled. The Mac and its display may still sleep.
- The three Swift files are in the Runner target of `macos/Runner.xcodeproj`. The menu bar item's icon
  is `MenuBarIcon.imageset`, a template image generated by `tool/icons/gen_icons.sh`
  ([App icon](app-icon.md)).

## On Windows

### What a person sees

- **Closing the window hides it** while **Keep running in the notification area** is on
  ([Device settings](settings.md#background), on by default). The close button, Alt+F4 and the taskbar's
  Close window all do it. Raindrop stays signed in, online and in any call, and the icon stays in the
  notification area. With the setting off, closing quits.
- **A notification-area icon** (the app's own icon) is there while it is kept running, and during a call
  whatever the setting says. Its tooltip is "Raindrop", or during a call "Raindrop — In General (server)"
  with ", muted" or ", deafened" after it, or "Reconnecting…" in place of the title. A left click brings
  the window back. A right click opens a menu: Open Raindrop (the default item); during a call the title
  and server (greyed out), Mute / Unmute, Deafen / Undeafen and Leave call; Settings…, which shows the
  window and opens Device settings (only while the app is unlocked); and Quit Raindrop.
- **The icon is the call's surface.** Windows has nothing like a live activity, so there is no timer or
  island; the tooltip and menu are all it shows.
- **Quitting leaves the call**, as everywhere (see below).

Not done, as follow-ups: Mute and Leave buttons on the taskbar thumbnail (`ITaskbarList3`), and a one-off
"still running" notice the first time the window is closed.

### How it is built

`windows/runner/raindrop_shell.{h,cpp}` (`RaindropShell`) is owned by `FlutterWindow`: created after the
plugins are registered, destroyed before the Flutter controller. `FlutterWindow::MessageHandler` gives it
every window message before Flutter (`HandleMessage`); returning a result there keeps Flutter from seeing
the message. It opens both channels, `raindrop/residency` and `raindrop/call_session`, on the engine's
messenger and reads `toMap()` leniently, like the other platforms.

- `WM_CLOSE` is hidden (`SW_HIDE`) while keep-running is set and the shell is not quitting. Otherwise
  Flutter gets it and turns it into its exit request, so `VoiceCallController.leaveNow` leaves the call.
  Quit Raindrop sets a quitting flag and posts `WM_CLOSE`, so it takes that same road.
- The icon is a `Shell_NotifyIconW` icon (`IDI_APP_ICON` loaded at the small-icon size), added, modified
  or deleted by `Render` whenever keep-running or the call changes. It is added again when Explorer
  restarts (the registered `TaskbarCreated` message). Keep-running starts true until Dart says otherwise.
- The menu is a popup menu built each time it opens; Mute, Deafen and Leave send `action` to Dart.
  The shell ignores `connectedAt`, since there is no timer to draw.

**Not yet built or run on Windows.** The sources were compiled (syntax only) with MinGW-w64 against
Flutter's C++ client wrapper under `-Wall -Wextra -Werror -Wconversion`, which approximates but is not
MSVC's `/W4 /WX`. CI (`.github/workflows/ci.yml`) is where they first really build. Hiding, the icon, the
menu, Quit and the Explorer-restart re-add are untested.

## On Linux

### What a person sees

- **Closing the window hides it** while **Keep running in the tray** is on (on by default), if the
  desktop shows tray icons. The tray menu mirrors Windows': Open Raindrop; during a call the title and
  server (greyed out), Mute / Unmute, Deafen / Undeafen and Leave call; Settings…; Quit Raindrop.
- **A desktop with no tray** (GNOME without its AppIndicator extension, or the tray library not
  installed) always has a way to quit: closing the window during a call only **minimises** it, and
  closing with no call quits as it always did.
- **The call's time beside the icon.** During a call the tray shows the elapsed time as a label next to
  the icon (`4:07`, `1:02:33`, or "Reconnecting…"), redrawn every second, where the desktop draws labels:
  KDE Plasma and Ubuntu's extension do. It is Linux's nearest thing to a live activity.
- The icon is the app's own. GNOME shows its own microphone-in-use indicator regardless.

Not done, as a follow-up: a resident freedesktop notification with Mute and Leave, for desktops with no
tray.

### How it is built

`linux/runner/raindrop_shell.{h,cc}`. `raindrop_shell_init(window)` runs in `my_application_activate`
right after the window is created and before the Flutter view, and connects `delete-event` first, so a
close that only hides never reaches Flutter's own `delete-event` handler (which requests app exit).
`raindrop_shell_attach(messenger)` opens the two channels after the plugins are registered.

- **The tray is a StatusNotifierItem through libayatana-appindicator3** (falling back to
  libappindicator3), **opened with `dlopen` at runtime, not linked**. It is not needed to build, and
  the app starts without it; `linux/runner/CMakeLists.txt` links `${CMAKE_DL_LIBS}` for it.
- On close with keep-running set (and not quitting): if the indicator exists **and a tray host is
  registered**, the window is hidden. That is asked of D-Bus, `IsStatusNotifierHostRegistered` on
  `org.kde.StatusNotifierWatcher` and on `org.freedesktop.StatusNotifierWatcher`, both, because GNOME's
  extension still uses the org.kde name. Otherwise, during a call, the window is iconified; with no call
  the close goes through to Flutter and quits. Quit sets a quitting flag and closes the window, so it
  reaches Flutter's exit request and `leaveNow` leaves the call.
- The icon is shown while keep-running is set or a call is up. The timer is `app_indicator_set_label`,
  redrawn by a one-second timeout that runs only during a call, from `connectedAt`.
- The icon file is `packaging/linux/raindrop.png`, installed by `linux/CMakeLists.txt` into the bundle as
  `data/tray/raindrop-tray.png` and passed to the indicator as a full path (from `/proc/self/exe`).
- Packages **recommend**, not depend on, the library: `libayatana-appindicator3-1` (.deb) and
  `libayatana-appindicator-gtk3` (.rpm), set in `packaging/linux/build-packages.sh`. The AppImage uses the
  host's library if there is one. No build dependency was added.

**Not yet built or run on Linux.** The runner sources were compiled (syntax only) in an Ubuntu 22.04
container with GTK 3 headers under the runner's own `-Wall -Werror`. CI is where they first really build.
Hiding, the tray, its menu, Quit, GNOME without the extension and the label on KDE are untested.

### Why not tray_manager and window_manager

The approved plan was the `tray_manager` and `window_manager` packages. They are not used:
tray_manager 0.8, the line compatible with this Flutter (3.47), depends on `nativeapi` / `cnativeapi`,
whose Dart build hook compiles a roughly 360-file C++ library for every target the app builds, Android
and iOS included. So the tray is written in the runners, like the Mac's, and no Dart package was added.

## On an iPhone or iPad

### What a person sees

- **The call is a Live Activity** while it lasts, on the Lock Screen and, on an iPhone with a Dynamic
  Island, in the island. On the Lock Screen (and in Notification Center and StandBy) it is a banner with
  the microphone (green, or red when nobody can hear you), the call's title and server, the
  participant count and screen-share and lock icons, the call's timer (a reconnect symbol while
  reconnecting), and Mute, Deafen and Leave buttons. In the island it is
  compact (the microphone on the left, the timer on the right, held to a narrow width) or, when
  pressed, expanded with the same things; minimal (another app's activity has the island too) it is the
  microphone alone. Tapping it opens Raindrop.
- **Leaving it running is the point.** The call keeps going with the app off screen because of the
  `audio` background mode, as before; the activity is only how it shows. Muting, deafening or leaving
  from it does what the call bar's buttons do.
- **Swiping the app away ends the call** and its activity, as quitting does elsewhere.
- **It can be turned off.** **Show calls as a Live Activity** in [Device settings](settings.md#background)
  (on by default; Apple's own name, which covers the Lock Screen on every iPhone and the island on those
  with one). Turning off Live Activities for Raindrop, or for every app, in the system's Settings does
  the same: the call goes on without one.
- **While the app is locked** the activity says only "In a voice call" and names nothing else.

Limits worth knowing, which are Apple's:

- **Buttons need iOS 17.** On iOS 16.2 to 16.x the activity is shown but has no buttons, and a tap opens
  the app.
- **An iPhone without a Dynamic Island** shows the Lock Screen, Notification Center and StandBy
  presentation. Nothing can be drawn in the notch itself.
- **A Live Activity lasts at most 8 hours active**, then ends, and may stay on the Lock Screen for up to
  4 more.
- **Updates sent while the app is in the background may be throttled** by iOS. An unconfirmed developer
  report says local updates stop after about 30 seconds even with background audio. The timer is not
  affected, because the system draws it from `connectedAt`, but a mute or a change in who is in the call
  made while the app is off screen may show late.
- **CallKit is still not used**, so there is no green call pill in the status bar; the system shows its
  own microphone indicator.

**Not yet seen on a device or simulator with a real call.** What has been checked is that
`flutter build ios --simulator --debug` is clean (Runner and the extension both treat Swift warnings as
errors), that the extension is embedded in `Runner.app/PlugIns`, that the app's AppIntents metadata
contains the three intents, that ActivityKit and AppIntents are weak-linked, and that the Lock Screen view
renders correctly off-screen (normal, muted, locked). Starting, updating and ending the activity, the
buttons, the island, and swiping the app away are untested.

### How it is built

Dart side: `IosCallSessionHost` (in `call_session_host.dart`) extends `ChannelCallSessionHost`.
`showsCallOutsideApp` is true, which is what puts the setting in Settings on iOS, and `setScreenCapture`
answers true without asking (the broadcast extension asks the system itself). `createCallSessionHost`
returns it on iOS, so every platform now has a real host; `InactiveCallSessionHost` is left for tests and
any platform not listed. `showCallSettingTitle` (in `platform_info.dart`) is "Show calls as a Live
Activity" on iOS.

Native side, in `ios/Runner/`:

- `CallActivity.swift`: a `@MainActor` singleton over `raindrop/call_session`. `begin` and `update`
  start or update the activity, but only when `showOutsideApp` is set and
  `ActivityAuthorizationInfo().areActivitiesEnabled`; with `showOutsideApp` off an update ends it. It is
  requested with `pushType: nil`, so no APNs or push server is involved. `end` ends it immediately.
  Updates are chained, each waiting for the one before, so a quick mute and unmute cannot arrive out of
  order. Activities left over from a run that was killed are ended when it attaches at launch.
  `endAllBeforeExit()` ends every call activity on termination, waiting at most a second. Everything
  here is guarded by iOS 16.2.
- `AppDelegate.swift`: attaches `CallActivity` from `didInitializeImplicitFlutterEngine`, through a
  plugin registrar's messenger, and calls `endAllBeforeExit` from `applicationWillTerminate`. Swiping
  the app away is Dart's existing `onDetach` to `leaveNow`, so the call and its activity both end.
  `applicationWillTerminate` is not guaranteed when the app is killed from the background, which is why
  the leftovers are also ended on the next launch.
- `Info.plist`: `NSSupportsLiveActivities` is YES.

`ios/RaindropLiveActivity/` is a widget extension target (`com.apple.widgetkit-extension`), embedded in
the app:

- `CallActivityAttributes.swift` (compiled into both targets): the `ContentState`, which mirrors the Dart
  description (less `showOutsideApp`). Nothing ticks; the timer is `Text(timerInterval:)` from
  `connectedAt`, so the activity is updated only when the call changes.
- `CallActivityIntents.swift` (both targets): `CallActivityRelay` and three iOS 17 `LiveActivityIntent`s,
  mute, deafen and leave. An intent runs in the app's process whichever process drew its button, so the
  app sets the relay and sends `action` to Dart; in the extension it is never reached.
- `CallActivityViews.swift`: plain SwiftUI views of the state (the microphone, the timer, the summary,
  the controls, the Lock Screen view). They use no ActivityKit, which is what let them be rendered
  off-screen for checking.
- `RaindropLiveActivity.swift`: the `WidgetBundle` and the `ActivityConfiguration`: the Lock Screen
  banner, the island's expanded regions, the compact microphone and timer (the timer held to 44pt, since
  a running timer otherwise takes as much room as its longest reading), and the minimal microphone.
- `LiveActivity.xcconfig`: only Flutter's generated variables, for the two version numbers, plus
  `Flutter/Warnings.xcconfig`. Deliberately not the Pods settings, which would link every plugin into the
  extension.

The extension's deployment target is 16.2; the app stays at 15.0. So Runner weak-links ActivityKit and
AppIntents (`OTHER_LDFLAGS` keeps `$(inherited)`) and still launches on iOS 15.
`tool/ios/add_live_activity_extension.rb` added the target to `Runner.xcodeproj` (the shared files in both
targets, the extension in the existing *Embed Foundation Extensions* phase, before *Thin Binary*). It is
the record of what it needed; run it again if the project is regenerated.

iOS starts an activity only for an app in the foreground. That is met because joining happens in the
foreground and a rejoin keeps the session open (see below), so a dropped call never needs a new one
from the background. An activity that goes away without the app ending it — the person swiped it off
the Lock Screen, or iOS ended it after its 8 hours — stays away until the next call
(`CallActivity.dismissed`): bringing it back on the next mute would overrule the person, and from the
background iOS would refuse anyway.

**Signing.** The extension is `com.raindrop.raindropClient.RaindropLiveActivity`, under the same team. It
needs its own App ID on the developer account; no App Group or other capability is needed. Automatic
signing registers it; a release pipeline with explicit profiles needs a profile for it. CI builds
`--no-codesign`. See [Android and iOS](mobile.md#the-ios-extension).

## What exists on every platform

### The call, described

[`CallSessionDescription`](../lib/core/voice/call_session_host.dart) is the whole call as a glance
shows it, so a surface needs nothing else from Dart:

| Field | Meaning |
|---|---|
| `title`, `body` | "In <channel>" and the server's name. Before the channel list loads, or while the app is locked, the title is "In a voice call" and the body is empty |
| `connectedAt` | When the call first connected. Kept across a rejoin, so a timer does not restart. Nothing ticks from Dart; each surface draws its own clock from it |
| `micOn` | What others hear: false when self-muted, moderator-muted, suppressed, or the microphone failed |
| `deafened`, `reconnecting`, `participants`, `sharingScreen`, `encrypted` | State a surface may show |
| `concealed` | The app lock is engaged: generic words only, and the surface names nothing else |
| `showOutsideApp` | The person's setting (see below) |

It is compared by value and sent over the platform channel with `toMap()`. The pure function
`describeCall` (in `voice_call_controller.dart`) builds it, so the same call always describes the same
way. `VoiceCallController` opens the session once the call connects (`_announceSession`) and re-sends
it only when it really changed (`_refreshSession`), driven by the call's own state, voice settings, the
app lock, the background settings, the call's roster and the channel list, and a rebuilt server session.

### The controls coming back

`CallSessionHost.actions` is a stream of `CallSessionAction` (`toggleMute`, `toggleDeafen`, `leave`),
found by name; a name the build does not know is ignored. The controller applies each as the call bar's
matching button does, so mute while the microphone has failed retries it. The channel hosts
(`ChannelCallSessionHost`) relay a channel method `action` whose argument is the action's name. The
desktop runners and iOS (`CallActivity.swift`) send it; the Kotlin side does not yet.

### A rejoin keeps the session

When a dropped call is rejoined, the controller tears the engine down but keeps the OS session
(`_teardown(keepSession: true)`) and describes it as `reconnecting`. It is ended only when the call
settles. This is not tidiness: Android will not start a microphone foreground service again from the
background, and iOS will not start a Live Activity, so ending the session and opening a new one would
leave a call dropped in the background with nothing to show or keep it alive.

The one session that would outlive its call is a rejoin abandoned between two of its tries, when the
state briefly holds no call for `leave()` to end. So `join()` ends any session still open before it
connects: a new call opens its own session, with its own `connectedAt`.

### Staying running with the window closed

[`AppResidency`](../lib/core/platform/app_residency.dart) is the seam for the desktops: whether closing
the window hides the app (kept signed in, online and in any call, behind a menu bar, notification area
or tray icon) or quits it. It has `available`, `setKeepRunningWhenClosed` and a `commands` stream
(`ResidencyCommand.openSettings`, from the icon's Settings item). `appResidencyProvider` returns
`DesktopAppResidency` on every desktop and `NoAppResidency` on a phone.

**Quitting is never done in the residency.** The icon's Quit, Cmd+Q, logging off and closing the window
with residency off all go through Flutter's exit request, where `VoiceCallController.leaveNow` leaves
the call first. Keeping that in one place means no platform can forget it.

### The settings

`BackgroundSettings` (`keepRunningWhenClosed` for desktops, `showCallOutsideApp` for phones, both on by
default) is persisted in `AppPrefs` under `settings.background` by `backgroundSettingsProvider`.
`appResidencyBindingProvider`, watched by `lib/app.dart`, hands `keepRunningWhenClosed` to the residency
at startup and on every change, and opens `/settings` on the icon's command only while the app is
unlocked. `BackgroundSettingsSection` ([Settings](settings.md#background)) shows each row only where
the residency is `available` or the host `showsCallOutsideApp`, and the whole section nowhere else.
Today the residency is available on the three desktops and the host shows its call outside the app on
iOS, so the section shows on those four and nowhere else (on iOS it has the one row, **Show calls as a
Live Activity**).
`CallSessionHost.showsCallOutsideApp` is true on iOS only. It is false on the desktops, where the call
always shows, and on Android: its ongoing notification is the price of the call running, so it is not
offered as something to turn off until there is a promoted version to turn off.

Tests: `test/core/voice/call_session_host_test.dart` (the `DesktopCallSessionHost` group, and
the `IosCallSessionHost` group, and `createCallSessionHost` on iOS and all three desktops),
`test/core/platform/app_residency_test.dart` (`DesktopAppResidency`, and `createAppResidency` per
platform), `test/features/voice/call_description_test.dart` and
`test/features/settings/background_settings_test.dart`.

## The plan per platform (not built yet)

The desktops and iOS are built (see above); the rest is still to do.

| Platform | Showing the call | Staying running |
|---|---|---|
| **Android** | A CallStyle notification and Live Updates (the status bar chip, the Now Bar) on top of the existing foreground service; the Kotlin side sending `action` | Already covered by the foreground service |
| **macOS 27.3** | Live Activities | — |

Each of these implements the existing seams (`CallSessionHost`, `AppResidency`) rather than adding a
branch to the call controller. When one lands, move it out of this table into its own section above, flip the host's
`showsCallOutsideApp` or the residency's `available`, and update the [roadmap](roadmap.md).

## Related

- [Android and iOS](mobile.md) — the call session on phones, in detail.
- [Voice](voice.md) — the call controller and its rejoin.
- [Settings](settings.md#background) — the Background section.
- [Native feel per platform](native-feel-per-platform.md) — the seams.
