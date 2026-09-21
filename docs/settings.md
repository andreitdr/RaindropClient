# Settings

Feature folder: [`lib/features/settings/`](../lib/features/settings/). Routes: `/settings` and
`/settings/theme-editor` (see [Routing](routing.md)).

## `SettingsScreen`

[`settings_screen.dart`](../lib/features/settings/screens/settings_screen.dart) has three sections:

### Theme

Lists "Match system" (selects `kSystemThemeId`) plus every theme in `themeCatalogProvider`
(built-in + custom — see [Theming](theming.md)). Each row shows a color swatch (the theme's
`seedColor`) and a checkmark when active; custom themes additionally get edit and delete icon buttons
that built-in themes don't. "New theme" pushes `/settings/theme-editor` with the *currently active*
theme as the starting point. Deleting a theme asks for confirmation via `showAdaptiveConfirm` (see
[Native feel per platform](native-feel-per-platform.md)) and, if the deleted theme was active, falls
back the selection to `kSystemThemeId`.

### Voice & audio

[`VoiceSettingsSection`](../lib/features/voice/widgets/voice_settings_section.dart), reading and writing
`voiceSettingsProvider`: microphone and speakers (desktop only — `canChooseAudioDevices`; phones let the
OS route audio), output volume (0–200%, multiplied into every member's own volume), and echo
cancellation, noise suppression and automatic gain control. Changes reach a call in progress
immediately. There is no microphone volume — see [Voice](voice.md#ui). Per-member volume and local mute
are set from the member menu in a call, not here.

### Connected servers

Lists every server from `serversControllerProvider` (see [Servers & sessions](servers-and-sessions.md))
with its `host:port`. The logout icon on each row: confirms, then calls
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
