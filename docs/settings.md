# Settings

Feature folder: [`lib/features/settings/`](../lib/features/settings/). Routes: `/settings`,
`/settings/layout` and `/settings/theme-editor` (see [Routing](routing.md)).

`/settings` is reached from the **Settings** button — by default in the server rail (see
[Servers & sessions](servers-and-sessions.md#server-rail)), which is on screen for every server
whether or not this device is signed in to it, and in the user panel; the user's [layout](layout.md)
can move it, but always keeps it somewhere — plus the channel sidebar's header.

## `SettingsScreen`

[`settings_screen.dart`](../lib/features/settings/screens/settings_screen.dart) has these sections:

### Theme

Lists "Match system" (selects `kSystemThemeId`) plus every theme in `themeCatalogProvider`
(built-in + custom — see [Theming](theming.md)). Each row shows a color swatch (the theme's
`seedColor`) and a checkmark when active; custom themes additionally get edit and delete icon buttons
that built-in themes don't. "New theme" pushes `/settings/theme-editor` with the *currently active*
theme as the starting point. Deleting a theme asks for confirmation via `showAdaptiveConfirm` (see
[Native feel per platform](native-feel-per-platform.md)) and, if the deleted theme was active, falls
back the selection to `kSystemThemeId`.

### Layout

"Customize layout" opens `/settings/layout`, the [layout editor](layout.md#the-editor): move, resize
and hide the main view's panes and buttons, reset, import and export. Disabled under 680px, where the
narrow layout that the saved layout does not arrange is shown; the subtitle says whether a custom
layout is in use.

### Voice & video

[`VoiceSettingsSection`](../lib/features/voice/widgets/voice_settings_section.dart), reading and writing
`voiceSettingsProvider`: microphone and speakers (desktop only — `canChooseAudioDevices`; phones let the
OS route audio), output volume (0–200%, multiplied into every member's own volume), and echo
cancellation, noise suppression and automatic gain control. Changes reach a call in progress
immediately. There is no microphone volume — see [Voice](voice.md#ui). Per-member volume, local mute
and a hidden camera are set from the member menu in a call, not here.

**Camera & effects** opens the same sheet the camera button in a call opens
([`camera_effects_sheet.dart`](../lib/features/voice/widgets/camera_effects_sheet.dart)): a live
preview, the camera picker, the quality, and the background effect — none, blur with a strength
slider, or a picture of your own chosen through the usual file dialog. Shown on every platform, unlike
the audio devices — a phone's front and back cameras are two devices. The effect rows are disabled
with a reason where effects cannot run (Windows and Linux, or a build with no segmentation model:
`cameraEffectsAvailable`), and the preview still shows the plain camera there. What is remembered is *which* camera and *which*
effect, never whether the camera is on: mute and deafen are states that carry over from one call to
the next, and a camera is not. See [Voice](voice.md#camera).

### Connected servers

Lists every server from `serversControllerProvider` (see [Servers & sessions](servers-and-sessions.md))
with its `host:port`. Leaving a server for good is the rail's right-click menu, not this list — see
[Servers & sessions](servers-and-sessions.md#leaving-or-removing-a-server). The logout icon on each row: confirms, then calls
`serverSessionProvider(serverId).notifier.logout()` followed by
`serversControllerProvider.notifier.remove(serverId)` — **this only forgets the server locally**
(including its saved session and pinned certificate fingerprint); it does not delete the user's
account on the server.

## `ThemeEditorScreen`

[`theme_editor_screen.dart`](../lib/features/settings/screens/theme_editor_screen.dart) — a
color-by-hex-field form for `name`, `brightness`, `seedColor`, and the five `AppSurfaces` colors (see
[Theming](theming.md#appsurfaces--the-pane-color-tiers)).

Takes two navigation `extra` arguments (see [Routing](routing.md)):

- `starting` — the `AppThemeDefinition` to pre-fill every field from.
- `editing` — `null` when creating a brand-new theme (name defaults to `"<starting name> copy"`), or
  the existing custom theme being edited in place. **Editing a built-in theme is impossible by
  construction**: `SettingsScreen` never sets `editing` for a built-in row, so saving from that state
  always creates a new custom theme rather than mutating `light.json`/`dark.json`.

Saving calls `ThemeCatalogController.addOrUpdate(...)`, which persists to
`AppPrefs.customThemesJson` (see [Storage](storage.md)).

## Related

- [Theming](theming.md) — the full theme model this screen edits.
- [Servers & sessions](servers-and-sessions.md) — what "removing" a server actually clears.
- [Storage](storage.md) — where settings data is persisted.
