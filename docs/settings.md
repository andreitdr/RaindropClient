# Settings

Feature folder: [`lib/features/settings/`](../lib/features/settings/). Settings are split by what they
belong to:

| Page | Route | Screen | Opened from |
|---|---|---|---|
| **Device settings** | `/settings` | [`DeviceSettingsScreen`](../lib/features/settings/screens/device_settings_screen.dart) | the **User settings** button beside the person's name (and wherever else the [layout](layout.md) puts it); the *User settings* link on `SignInPane` and `ServerUnreachablePane` |
| **Identity & devices** | `/settings/identity` | [`IdentitySettingsScreen`](../lib/features/settings/screens/identity_settings_screen.dart) | Device settings |
| **Server settings** | `/servers/:serverId/settings` | [`ServerSettingsScreen`](../lib/features/settings/screens/server_settings_screen.dart) | the server's name above its channel list; *Server settings* in the rail's server menu; a row of Device settings' server list |

Plus `/settings/layout` and `/settings/theme-editor` (see [Routing](routing.md)).

The **User settings** button (`app.settings` in the [layout](layout.md)) sits by default only in the
user panel at the foot of the channel list — not in the rail any more. The layout still requires it
in at least one slot, and a saved layout that has it in the rail keeps it there. With no channel list
on screen — a server signed out or unreachable — the user panel is not there either, so
`SignInPane` and `ServerUnreachablePane` carry a *User settings* link of their own.

## `DeviceSettingsScreen`

Everything that belongs to this device, whichever server is open:

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

### Identity & devices

One row — this device's name and how many other devices are paired — opening `/settings/identity`.
It has a page of its own because it belongs to the person rather than to this device or a server.

### Servers on this device

Every server from `serversControllerProvider` (see [Servers & sessions](servers-and-sessions.md)) with
its `host:port`. Tapping a row opens that server's settings; its ⋮ menu offers **Leave server** and
**Remove from this device** — the same entries, and the same code, as the rail's server menu
([`server_actions.dart`](../lib/features/servers/widgets/server_actions.dart); see
[Leaving or removing a server](servers-and-sessions.md#leaving-or-removing-a-server)).

## `IdentitySettingsScreen`

A page around [`IdentitySettingsSection`](../lib/features/identity/widgets/identity_settings_section.dart):
nudges when the recovery words are due a check or this is the only device, this device (renamable) and
the other paired devices, pairing a device, new recovery words, checking them, the authenticator and new
backup codes, the cloud backup (iCloud Keychain / Google), and how this device is unlocked. See [Identity](identity.md).

## `ServerSettingsScreen`

What belongs to one server, for the server in its route — not the active one, so it can be opened for
any server from the rail or the device's server list. It needs no session, so it opens for a server
that is down or signed out too.

- A header with the server's name and `host:port`.
- **Encryption** — [`EncryptionSettingsSection`](../lib/features/security/widgets/encryption_settings_section.dart)
  for that server: says so when the server offers no end-to-end encryption, when this device is not
  set up there yet, or when it cannot be read; otherwise this device and the account's other devices
  there, and a row for each changed identity key waiting for the person's decision (opens the
  safety-number dialog). See [Crypto](crypto.md).
- **Members → Roles** — opens [`RolesScreen`](roles.md) for that server. Shown only when the server's
  permission catalogue can be read, so a signed-out server or one without role management does not offer
  it. See [Roles](roles.md).
- **Leave this server** — *Leave server* (`showLeaveServerDialog`) and *Remove from this device*
  (`confirmRemoveServer`). Once the server is gone from `serversControllerProvider` — from here or
  anywhere else — the page closes itself.

## `ThemeEditorScreen`

[`theme_editor_screen.dart`](../lib/features/settings/screens/theme_editor_screen.dart) — a
color-by-hex-field form for `name`, `brightness`, `seedColor`, and the five `AppSurfaces` colors (see
[Theming](theming.md#appsurfaces--the-pane-color-tiers)).

Takes two navigation `extra` arguments (see [Routing](routing.md)):

- `starting` — the `AppThemeDefinition` to pre-fill every field from.
- `editing` — `null` when creating a brand-new theme (name defaults to `"<starting name> copy"`), or
  the existing custom theme being edited in place. **Editing a built-in theme is impossible by
  construction**: `DeviceSettingsScreen` never sets `editing` for a built-in row, so saving from that state
  always creates a new custom theme rather than mutating `light.json`/`dark.json`.

Saving calls `ThemeCatalogController.addOrUpdate(...)`, which persists to
`AppPrefs.customThemesJson` (see [Storage](storage.md)).

## Related

- [Theming](theming.md) — the full theme model this screen edits.
- [Servers & sessions](servers-and-sessions.md) — what leaving and "removing" a server actually clear.
- [Identity](identity.md) — what the Identity & devices page manages.
- [Storage](storage.md) — where settings data is persisted.
