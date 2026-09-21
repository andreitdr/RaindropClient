# Channels

Feature folder: [`lib/features/channels/`](../lib/features/channels/). Server-side reference:
[Channels](../../RaindropServer/docs/channels.md).

## Fetching the list

[`ChannelsController`](../lib/features/channels/controllers/channels_controller.dart)
(`channelsProvider`, `AsyncNotifierProvider.family<..., List<Channel>, String>` keyed by `serverId`)
fetches `GET /api/channels` once per server and then follows the [event stream](live-updates.md):
`channel.created` and `channel.renamed` upsert the channel (the server sends each member the channel
with *their own* `yourPermissions`, so it is exactly the row a re-read would give), `channel.deleted`
removes it, and any `role.*` or `member.roles` event re-reads the list — a role change can change which
channels this account sees and what it may do in them, and working that out here would mean
re-deriving the server's resolver. The list is re-read after every reconnect; it has no fallback poll,
since it changes rarely and never polled before. It also re-fetches whenever the underlying
`serverSessionProvider` changes: signing out empties the list, signing back in refills it.
`.refresh()` still forces a read.

### Creating, renaming and deleting

The same controller has the three writes — `create(name)`, `rename(id, name)` and `delete(id)` — calling
`ChannelsApi.create/rename/delete`. Each folds the server's answer into the list itself and throws the
server's `ApiException` for the caller to show. The `channel.*` event the server then pushes back to the
member who caused the change merges on id (`_applyTo`), so the REST response and the echo cannot leave a
channel showing twice. There is nothing to do for a deleted channel that was selected: `resolveChannel`
already falls back to another one (see [Selection](#selection)).

What a member may do arrives two ways, and the difference matters:

- **Per channel**, in `yourPermissions`: `rename_channels`, `delete_channels` and `manage_messages`. A
  channel's *creator* holds the first three implicitly, and the server reports it that way.
- **Server-wide**: `create_channels` is not about any channel — and a server with no channels has nowhere
  to report it — so it is read once from `GET /api/roles/me` by
  [`serverPermissionsProvider`](../lib/features/servers/controllers/server_permissions.dart)
  (`RolesApi`), which re-reads on `role.*` / `member.roles` events. Until it is known (or against a server
  without the endpoint) it reads as "may not", so the button stays hidden rather than being offered and
  refused.

## `Channel` — the model the UI reads

[`channel.dart`](../lib/features/channels/models/channel.dart) reduces the server's `ChannelSummary`
down to what the sidebar and chat pane actually need:

- `id`, `name`, `type` (`ChannelType.text` / `.voice` / `.unknown`)
- `canSendMessages` — resolved from `yourPermissions` (see the server's
  [Roles & permissions doc](../../RaindropServer/docs/roles-and-permissions.md)). **The composer is
  disabled client-side when this is false, rather than letting a send attempt fail with a 403** — see
  [Messages & chat](messages-chat.md).
- `canRename`, `canDelete` — whether the sidebar offers rename / delete for this channel.
- `canManageMessages` — whether we may delete *other* members' messages here (`manage_messages`). Deleting
  our own needs no permission, so this never gates that — see
  [Messages & chat](messages-chat.md#deleting-a-message).
- `canConnect`, `canSpeak` — for a voice channel, whether we may join its call and whether we would be
  heard in it (`connect`, `speak`). See [Voice](voice.md).

`ChannelType.unknown` is what a type added to a newer server than this build arrives as — it's listed
and greyed out in the sidebar rather than crashing it. `groupByType()` buckets a channel list into
`ChannelCategory` sections (`Text Channels`, `Voice Channels`, `Other`) purely as a client-side
presentation choice — the server has no concept of categories, and drops empty groups so a server with
no voice channels shows no voice heading at all — unless `alwaysShowText` / `alwaysShowVoice` is set,
which the sidebar does for a member who may create channels, so the "+" for each kind has a heading to
sit on.

Selecting a voice channel opens the [voice view](voice.md#ui) in place of the chat pane; it never joins
the call by itself.

## Selection

[`SelectedChannelController`](../lib/features/channels/controllers/selected_channel_controller.dart)
(`selectedChannelIdProvider`) holds **only the user's choice of channel id**, deliberately not the
resolved `Channel` object — that id might belong to another server, or point at a channel that's since
been deleted. `resolveChannel(channels, selectedId)` is what turns a raw id into the channel to
actually render: the selected one if it's still present, otherwise the first text channel, otherwise
the first channel of any kind, or `null` if the server has no channels at all. `HomeShell` calls this
every build (see [Architecture overview](architecture-overview.md)).

## `ChannelSidebar`

[`channel_sidebar.dart`](../lib/features/channels/widgets/channel_sidebar.dart) — the second pane of
the shell: the active server's name (tapping it opens `/settings`), the grouped channel list, and a
persistent footer showing the signed-in user (avatar with an online dot, username, a settings
shortcut).

- **Create** — a "+" on the *Text Channels* and *Voice Channels* headings, shown only when the account
  has `create_channels` (both headings are shown even when empty, for that reason);
  `ChannelsController.create(name, type:)` passes the kind through. A server with genuinely zero
  channels shows an empty state that offers "Create a text channel" and "Create a voice channel" to a
  member who may, and otherwise says someone with permission has to make one. Creating selects the new
  channel and, in the narrow layout, closes the drawer over it.
- **Who is in each call** — every voice channel lists its call's participants underneath (from
  `voiceRosterProvider`), with their mute/deafen icons; right-click / long press opens the
  [member menu](voice.md#ui). Above the signed-in user, `VoiceConnectionBar` shows the call this client
  is in, and the footer has mic and headset buttons.
- **Rename / delete** — a menu on each channel that offers only what `canRename` / `canDelete` allow
  (none at all → no menu). It is reached the way each platform reaches one, decided by
  `isDesktopPlatform`: a hover-revealed "…" button and a right-click on desktop, a long press on touch.
  Delete confirms with `showAdaptiveConfirm` — for a text channel it says the server owner keeps a copy
  of the channel's messages, for a voice channel that deleting it ends its call (see the server's [deleted-message archive](../../RaindropServer/docs/messages.md#the-deleted-message-archive)).
- **The name dialog** ([`channel_name_dialog.dart`](../lib/features/channels/widgets/channel_name_dialog.dart))
  is shared by create and rename. It pre-checks the name with `validateChannelName`
  ([`channel_name.dart`](../lib/features/channels/models/channel_name.dart), a copy of the server's
  `ChannelNamePolicy` for UX only), and shows whatever the server refuses — `channel_name_taken` is the
  usual one, and only the server can know it — under the field, keeping the dialog open so the name can be
  corrected.

## Related

- [Messages & chat](messages-chat.md) — what happens once a channel is selected.
- [Roadmap](roadmap.md) — voice channels are not implemented client-side yet, and the server refuses to
  create one.
