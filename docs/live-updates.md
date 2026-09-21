# Live updates (the event stream)

The client sends through the REST API as it always has — posting a message is still
`POST /api/channels/text/messages/send` — and **receives** everything over the server's event stream:
a WebSocket at `GET /api/events` down which the server pushes every change this account may see, from
this client, from its other devices, and from every other member. Server-side reference:
[Events](../../RaindropServer/docs/events.md).

So a message one member posts shows up for everyone else as the server accepts it, a deletion turns
into a tombstone in place, a renamed channel renames in the sidebar, and the roster follows logins —
none of it waiting on a poll.

## The pieces

```
core/network/api_client.dart     ApiClient.openWebSocket — the pinned, authenticated upgrade
core/network/event_stream.dart   EventStream — one reconnecting stream, ServerEvent, the event names
features/servers/controllers/
  server_events.dart             serverEventsProvider(serverId) — one stream per signed-in server
  live_sync.dart                 LiveSync — what each controller uses to follow it
```

### `ApiClient.openWebSocket` — same pin, same token

The upgrade goes through the **same `CertificatePinner`** as every REST call and carries the same
`Authorization: Bearer` header, so a pinned server stays pinned and the token never goes in a URL
(see [Network layer](network-layer.md)). It is done by hand over an `HttpClient` — the documented
`WebSocket.fromUpgradedSocket` route — rather than with `WebSocket.connect`, because that reports every
refused upgrade identically. Doing it here keeps the status code and the server's `{error, message}`
body, so a `401` surfaces as `ApiException('invalid_session')` exactly as it would from `get`. It also
checks `Sec-WebSocket-Accept`, per RFC 6455.

### `EventStream` — one reconnecting connection

`core/`, so it knows nothing about chat or rosters. It:

- delivers every frame as a `ServerEvent(type, data)` on `events` — `ready` included — with `data`
  left as the decoded map, so each feature parses it with the `fromJson` it already has (the payloads
  are the same records the REST API returns);
- reports `EventStreamStatus` on `statusChanges`: `connecting` → `live` (on `ready`) → `disconnected`
  on a drop, then back round;
- reconnects with exponential backoff (1 s, 2 s, 4 s … capped at 30 s, with jitter so a server that
  just restarted is not hit by every client in the same instant), resetting after each `ready`;
- **stops** at `sessionEnded` — a `4401` close, or a `401` on the upgrade — because retrying with a
  dead token cannot work.

Event names are constants in `ServerEventTypes`. A name this build does not know is ignored, which is
what lets a newer server — or a server plugin — add its own without breaking this client.

The stream asks for JSON and reads text frames only; see [Wire format](wire-format.md).

### `serverEventsProvider` — one per signed-in server

`Provider.family<EventStream?, String>` keyed by `serverId`, built from the server's
`ServerSession` and null when not signed in there. Not `autoDispose`: it stays open for as long as the
session does, whether or not a pane showing that server is on screen. A new session (fresh login, new
token) is a new stream.

When the stream reports `sessionEnded`, the provider invalidates `serverSessionProvider(serverId)`.
Re-resolving the session calls `/api/users/me`, finds the token gone, clears it, and the shell routes
to `ReauthPrompt` — see [Servers & sessions](servers-and-sessions.md). This is what happens after a
**server restart**, which logs everyone out: the stream backs off while the server is down, gets a
`401` when it is back, and the user is asked for their password.

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

The fallback poll is what keeps the client working against a server too old to have `/api/events`,
or through a network that drops WebSockets: the stream keeps retrying in the background, and the
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

- The server's [Events doc](../../RaindropServer/docs/events.md) — every event type, close codes, and
  the server's guarantees.
- [Network layer](network-layer.md) — `ApiClient` and pinning.
- [Servers & sessions](servers-and-sessions.md) — how a `sessionEnded` becomes a reauth prompt.
