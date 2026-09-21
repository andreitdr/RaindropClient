# Servers & sessions

Feature folder: [`lib/features/servers/`](../lib/features/servers/).

This feature owns three related things: the local list of connected servers, the live authenticated
session for whichever one is active, and the UUID→display-name lookup cache messages need.

## `ServersController` — the local server list

[`servers_controller.dart`](../lib/features/servers/controllers/servers_controller.dart). Raindrop has
no central directory, so this list **is** the user's server list — nothing here is fetched from
anywhere, it's pure local bookkeeping over `AppPrefs.serverProfilesJson` (see [Storage](storage.md)).

- `serversControllerProvider` → `List<ServerProfile>` (see [`ServerProfile`](../lib/core/models/server_profile.dart):
  `id`, `host`, `port`, `displayName` — `id` is the server's GUID, generated once by
  [`ConnectServerFlow`](connecting-to-a-server.md) and independent of any server-assigned id).
  - `.add(server)` — no-ops if the id is already present.
  - `.rename(serverId, displayName)`
  - `.remove(serverId)` — also calls `SecureStore().forgetServer(serverId)` to drop its pinned
    fingerprint and session token.
- `activeServerIdProvider` → `String?`, which connected server the shell is currently showing.
  Restores the last-active server from `AppPrefs.lastServerId` on cold start if it still exists,
  otherwise falls back to the first server in the list (or `null` if there are none).

## `ServerSession` and `ServerSessionController` — the live connection

[`session_controller.dart`](../lib/features/servers/controllers/session_controller.dart).

`ServerSession` bundles a server's `ServerProfile`, its `ApiClient`, the bearer token, and the signed-in
`UserProfile`. The per-domain API wrappers (`UsersApi`, `ChannelsApi`, `MembersApi`,
`TextMessagesApi`, `RolesApi`, `VoiceApi` — see [Network layer](network-layer.md)) hang off the one client
as `late final` fields **rather than being passed in separately**, so adding a new domain is one line here
and nothing at the call sites that build a session.

`serverSessionProvider` is `AsyncNotifierProvider.family<ServerSessionController, ServerSession?, String>`
keyed by `serverId`. `build(serverId)` is what runs automatically on **cold start** for an
already-connected server:

1. Look up the `ServerProfile` in `ServersController`'s list; `null` if not found.
2. Read the session token from `SecureStore`; `null` (not signed in) if there isn't one.
3. Build an `ApiClient` pinned to whatever fingerprint is stored for this server, and register that
   fingerprint with `PinRegistry` so the voice engine's own sockets trust the server too (see
   [Voice](voice.md#how-a-call-is-carried)). `adopt` does the same for a first connection.
4. Call `GET /api/users/me` to confirm the token is still valid.
   - Valid → returns a populated `ServerSession`.
   - `invalid_session` → clears the stored token and returns `null`.

A `null` result routes the shell to [`ReauthPrompt`](connecting-to-a-server.md#reconnecting-connectserverflowforexisting)
in the chat pane, next to the server rail (`HomeShell`'s `_SignedOutLayout`) — see `HomeShell` in
[Architecture overview](architecture-overview.md).

Two mutating methods:

- `.adopt(session)` — called once [`ConnectServerFlow.persist`](connecting-to-a-server.md) hands back
  a fresh session, so the shell picks it up immediately without waiting for `build` to re-run.
- `.logout()` — best-effort `POST /api/users/logout` (a failure there is ignored — the token is being
  discarded locally regardless), then clears the stored token and sets state to `null`.

## The event stream

`serverEventsProvider(serverId)` ([`server_events.dart`](../lib/features/servers/controllers/server_events.dart))
is the live event stream for a signed-in server, open for as long as its session is, and
[`LiveSync`](../lib/features/servers/controllers/live_sync.dart) is how controllers follow it. When the
server closes the stream because the session ended — logged out elsewhere, or a server restart that
logged everyone out — the provider invalidates `serverSessionProvider(serverId)`, whose re-check finds
the token gone and routes the shell to `ReauthPrompt`. Full detail in [Live updates](live-updates.md).

## User lookup cache

[`user_lookup.dart`](../lib/features/servers/controllers/user_lookup.dart). Messages carry only their
author's UUID (see the server's [Messages doc](../../RaindropServer/docs/messages.md)), so every
message row needs this to show a name.

`userLookupProvider` is a `FutureProvider.family<PublicUserProfile?, UserRef>` (`UserRef` =
`(serverId, userId)`) wrapping `POST /api/users/lookup`. **Riverpod's own per-argument caching is the
cache** — one request per distinct author, however many messages that author wrote, for as long as the
provider's arguments keep matching. A failed lookup resolves to `null` rather than throwing.

The cache follows the [event stream](live-updates.md): a `member.renamed`, `member.left` or
`member.joined` for that UUID invalidates the entry, so every message they wrote shows the new name
without re-reading any history.

`displayNameFor(ref, who)` is the convenience read: the looked-up username, `'Unknown'` for an erased
account (see the server's [Users doc](../../RaindropServer/docs/users.md#lifecycle)), or a short prefix
of the UUID while the lookup is still in flight.

## Server rail

[`server_rail.dart`](../lib/features/servers/widgets/server_rail.dart) — the leftmost pane of the
shell: one circular avatar (initial letter of `displayName`) per connected server, plus an "add
server" button that pushes `/connect`. Tapping a server calls `activeServerIdProvider.notifier.select`.
Switching servers is always a single tap, regardless of how deep the user is in a channel — the same
pattern Discord-style clients are known for.

## Related

- [Connecting to a server](connecting-to-a-server.md) — how a `ServerSession` first comes into being.
- [Storage](storage.md) — `AppPrefs` (server list, last-active id) vs. `SecureStore` (fingerprint,
  token).
- [Settings](settings.md) — where a connected server is renamed or removed.
