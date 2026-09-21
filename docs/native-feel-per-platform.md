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
- `isRunningOnWeb`, `operatingSystemName`

Keeping every check in one file means a new target only needs updating here.

## `core/widgets/adaptive.dart` — swapping controls, not screens

[`adaptive.dart`](../lib/core/widgets/adaptive.dart) covers the handful of widgets Flutter doesn't
already adapt automatically:

- `AdaptiveSwitch` — `CupertinoSwitch` on Apple platforms, Material `Switch` elsewhere.
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
chat → optional member list) into a single pane behind a `Drawer` under **680px**. This is what makes
phones and small windows usable without a separate mobile codebase — the same layout code runs
everywhere, and the breakpoint (not the OS) decides which arrangement to render.

A second breakpoint, **1000px**, decides whether the member list pane shows automatically
(`canShowMembers`) or has to be toggled on with a button in the chat pane's trailing actions — see
[Members & presence](members-presence.md).

## Related

- [Theming](theming.md) — the other major cross-platform-consistency mechanism (colors, not controls).
- [Architecture overview](architecture-overview.md) — where `core/platform/` and `core/widgets/` sit in
  the overall folder layout.
