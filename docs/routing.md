# Routing

[`lib/core/router/app_router.dart`](../lib/core/router/app_router.dart), built on `go_router`.

## Routes

| Path | Screen | `extra` payload |
|---|---|---|
| `/` | [`HomeShell`](architecture-overview.md) | — |
| `/connect` | [`ConnectServerScreen`](connecting-to-a-server.md) | — |
| `/connect/auth` | [`ServerAuthScreen`](connecting-to-a-server.md) | `ConnectHandoff` — `(flow: ConnectServerFlow, status: UserStateResult, displayName: String)` |
| `/settings` | [`SettingsScreen`](settings.md) | — |
| `/settings/layout` | [`LayoutEditorScreen`](layout.md#the-editor) | — |
| `/settings/theme-editor` | [`ThemeEditorScreen`](settings.md) | `(starting: AppThemeDefinition, editing: AppThemeDefinition?)` |

## Why routes are shallow

Routes are intentionally shallow: **`/` alone decides whether to show onboarding or the main shell**
(`HomeShell` checks whether any server is connected, and whether the active one has a valid session —
see [Architecture overview](architecture-overview.md)), so nothing in the route table itself needs a
redirect guard.

`/connect/auth` carries its handoff via `extra` rather than encoding it into the URL, because
`ConnectServerFlow` holds a **live `ApiClient`** (an open TLS connection with in-memory pinning state)
that can't meaningfully round-trip through a query string — it has to be passed as a live Dart object.
The same reasoning applies to `/settings/theme-editor`'s `extra`, which carries live
`AppThemeDefinition` objects rather than, say, a theme id that would need a second lookup.

## Related

- [Connecting to a server](connecting-to-a-server.md) — what `ConnectHandoff` is built from and consumed by.
- [Settings](settings.md) — what the theme editor's `extra` tuple means.
