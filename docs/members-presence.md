# Members & presence

Feature folder: [`lib/features/members/`](../lib/features/members/). Server-side reference:
[Members](../../RaindropServer/docs/members.md).

## Fetching and following

[`MembersController`](../lib/features/members/controllers/members_controller.dart)
(`membersProvider`, `AsyncNotifierProvider.autoDispose.family<..., List<Member>, String>` keyed by
`serverId`) fetches `GET /api/members` once and then follows the [event stream](live-updates.md):

- `member.joined` adds the member as offline — a `member.presence` follows as soon as their first
  session opens;
- `member.renamed` updates the username, `member.left` removes the row;
- `member.presence` sets their presence. It is a *state*, not a toggle — the server re-announces
  `online` when a second device logs in — so it is always applied as "set".

The roster is re-read after every reconnect. While the stream is down it falls back to polling every
**fifteen seconds** (`_fallbackPollInterval`) — slower than chat's three, because a roster a few
seconds stale reads as fine and this is a whole-server query.

`autoDispose` matters here specifically: the member pane is hidden when the window is too narrow for
it (1000px at the default widths) unless manually toggled on (see
[Native feel per platform](native-feel-per-platform.md#the-responsive-shell)), or when the user has
hidden it in their [layout](layout.md), and a hidden pane has no roster to keep current. A failed re-read leaves the last good roster on screen
rather than surfacing an error where the list used to be.

## `PresenceStatus` — client-side mirror of the server enum

[`member.dart`](../lib/features/members/models/member.dart) defines `PresenceStatus` (`online`,
`offline`), parsed from the wire **name**, never an index. It is **declared in the order the roster
shows them**, matching the server's own `PresenceStatus`
(see the server's [Members doc](../../RaindropServer/docs/members.md#presence-is-derived-never-stored)) —
neither side persists the numeric value, so adding a status (`idle`, `doNotDisturb`) means inserting a
value in its rightful place here *and* a matching one on the server, with nothing to migrate.

A wire name this build has never heard of parses to `offline` — the one bucket that claims nothing
about somebody, which is the honest answer when the client can't say what the server meant.

## Grouping and sorting

`groupByPresence(members)` splits the roster into `MemberGroup`s: one per `PresenceStatus` in
declaration order, and within each group, members sorted by username, **lower-cased** so `Zoe` sorts
next to `alice` rather than after every lower-cased name. Empty groups are dropped.

The server already returns the list sorted the same way, but the client sorts again for itself
regardless — it has to group under headings either way, and a list that merely *arrived* in the right
order is one server-side refactor away from arriving in the wrong one.

## Rendering

[`MemberList`](../lib/features/members/widgets/member_list.dart) — the rightmost pane: a heading per
presence group (`ONLINE — 3`), then each member as an avatar (initial letter + a presence dot) and
username. The signed-in user's own row is marked `you` (matched by comparing `member.id` to
`currentUserId` — the roster is the same list for everyone, so "which row is me" is *found*, not
passed in separately). Offline members are **dimmed, not hidden** — a 40%-opacity avatar and muted
text — which is what makes the two groups readable at a glance without needing a second theme color.

Only `online` gets a dedicated color (`AppSurfaces.onlineIndicator`, see [Theming](theming.md));
`offline` borrows `colorScheme.onSurfaceVariant` at reduced opacity.

## Related

- [Theming](theming.md) — `onlineIndicator`, the one presence-specific color.
- The server's [Members doc](../../RaindropServer/docs/members.md) — why presence is only ever as
  sharp as live sessions, and what a restart or an unclean disconnect does to it.
