# Native feel per platform

Nothing in RaindropClient builds separate UI trees per OS. Instead, a small number of focused pieces
adapt the one widget tree:

## `core/platform/platform_info.dart` — the only place that branches on OS

[`platform_info.dart`](../lib/core/platform/platform_info.dart) is the *only* file allowed to branch on
`Platform`/`defaultTargetPlatform` in the whole app. Everywhere else asks it a question instead of
re-deriving the check:

- `currentPlatform` → `RaindropPlatform` (`ios`, `macos`, `android`, `windows`, `linux`, `web`)
- `isApplePlatform` — iOS or macOS: gets Cupertino-flavored chrome (nav bars, action sheets, switches),
  because that's what "native feel" means there.
- `isDesktopPlatform` — macOS, Windows, or Linux.
- `isMobilePlatform` — iOS or Android.
- `canChooseAudioDevices` — desktop only: whether the app may pick the microphone and speakers for a
  call (phones route audio themselves). See [Voice](voice.md).
- `canChooseCamera` — **true everywhere**, unlike the audio devices: a phone's front and back cameras
  are two devices and choosing between them is the whole point, where audio routing is the OS's
  business.
- `canUseCameraEffects` — whether this platform has somewhere to put a frame processor: macOS, iOS and
  Android do, Windows and Linux have no chain between the capturer and the video source. The camera
  itself works everywhere. This is only the platform half of the answer — `cameraEffectsAvailable`
  (`core/video/camera_effects_engine.dart`) adds whether the build carries a segmentation model, and
  that is what the camera sheet reads, so a build without one offers no effect rather than one that
  would blur the wrong shape. See [Voice](voice.md#camera-effects).
- `canShareScreen` — every platform Raindrop runs on. `sharesWholeDeviceOnly` — phones and tablets,
  which share everything on the screen and have nothing to pick between, so the picker is a sheet
  there. `maximumShareFrameRate` — 30 on iOS, whose screen comes through a broadcast extension; no
  limit elsewhere. `needsScreenCapturePermission` — macOS, which asks for Screen Recording.
- `windowAudioUnavailableReason(windowId)` — why a window's own sound cannot be shared, or null: only
  on Windows 11, and not for a window whose process tree contains Raindrop. `isThisAppsWindow` and
  `isWindowStillOpen` answer the share picker. The Windows half of these is
  `core/platform/windows_processes.dart` (`dart:ffi`; it never branches on the platform itself, and
  loads nothing until called). See [Voice](voice.md#screen-sharing).
- `canUseSpeakerphone` — phones only: whether a call can be moved between the earpiece and the
  loudspeaker. Deliberately never offered alongside `canChooseAudioDevices`; they are each platform's
  answer to the same question. See [Android and iOS](mobile.md).
- `canScanCodes` — whether the camera can read another device's link code.
- `isRunningOnWeb`, `operatingSystemName`

Keeping every check in one file means a new target only needs updating here.

## `core/widgets/adaptive.dart` — swapping controls, not screens

[`adaptive.dart`](../lib/core/widgets/adaptive.dart) covers the handful of widgets Flutter doesn't
already adapt automatically:

- `AdaptiveSwitch` — `CupertinoSwitch` on Apple platforms, Material `Switch` elsewhere. Its `onChanged`
  is nullable: null shows it disabled.
- `AdaptiveActivityIndicator` — `CupertinoActivityIndicator` vs. a Material `CircularProgressIndicator`.
- `showAdaptiveConfirm(context, {title, message, confirmLabel, destructive})` — a confirm/cancel dialog
  styled per platform (`CupertinoAlertDialog` vs. `AlertDialog`), returning `true` only when the
  confirming action is picked.

Sliders use Flutter's own `Slider.adaptive` (the per-member and output volume sliders in
[Voice](voice.md)), so no wrapper was needed for them.

Page-transition style and scroll physics (bouncing vs. clamping) come for free from Flutter's default
`MaterialApp` behavior per platform — nothing had to be written for those.

## The responsive shell

[`HomeShell`](../lib/features/home/screens/home_shell.dart) is responsive **by width, not by
platform**: a `LayoutBuilder` collapses the four-pane desktop layout (server rail → channel sidebar →
chat → optional member list) into a single pane under **680px**: the server rail and channel list
behind a left-hand `Drawer`, the member list behind a right-hand one (the top bar's **Members** button,
or a swipe in from the right edge). This is what makes
phones and small windows usable without a separate mobile codebase — the same layout code runs
everywhere, and the breakpoint (not the OS) decides which arrangement to render.

Above 680px the panes' order and widths come from the user's saved [layout](layout.md). Whether the
member list shows by itself is derived from those widths: it shows while the chat keeps at least
**440px** (`kMinContentWidth`) beside it — a 1056px window at the default widths — and otherwise folds
behind the **Members** button, wherever the layout put it. See [Members & presence](members-presence.md).

## What is *not* shared

Four things a phone or desktop does that the shared UI could not paper over with a responsive layout,
so each sits behind its own seam rather than a branch at the call site:

| | Seam | Why |
|---|---|---|
| Keeping a call alive off screen, and showing it there | `CallSessionHost` (`core/voice/`) | iOS needs static configuration to keep it running, Android a foreground service, desktop nothing; showing the call outside the app (and taking its controls back) goes through the same seam. On iOS it is a Live Activity (`IosCallSessionHost`, with a widget extension drawing it; the person may turn it off, "Show calls as a Live Activity"). On Android it is a call notification (`CallStyle`, with Mute and Leave) that Android 12+ draws as a status bar chip and Android 16 as a Live Update, which the person may turn off ("Show calls in the status bar"; off, it is a plain ongoing notification) (`AndroidCallSessionHost`, `CallForegroundService.kt`); swiping the app away ends the call. On macOS it shows the call in the notch or the menu bar, on Windows in the notification-area icon's tooltip and menu, on Linux in the tray's menu and a timer label (`DesktopCallSessionHost`) |
| Re-reading everything after suspension | `AppLifecycleListener` → `EventStream.resubscribe()` | A suspended phone may have missed any amount of events; a fresh `ready` makes every controller re-read |
| Staying running with the window closed | `AppResidency` (`core/platform/`) | A desktop decides by what its close button does: hide to a menu bar / notification area / tray icon, or quit. Implemented on all three desktops by `DesktopAppResidency`: a menu bar item on macOS, a notification-area icon on Windows, a tray icon on Linux, each written in its runner (not with `tray_manager`, whose build hook compiles a large C++ library for every target); a phone has `NoAppResidency`. Windows and Linux are not yet built or run |
| Earpiece vs. loudspeaker | `VoiceEngine.setSpeakerphone` | Desktop picks a device instead; phones have no picker |

Each is inert off the platform that needs it — `NoAppResidency`, a lifecycle state that never
leaves `resumed`, a button that draws nothing — so the desktop builds are unchanged by their
existence. Full detail: [Android and iOS](mobile.md) and
[Background and live calls](background-and-live-calls.md).

## Related

- [Android and iOS](mobile.md) — the mobile half of "native feel", in full.
- [Theming](theming.md) — the other major cross-platform-consistency mechanism (colors, not controls).
- [Architecture overview](architecture-overview.md) — where `core/platform/` and `core/widgets/` sit in
  the overall folder layout.
