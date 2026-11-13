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

`ServerSession` bundles a server's `ServerProfile`, its `RaindropChannel` (`client`: one pinned HTTP/2
connection), the bearer token, and the signed-in `UserProfile`. The per-domain API wrappers
(`UsersApi`, `ChannelsApi`, `MembersApi`, `TextMessagesApi`, `RolesApi`, `VoiceApi`, `E2eeApi`,
`AttachmentsApi`; see [Network layer](network-layer.md)) hang off the one channel
as `late final` fields **rather than being passed in separately**, so adding a new domain is one line here
and nothing at the call sites that build a session.

`serverSessionProvider` is `AsyncNotifierProvider.family<ServerSessionController, ServerSession?, String>`
keyed by `serverId`. `build(serverId)` is what runs automatically on **cold start** for an
already-connected server:

1. Look up the `ServerProfile` in `ServersController`'s list; `null` if not found.
2. Read the session token from `SecureStore`; `null` (not signed in) if there isn't one.
3. Build a `RaindropChannel` pinned to whatever fingerprint is stored for this server, and register that
   fingerprint with `PinRegistry` so the voice engine's own sockets trust the server too (see
   [Voice](voice.md#how-a-call-is-carried)). `adopt` does the same for a first connection.
4. Call `UserService.GetMe` to confirm the token is still valid.
   - Valid → returns a populated `ServerSession`.
   - `invalid_session` → clears the stored token and returns `null`.

A `null` result routes the shell to [`ReauthPrompt`](connecting-to-a-server.md#reconnecting-connectserverflowforexisting)
in the chat pane, next to the server rail (`HomeShell`'s `_SignedOutLayout`) — see `HomeShell` in
[Architecture overview](architecture-overview.md).

Two mutating methods:

- `.adopt(session)` — called once [`ConnectServerFlow.persist`](connecting-to-a-server.md) hands back
  a fresh session, so the shell picks it up without another `GetMe`. It does not set `state`: it
  stashes the session and invalidates the provider, and the next `build` returns it (and closes its
  channel when it is rebuilt). Setting `state` directly would leave any build already in flight
  (restoring from the token `persist` just saved) to land afterwards and replace it with a second
  session on the same token — and everything that follows the session (device setup, the event
  stream, channel groups) would start twice, racing each other. `persist` adopts **before** adding the
  profile for the same reason, so no restoring build starts at all.
- `.logout()` — best-effort `UserService.Logout` (a failure there is ignored — the token is being
  discarded locally regardless), then clears the stored token and sets state to `null`.
- `.leave({password, preserveData})` — `UserService.LeaveServer`, then clears the stored token and
  sets state to `null`, same as a logout. **Its failures are not swallowed**, unlike `logout()`'s: a
  wrong password comes back as `invalid_credentials` and has to reach the dialog that asked for it.
  Forgetting the server locally is the caller's next step, not part of this.

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
`(serverId, userId)`) wrapping `UserService.LookupUser`. **Riverpod's own per-argument caching is the
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
shell: one circular avatar (initial letter of `displayName`) per connected server, then the
`rail.footer` [layout slot](layout.md) — by default an "add server" button that pushes `/connect` and
a settings button that pushes `/settings`, but the user may move, add or remove them. Tapping a server
calls `activeServerIdProvider.notifier.select`. Switching servers is always a single tap, regardless
of how deep the user is in a channel — the same pattern Discord-style clients are known for.

The rail is the **one pane that is on screen for every server, signed in or not** — `HomeShell`'s
`_SignedOutLayout` keeps it beside `ReauthPrompt`, and the narrow layout puts it in the drawer — which
is why settings hang off it rather than off a server's own sidebar, where they were unreachable on a
server this device is signed out of. The sidebar's own gear and header still push `/settings` too;
they are shortcuts, not the only way in.

### Leaving or removing a server

Right-click (long-press on touch) a server avatar for its menu, the same gesture the channel tiles
use (see [Channels](channels.md)):

- **Leave server** opens [`leave_server_dialog.dart`](../lib/features/servers/widgets/leave_server_dialog.dart):
  the password (the server requires it) and an "Erase my account" switch, off by default, which is
  `preserveData` inverted — off leaves the account inactive but reserved until the server's retention
  runs out, on erases username and password at once. See the server's
  [Users doc](../../RaindropServer/docs/users.md#lifecycle). The dialog hangs up a call on that server
  first (the voice leave needs the session the server leave is about to end), calls
  `serverSessionProvider(id).notifier.leave(...)`, then `ServersController.remove(id)` — leaving always
  forgets the server on this device. Like the channel-name dialog it stays open on failure, showing
  the server's message under the field, and it resolves the session with `await ref.read(provider.future)`
  rather than hiding the menu entry, since only the *active* server's session has been restored.
- **Remove from this device** is the local-only half, identical to the Settings row: confirm,
  `logout()`, `remove(id)`. The account on the server is untouched — this is the one to use when
  signed out, since a leave needs a live session.

## Related

- [Connecting to a server](connecting-to-a-server.md) — how a `ServerSession` first comes into being.
- [Storage](storage.md) — `AppPrefs` (server list, last-active id) vs. `SecureStore` (fingerprint,
  token).
- [Settings](settings.md) — where a connected server is renamed or removed.
