# Messages & chat

Feature folder: [`lib/features/chat/`](../lib/features/chat/). Server-side reference:
[Messages](../../RaindropServer/docs/messages.md).

Text channels are real: `ChannelsApi` fetches the channel list (see [Channels](channels.md)) and
`TextMessagesApi` wraps `/api/channels/text/messages/{send,history}` (see
[Network layer](network-layer.md)).
[`ChatController`](../lib/features/chat/controllers/chat_controller.dart) owns one channel's timeline,
keyed by a `(serverId, channelId)` pair — the same client can be signed into several servers at once,
and channel ids are only unique within one server.

`chatProvider` is `AsyncNotifierProvider.autoDispose.family<ChatController, ChatTimeline, ChatScope>`.
`autoDispose` matters here: the event subscription and any fallback poll (below) live as long as the
provider, so leaving a channel actually stops listening to it rather than leaking a timer.

## `ChatTimeline`

The state shape: `messages` (confirmed, oldest first — render order), `pending` (optimistic messages
still in flight or failed — always rendered after `messages`, since they're by definition the newest
thing the user did), `olderCursor` (the opaque cursor for the page before `messages`, or `null` at the
channel's beginning), and `loadingOlder`. `.all` is the concatenation the chat pane actually renders.

## Receiving is pushed

Messages arrive over the server's [event stream](live-updates.md). `message.created` and
`message.deleted` for this channel each carry the whole message — the tombstone, for a deletion — so
either is simply merged on id, exactly like a page that was read. Nothing polls while the stream is
live.

`_resync()` re-reads the newest page and merges it: after every (re)connect of the stream — the
server replays nothing, so this is how what happened while disconnected is picked up, deletions
included, since a deleted message comes back as a tombstone in place — and as the **fallback poll**
every three seconds (`_fallbackPollInterval`) while the stream is down, or against a server too old to
have one.

Events that arrive while the first page is still loading are buffered in `_early` and folded into it,
so nothing sent during the initial load is lost. A re-read that fails is swallowed, not surfaced — the
timeline on screen is still the last good one.

**Caveat:** a re-read only ever reads the newest page (`_pageSize = 50`, capped server-side at its own
maximum). A burst of more than 50 messages while the stream was down could leave a gap in the middle of
the timeline; scrolling back with `loadOlder()` re-reads across any such gap because it re-fetches and
re-merges rather than trusting what's already cached.

## Sending is optimistic

`send(content)` immediately appends a `ChatMessage` with a local id
(`'local-${uuid.v4()}'`) and `MessageStatus.sending`, then posts to the server. When the server
responds:

- **Success** — the optimistic entry is removed from `pending` and the server's real copy (real id,
  real timestamp) is merged into `messages`. Merging on id is what keeps an event or re-read that
  already picked up the same message from showing it twice.
- **The echo** — the server also pushes our own message back as `message.created`, and it can arrive
  *before* the send's response. When it does, it replaces the first pending message still sending with
  the same text (`_withoutEchoOf`), so the message never shows twice; the response then finds nothing
  left to remove and merges on id, a no-op.
- **Failure** — the entry stays in `pending`, now marked `MessageStatus.failed`, with `retry(localId)`
  and `discard(localId)` available — the typed text is never thrown away on a failed send.

## Deletion tombstones

A deleted message still arrives from the server, with `content == null` and `deleted == true` (see the
server's [Messages doc](../../RaindropServer/docs/messages.md#deletion-is-a-tombstone)). The client
renders it as "message deleted" in place. **Dropping it instead would misrepresent the conversation and
break the paging cursor**, which may point at that exact row.

## Deleting a message

`ChatController.delete(messageId)` calls `TextMessagesApi.delete` and merges the tombstone the server
answers with. It is **not optimistic** — the server decides who may delete what, so the message stays as it
is until the server says yes — and it throws the server's `ApiException` (`missing_permission`, …) for the
view to show. The `message.deleted` event that follows carries the same tombstone and merges on id.

**Who is offered a delete** is `canDeleteMessage` in
[`message.dart`](../lib/features/chat/models/message.dart), two independent rules that mirror the server's:

- **your own message: always** — no permission is consulted, so a member whose roles grant almost
  nothing can still take back what they said;
- **somebody else's: only with `manage_messages`** in the channel (`Channel.canManageMessages`; a channel's
  creator has it implicitly).

Never on a message that is already a tombstone, or one that has not reached the server (still sending, or
failed — those are discarded, not deleted). The server checks all of it again regardless.

In [`chat_view.dart`](../lib/features/chat/widgets/chat_view.dart): on desktop the row shows a
hover-revealed trash button; on touch a long press opens a bottom sheet ("Copy text", and "Delete message"
when allowed). Both confirm with `showAdaptiveConfirm` — the server keeps a copy of a deleted message for
its owner (see the server's [deleted-message archive](../../RaindropServer/docs/messages.md#the-deleted-message-archive)),
so the dialog says so rather than promising the message is gone. Selecting text is a long press on touch
and a right-click on desktop — the gestures the row uses — so message text is `SelectableText` only on
desktop; on touch it is plain `Text` and the sheet's "Copy text" replaces selecting.

**Tombstones win when merging.** `mergeMessages` (same file as `ChatMessage`) replaces a known id with the
incoming copy — except that a copy which is *not* deleted never overwrites one that is. A message never
becomes readable again, and without that a re-read that began before a delete and finished after it would
put back text the server has already destroyed.

## History paging

History pages backwards through the server's opaque cursor: pass `nextCursor` back as `Before`
untouched — **never parse it client-side**. `ChatView` exposes this as a "Load earlier messages" row
at the top of the message list, wired to `ChatController.loadOlder()`.

## Resolving author names

A message carries only its author's UUID. `userLookupProvider` (see
[Servers & sessions](servers-and-sessions.md#user-lookup-cache)) resolves it to a display name, using
Riverpod's per-argument caching as the cache itself — one request per distinct author, however many
messages they wrote.

## Related

- [Channels](channels.md) — where a channel's `canSendMessages` disables the composer up front, and
  where `canManageMessages` comes from.
- [Network layer](network-layer.md) — `TextMessagesApi`'s exact request/response shapes.
- [Wire format](wire-format.md) — currently JSON only.
