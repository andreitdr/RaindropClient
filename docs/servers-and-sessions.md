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
2. Read the session token from `SecureStore`. With one, build a `RaindropChannel` pinned to the stored
   fingerprint (registered with `PinRegistry` too, for the voice engine's sockets — see
   [Voice](voice.md#how-a-call-is-carried)) and call `UserService.GetMe`.
3. **No token, or `invalid_session`: sign in again with the device key**
   ([`signInWithDevice`](identity.md#signing-in)) and save the new token. Sessions lapse after twelve
   idle hours and a restarted server forgets them all; none of that reaches the person.
4. `network_error` (nothing answered, or not within the 20 s deadline) → **throws**. Not reaching the
   server says nothing about the account.
5. A certificate mismatch is followed only if the pinned identity key signed the new certificate
   (`ServerTrust.followCertificateChange`), and steps 2–3 are tried again.

An error puts `ServerUnreachablePane` (`features/servers/widgets/`) in the chat pane, beside the rail
(`HomeShell`'s `_SignedOutLayout`): "Can't reach …" naming the stored `host:port`, **Try again**, and
**Remove from this device** — a server that is gone for good never answers, so removing it cannot
depend on it answering.

### When signing in needs the person

Anything else settles on `null` and records why in `signInFailureProvider(serverId)`;
[`SignInPane`](../lib/features/servers/widgets/sign_in_pane.dart) takes the chat pane and asks for the
one thing missing:

| Refusal | Means | Asks for |
|---|---|---|
| `authenticator_required`, `invalid_authenticator_code`, `authenticator_locked` | The device is new to an account with an authenticator and does not hold its secret | A code, or a backup code — or, with both lost, starting [a wait](identity.md#waiting-out-a-lost-authenticator) |
| `recovery_pending` | This device is waiting to be let in without a code | Nothing: it says when, and signs in by itself then (or takes a code) |
| `recovery_cancelled` | One of the person's devices stopped the wait | A code, or a backup code |
| `invalid_username` | The server no longer has the account (reset, or erased) | A username, to join again |
| `invalid_credentials`, `device_exists` | This device was removed from the account | A go-ahead: its keys for the server are deleted and new ones made |
| anything else | | **Try again** |

All of them also offer **Remove from this device**. `ServerSessionController.signInWith(...)` is what
the pane calls, and `requestRecovery()` starts a wait.

Mutating methods:

- `.adopt(session)` — called once [`ConnectServerFlow.persist`](connecting-to-a-server.md) or
  `signInWith` has a fresh session. It does not set `state`: it stashes the session and invalidates
  the provider, and the next `build` returns it (and closes its channel when it is rebuilt). Setting
  `state` directly would let a build already in flight land afterwards with a second session, and
  everything that follows the session (device setup, the event stream, channel groups) would start
  twice.
- `.logout({forgetDevice})` — clears the stored token and sets state to `null` at once, then sends
  `UserService.Logout` — or, with `forgetDevice`, `DeviceService.RevokeDevice` for this device — **without
  waiting for it** (five-second timeout, failures ignored). Removing a server must work when the server
  is down.
- `.leave({preserveData})` — `UserService.LeaveServer`, then the same. **Its failures are not
  swallowed.** There is no password: the server takes the session being bound to a device, and the
  dialog has the person unlock first.

## Server rail

[`server_rail.dart`](../lib/features/servers/widgets/server_rail.dart) — the leftmost pane of the
shell: one circular avatar (initial letter of `displayName`) per connected server, then the
`rail.footer` [layout slot](layout.md) — by default an "add server" button that pushes `/connect`, but
the user may move, add or remove buttons there. Tapping a server
calls `activeServerIdProvider.notifier.select`. Switching servers is always a single tap, regardless
of how deep the user is in a channel — the same pattern Discord-style clients are known for.

The rail is the **one pane that is on screen for every server, signed in or not** — `HomeShell`'s
`_SignedOutLayout` keeps it beside `SignInPane` and `ServerUnreachablePane`, and the narrow layout puts
it in the drawer — which is why a server's menu (and its *Server settings*) hangs off its avatar.
User settings sit beside the person's name in the channel list by default; the two signed-out panes,
which have no channel list beside them, link to them instead. See [Settings](settings.md).

### Leaving or removing a server

Right-click (long-press on touch) a server avatar for its menu, the same gesture the channel tiles
use (see [Channels](channels.md)). Its entries come from
[`server_actions.dart`](../lib/features/servers/widgets/server_actions.dart), which the server list in
Device settings and the Server settings page use too:

- **Server settings** opens `/servers/<id>/settings` (see [Settings](settings.md#serversettingsscreen)).

- **Leave server** opens [`leave_server_dialog.dart`](../lib/features/servers/widgets/leave_server_dialog.dart):
  an "Erase my account" switch, off by default, which is `preserveData` inverted — off leaves the
  account inactive but reserved until the server's retention runs out, on erases it at once. See the
  server's [Users doc](../../RaindropServer/docs/users.md#lifecycle). The person unlocks the device
  (`confirmUnlock`); the dialog hangs up a call on that server first, calls
  `serverSessionProvider(id).notifier.leave(...)`, then `ServersController.remove(id)`.
- **Remove from this device** — `confirmRemoveServer`
  ([`remove_server.dart`](../lib/features/servers/widgets/remove_server.dart)), the one implementation
  behind the rail's menu, Device settings' server list, Server settings, `ServerUnreachablePane` and
  `SignInPane`. It is local and
  works with the server down or gone: `logout(forgetDevice: true)`, then `ServersController.remove`,
  which also records the server in `AppPrefs.hiddenServers` so the [vault](identity.md#the-vault) does
  not put it back. **The account is not deleted**: it stays on the server, where only this person's
  paired devices or recovery words can sign in to it, and adding the server again arrives back at it.

## Related

- [Connecting to a server](connecting-to-a-server.md) — how a `ServerSession` first comes into being.
- [Storage](storage.md) — `AppPrefs` (server list, last-active id) vs. `SecureStore` (fingerprint,
  token).
- [Settings](settings.md) — Server settings, and the server list in Device settings.
