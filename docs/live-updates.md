# Live updates (the event stream)

The client **sends** through ordinary gRPC calls (posting a message is
`TextChannelService.SendEncryptedMessage`) and **receives** everything over the server's event stream.
That stream is `EventService.Connect`, a bidirectional gRPC stream: the server pushes every change this
account may see, whether from this client, its other devices or any other member. The client sends a
heartbeat back up it every 20 seconds. Server-side reference:
[Events](../../RaindropServer/docs/events.md).

So a message one member posts shows up for everyone else as the server accepts it, a deletion turns
into a tombstone in place, a renamed channel renames in the sidebar, and the roster follows logins —
none of it waiting on a poll.

## The pieces

```
core/network/event_stream.dart   EventStream — one reconnecting, heartbeating stream; ServerEvent
features/servers/controllers/
  server_events.dart             serverEventsProvider(serverId) — one stream per signed-in server
  live_sync.dart                 LiveSync — what each controller uses to follow it
```

### `EventStream`: one reconnecting stream

It lives in `core/`, so it knows nothing about chat or rosters. It rides the server's one
`RaindropChannel`: the same pinned HTTP/2 connection as every call, with the token as
`authorization` metadata (see [Network layer](network-layer.md)). It:

- **Delivers every event as a `ServerEvent` on `events`**, `ready` included. A `ServerEvent` wraps the
  typed `pb.ServerEvent`, and answers `type` (`message.created`, `e2ee.handshake`, …, the names the
  server publishes under, so a feature's `switch` reads like the server's docs), `userId` and
  `channelId` from whichever `oneof` case it carries. A feature filters on those, then reads its case
  (`event.proto.messageCreated`) with the same `fromProto` its wrapper uses for a call's answer.
- **Heartbeats.** After each `ready` it sends a `Heartbeat` every `ready.heartbeat_interval` (20 s). A
  stream the server stops hearing from is ended as `connection_lost`, and its member then reads as
  offline, which is how presence notices a client that was killed rather than closed.
- **Resubscribes.** `resubscribe()` asks for a fresh `ready` on the open stream.
  `serverEventsProvider` calls it when the app returns to the foreground, so every screen re-reads
  without the stream being torn down.
- **Reports `EventStreamStatus`** on `statusChanges`: `connecting` → `live` (on `ready`) →
  `disconnected` on a drop, then back round.
- **Reconnects with exponential backoff** (1 s, 2 s, 4 s … capped at 30 s, with jitter so a server
  that just restarted is not hit by every client in the same instant), resetting after each `ready`.
- **Stops at `sessionEnded`**, because retrying with a dead token cannot work. That is a stream that
  ended with `ErrorInfo.reason` `session_ended`, or was refused at the start as `invalid_session` /
  `missing_token`. Every other ending (`server_stopping`, `too_slow`, `connection_lost`, a network
  failure) is a drop.

A `oneof` case this build does not know reads as `unknown` and is ignored. A server plugin's event
arrives as `plugin`, its `type` the plugin's own name. That is what lets a newer server, or a plugin,
add events without breaking this client.

### `serverEventsProvider` — one per signed-in server

`Provider.family<EventStream?, String>` keyed by `serverId`, built from the server's
`ServerSession` and null when not signed in there. Not `autoDispose`: it stays open for as long as the
session does, whether or not a pane showing that server is on screen. A new session (fresh login, new
token) is a new stream.

When the stream reports `sessionEnded`, the provider invalidates `serverSessionProvider(serverId)`.
Re-resolving the session calls `UserService.GetMe`, finds the token gone and clears it, and the shell
routes to `ReauthPrompt` (see [Servers & sessions](servers-and-sessions.md)). This is what happens
after a **server restart**, which logs everyone out: the stream backs off while the server is down, is
refused as `invalid_session` when it is back, and the user is asked for their password.

### Coming back from the background

