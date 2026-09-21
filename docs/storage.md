# Storage

Folder: [`lib/core/storage/`](../lib/core/storage/). Two stores, split strictly by sensitivity — this
is the one rule to keep straight when adding any new piece of persisted state.

## `AppPrefs` — plain, non-sensitive settings

[`app_prefs.dart`](../lib/core/storage/app_prefs.dart) wraps `SharedPreferences`. Holds:

| Key | Holds |
|---|---|
| `settings.active_theme_id` | The selected theme id (`activeThemeId`) — `"system"` (`kSystemThemeId`), a built-in id, or a custom theme's generated id |
| `themes.custom` | User-created themes, as a raw JSON array (`customThemesJson`) |
| `settings.last_server_id` | Which server was last active (`lastServerId`), restored on cold start |
| `servers.list` | The connected-servers list, as a raw JSON array (`serverProfilesJson`) |
| `voice.settings` | Voice preferences as a raw JSON map (`voiceSettingsJson`): output volume, devices, audio processing, and whether this client is muted/deafened — see [Voice](voice.md) |
| `voice.member_audio` | Per-member volume and local mute, as a raw JSON map keyed `serverId/userId` (`memberAudioJson`); members left at the default are not stored |

Deliberately format-agnostic: `customThemesJson` and `serverProfilesJson` return raw
`List<Map<String, dynamic>>` rather than `AppThemeDefinition`/`ServerProfile`, so this storage layer
never has to import a domain model from a feature. Callers ([`ThemeCatalogController`](theming.md),
[`ServersController`](servers-and-sessions.md)) do the `fromJson`/`toJson` conversion themselves.

Loaded once in `main.dart` before `runApp` and handed to the widget tree via `appPrefsProvider` — see
[Architecture overview](architecture-overview.md#load-before-runapp-pattern).

## `SecureStore` — everything that must never leak

[`secure_store.dart`](../lib/core/storage/secure_store.dart) wraps `flutter_secure_storage`, backed by
Keychain (macOS/iOS), Credential Manager (Windows), libsecret (Linux), and Keystore (Android). Holds,
per server id:

- `server.<id>.fingerprint` — the pinned TLS fingerprint (see [Network layer](network-layer.md#certificatepinner-trust-on-first-use)).
- `server.<id>.token` — the session bearer token.

`.forgetServer(serverId)` removes both at once — called whenever a server is removed from
`ServersController` (see [Servers & sessions](servers-and-sessions.md)) or when
[settings](settings.md#connected-servers) drops a connected server.

## What's *not* in `SecureStore`

A server's per-client **GUID is not a secret** — the server hands out `PublicUserProfile.userId` to
any authenticated caller who asks (see the server's
[Users doc](../../RaindropServer/docs/users.md#user-api)). So it lives as `ServerProfile.id` in plain
`AppPrefs`, and doubles as that server's storage namespace key for both `AppPrefs` and `SecureStore` —
there's no second synthetic id anywhere that needs to be kept in sync with it.

## Rule of thumb for new state

| If it's... | It goes in... |
|---|---|
| A GUID, a pinned fingerprint, a session token — anything that authenticates or identifies a device to a server | `SecureStore` |
| UI preference, theme data, "which server was open last", the server list itself | `AppPrefs` |

## Related

- [Theming](theming.md) — the active theme id and custom themes, both in `AppPrefs`.
- [Servers & sessions](servers-and-sessions.md) — the server list in `AppPrefs`, the live session built
  from `SecureStore`'s token.
- [Connecting to a server](connecting-to-a-server.md) — where the fingerprint and token are first written.