Anything could have changed while the app was not looking — a phone unlocked, a laptop woken — even if
the stream survived. So `serverEventsProvider` registers an `AppLifecycleListener` whose `onResume`
calls `EventStream.resubscribe()`: it asks the server for a fresh `ready` on the open stream, and that
`ready` is every feature's cue to re-read, since the server replays nothing. Nothing is torn down, and
it does nothing while the stream is not open (a stream that is down is already reconnecting). Desktop
windows are never suspended, so there it is cheap and rarely matters. See
[Android and iOS](mobile.md).

### `LiveSync` — how a controller follows the stream

Every controller that shows server state constructs one in `build`, handing it three things:

| | Called |
|---|---|
| `onEvent` | for every event except `ready` — the controller picks out the ones it cares about |
| `resync` | on every `ready`, i.e. after each (re)connect, and as the fallback poll |
| `fallbackPoll` | the interval to poll at **only while the stream is not live** (optional) |

Two rules make this correct rather than merely fast:

- **Re-read after every `ready`.** The server replays nothing, so what changed while the stream was
  down is only picked up by reading it again — and reading *after* `ready` is what guarantees no gap,
  because anything that changes after that point arrives as an event.
- **Subscribe before the first read.** Each controller creates its `LiveSync` *before* its initial
  fetch, and holds events that arrive meanwhile in an `_early` list that it folds into the result. An
  event landing while the first page is in flight is buffered, not lost.

The fallback poll keeps the client current while the stream is down: a network that drops
long-lived connections, or a server restarting. The stream keeps retrying in the background, and the
moment it goes live the poll stops.

## Who follows what

| Controller | Events | On `ready` | Fallback poll |
|---|---|---|---|
| `ChatController` ([Messages & chat](messages-chat.md)) | `message.created`, `message.deleted` for its channel | re-read newest page | 3 s |
| `MembersController` ([Members & presence](members-presence.md)) | `member.joined`, `.renamed`, `.left`, `.presence` | re-read roster | 15 s |
| `ChannelsController` ([Channels](channels.md)) | `channel.created`, `.renamed`, `.deleted`; `role.*` and `member.roles` trigger a re-read | re-read list | none |
| `serverPermissionsProvider` ([Channels](channels.md#creating-renaming-and-deleting)) | `role.*` and `member.roles` → re-read what this account may do server-wide | re-read | none |
| `userLookupProvider` ([Servers & sessions](servers-and-sessions.md#user-lookup-cache)) | `member.renamed`, `.left`, `.joined` for that UUID → re-lookup | — | — |
| `voiceRosterProvider` ([Voice](voice.md#state)) | `voice.state` (upsert), `voice.left` (remove), `channel.deleted` (drop the call); `role.*` and `member.roles` trigger a re-read | re-read | 15 s |
| `voiceCallProvider` ([Voice](voice.md#state)) | `voice.state` / `voice.left` about this client in its call → moderator mute, or the call ending with a reason | — | — |

Every event carries state, not a change — the whole message, the tombstone, the channel with this
account's own permissions — so applying one twice, or one a re-read already reflected, changes
nothing. That is what makes it safe for an event and a re-read to overlap.

## Riverpod note: per-build flags

Riverpod **reuses a notifier instance** when its provider rebuilds (a new session, say), so every
per-build field — `_loaded`, `_early`, `_disposed` — is reset at the top of `build`. `_disposed` in
particular used to be set by the first rebuild's `onDispose` and never cleared, which would have
silently dropped every later re-read.

## Related

- The server's [Events doc](../../RaindropServer/docs/events.md) — every event, how a stream ends, and
  the server's guarantees.
- [Network layer](network-layer.md) — `RaindropChannel` and pinning.
- [Servers & sessions](servers-and-sessions.md) — how a `sessionEnded` becomes a reauth prompt.
- [Android and iOS](mobile.md) — why a phone needs `resubscribe()` at all.
