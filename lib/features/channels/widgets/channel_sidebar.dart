import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/server_profile.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/users_api.dart';
import '../../../core/platform/platform_info.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/adaptive.dart';
import '../../../core/widgets/panel.dart';
import '../../servers/controllers/server_permissions.dart';
import '../../voice/controllers/voice_roster_controller.dart';
import '../../voice/widgets/voice_controls.dart';
import '../../voice/widgets/voice_participant_tile.dart';
import '../controllers/channels_controller.dart';
import '../controllers/selected_channel_controller.dart';
import '../models/channel.dart';
import 'channel_name_dialog.dart';

/// The second pane: the active server's name up top, its channel list in
/// the middle, and a persistent footer showing who's signed in — the
/// familiar three-tier layout of a chat client's channel sidebar.
class ChannelSidebar extends ConsumerWidget {
  const ChannelSidebar({
    super.key,
    required this.server,
    required this.currentUser,
  });

  final ServerProfile server;
  final UserProfile currentUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedChannelId = ref.watch(selectedChannelIdProvider);
    final channelsAsync = ref.watch(channelsProvider(server.id));
    // Creating a channel is a server-wide permission, so it is not on any
    // channel. Unknown (still loading, or an older server) reads as "no".
    final mayCreate = canCreateChannels(
      ref.watch(serverPermissionsProvider(server.id)).valueOrNull,
    );

    return SizedBox(
      width: 240,
      child: Panel(
        color: context.surfaces.sidebar,
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              left: false,
              right: false,
              child: _SidebarHeader(server: server),
            ),
            const Divider(height: 1),
            Expanded(
              child: channelsAsync.when(
                loading: () => const Center(child: AdaptiveActivityIndicator()),
                error: (err, _) => _ChannelsError(
                  error: err,
                  onRetry: () =>
                      ref.read(channelsProvider(server.id).notifier).refresh(),
                ),
                data: (channels) => channels.isEmpty
                    ? _NoChannels(
                        onCreate: mayCreate
                            ? (type) =>
                                  _createChannel(context, ref, server.id, type)
                            : null,
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: [
                          for (final category in groupByType(
                            channels,
                            alwaysShowText: mayCreate,
                            alwaysShowVoice: mayCreate,
                          ))
                            _CategorySection(
                              serverId: server.id,
                              currentUserId: currentUser.userId,
                              category: category,
                              selectedChannelId: resolveChannel(
                                channels,
                                selectedChannelId,
                              )?.id,
                              onSelect: (id) => ref
                                  .read(selectedChannelIdProvider.notifier)
                                  .select(id),
                              // Text and voice can be made; a kind this
                              // build does not know cannot.
                              onCreate:
                                  mayCreate &&
                                      category.type != ChannelType.unknown
                                  ? () => _createChannel(
                                      context,
                                      ref,
                                      server.id,
                                      category.type,
                                    )
                                  : null,
                              onRename: (channel) => _renameChannel(
                                context,
                                ref,
                                server.id,
                                channel,
                              ),
                              onDelete: (channel) => _deleteChannel(
                                context,
                                ref,
                                server.id,
                                channel,
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            // Whichever server the call is on: it follows the user around.
            const VoiceConnectionBar(),
            _UserPanel(currentUser: currentUser),
          ],
        ),
      ),
    );
  }
}

// ── Channel actions ────────────────────────────────────────────────────────
//
// Plain functions rather than methods so the tiles stay dumb: a tile knows
// which actions it was given and offers them, nothing more. The server checks
// every one of these again, so a permission that changed under an open menu
// still ends in a message rather than in a change.

Future<void> _createChannel(
  BuildContext context,
  WidgetRef ref,
  String serverId,
  ChannelType type,
) {
  // Read up front: the notifiers outlive this widget, `ref` does not, and
  // the layout can change under an open dialog.
  final channels = ref.read(channelsProvider(serverId).notifier);
  final selected = ref.read(selectedChannelIdProvider.notifier);
  final voice = type == ChannelType.voice;

  return showChannelNameDialog(
    context,
    title: voice ? 'Create voice channel' : 'Create text channel',
    confirmLabel: 'Create',
    icon: voice ? Icons.volume_up_outlined : Icons.tag,
    onSubmit: (name) async {
      final channel = await channels.create(name, type: type);
      selected.select(channel.id);
      // In the narrow layout the sidebar lives in a drawer that would
      // otherwise stay open over the channel that was just made.
      if (!context.mounted) return;
      final scaffold = Scaffold.maybeOf(context);
      if (scaffold != null && scaffold.isDrawerOpen) scaffold.closeDrawer();
    },
  );
}

Future<void> _renameChannel(
  BuildContext context,
  WidgetRef ref,
  String serverId,
  Channel channel,
) {
  final channels = ref.read(channelsProvider(serverId).notifier);
  return showChannelNameDialog(
    context,
    title: 'Rename channel',
    confirmLabel: 'Rename',
    initialName: channel.name,
    icon: channel.type == ChannelType.voice
        ? Icons.volume_up_outlined
        : Icons.tag,
    onSubmit: (name) => channels.rename(channel.id, name),
  );
}

Future<void> _deleteChannel(
  BuildContext context,
  WidgetRef ref,
  String serverId,
  Channel channel,
) async {
  final voice = channel.type == ChannelType.voice;
  final confirmed = await showAdaptiveConfirm(
    context,
    title: voice ? 'Delete ${channel.name}?' : 'Delete #${channel.name}?',
    message: voice
        ? 'This deletes the voice channel for everyone, and ends its call for '
              'anybody in it. It can\'t be undone.'
        : 'This deletes the channel and every message in it, for everyone. It '
              'can\'t be undone. The server owner keeps a copy of any messages '
              'sent before end-to-end encryption.',
    confirmLabel: 'Delete',
    destructive: true,
  );
  if (!confirmed || !context.mounted) return;

  final channels = ref.read(channelsProvider(serverId).notifier);
  try {
    await channels.delete(channel.id);
  } on ApiException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(e.message)));
  }
}

/// A server can genuinely have no channels — nobody has created one yet. A
/// member who may create channels is offered the button; anybody else is told
/// who to wait for, rather than shown an empty box that looks broken.
class _NoChannels extends StatelessWidget {
  const _NoChannels({this.onCreate});

  /// Null when the account may not create channels.
  final ValueChanged<ChannelType>? onCreate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            onCreate != null
                ? 'No channels here yet. Create the first one to give '
                      'everybody somewhere to talk.'
                : 'No channels here yet. Someone with permission to create '
                      'channels has to make one before there is anywhere to '
                      'talk.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (onCreate case final create?) ...[
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () => create(ChannelType.text),
              icon: const Icon(Icons.tag, size: 18),
              label: const Text('Create a text channel'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: () => create(ChannelType.voice),
              icon: const Icon(Icons.volume_up_outlined, size: 18),
              label: const Text('Create a voice channel'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChannelsError extends StatelessWidget {
  const _ChannelsError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            error is ApiException
                ? (error as ApiException).message
                : 'Could not load this server\'s channels.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: scheme.error),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.server});

  final ServerProfile server;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/settings'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                server.displayName,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.expand_more, size: 20),
          ],
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.serverId,
    required this.currentUserId,
    required this.category,
    required this.selectedChannelId,
    required this.onSelect,
    required this.onRename,
    required this.onDelete,
    this.onCreate,
  });

  final String serverId;
  final String currentUserId;
  final ChannelCategory category;
  final String? selectedChannelId;
  final ValueChanged<String> onSelect;
  final ValueChanged<Channel> onRename;
  final ValueChanged<Channel> onDelete;

  /// Null when this group has no "create" button — the account may not
  /// create channels, or the group is a kind this build cannot create.
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, onCreate == null ? 12 : 4, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  category.title.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    letterSpacing: 0.6,
                    color: textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (onCreate != null)
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  tooltip: category.type == ChannelType.voice
                      ? 'Create voice channel'
                      : 'Create text channel',
                  visualDensity: VisualDensity.compact,
                  onPressed: onCreate,
                )
              else
                const SizedBox(width: 8),
            ],
          ),
        ),
        for (final channel in category.channels) ...[
          _ChannelTile(
            channel: channel,
            selected: channel.id == selectedChannelId,
            onTap: () => onSelect(channel.id),
            // Offered only what the server would allow us to do here.
            onRename: channel.canRename ? () => onRename(channel) : null,
            onDelete: channel.canDelete ? () => onDelete(channel) : null,
          ),
          if (channel.type == ChannelType.voice)
            _VoiceChannelParticipants(
              serverId: serverId,
              channelId: channel.id,
              currentUserId: currentUserId,
            ),
        ],
      ],
    );
  }
}

/// Who is in a voice channel's call, listed under it — visible to anybody who
/// can see the channel, whether or not they are in the call themselves.
class _VoiceChannelParticipants extends ConsumerWidget {
  const _VoiceChannelParticipants({
    required this.serverId,
    required this.channelId,
    required this.currentUserId,
  });

  final String serverId;
  final String channelId;
  final String currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participants =
        ref
            .watch(voiceRosterProvider(serverId))
            .valueOrNull
            ?.inChannel(channelId) ??
        const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final participant in participants)
          VoiceParticipantRow(
            serverId: serverId,
            participant: participant,
            isCurrentUser: participant.userId == currentUserId,
          ),
      ],
    );
  }
}

enum _ChannelAction { rename, delete }

/// One channel in the list. Selecting is a tap; rename and delete, when the
/// account may do them, are a menu reached the way each platform reaches one:
/// a hover-revealed button and a right-click on desktop, a long press on
/// touch. A channel with neither action has no menu at all.
class _ChannelTile extends StatefulWidget {
  const _ChannelTile({
    required this.channel,
    required this.selected,
    required this.onTap,
    this.onRename,
    this.onDelete,
  });

  final Channel channel;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  @override
  State<_ChannelTile> createState() => _ChannelTileState();
}

class _ChannelTileState extends State<_ChannelTile> {
  bool _hovered = false;

  bool get _hasMenu => widget.onRename != null || widget.onDelete != null;

  Future<void> _openMenu(Offset globalPosition) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final scheme = Theme.of(context).colorScheme;

    final action = await showMenu<_ChannelAction>(
      context: context,
      position: RelativeRect.fromRect(
        globalPosition & Size.zero,
        Offset.zero & overlay.size,
      ),
      items: [
        if (widget.onRename != null)
          const PopupMenuItem(
            value: _ChannelAction.rename,
            child: ListTile(
              leading: Icon(Icons.edit_outlined),
              title: Text('Rename channel'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
        if (widget.onDelete != null)
          PopupMenuItem(
            value: _ChannelAction.delete,
            child: ListTile(
              leading: Icon(Icons.delete_outline, color: scheme.error),
              title: Text(
                'Delete channel',
                style: TextStyle(color: scheme.error),
              ),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
      ],
    );

    switch (action) {
      case _ChannelAction.rename:
        widget.onRename?.call();
      case _ChannelAction.delete:
        widget.onDelete?.call();
      case null:
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final channel = widget.channel;
    final selected = widget.selected;
    final showMoreButton = _hasMenu && isDesktopPlatform;

    Widget tile = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: selected
            ? scheme.primary.withValues(alpha: 0.16)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: widget.onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              8,
              showMoreButton ? 2 : 8,
              8,
              showMoreButton ? 2 : 8,
            ),
            child: Row(
              children: [
                Icon(
                  channel.type == ChannelType.voice
                      ? Icons.volume_up_outlined
                      : Icons.tag,
                  size: 18,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    channel.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (showMoreButton)
                  // Kept in the layout while hidden so the row does not
                  // change height, or reflow its name, when the pointer
                  // arrives.
                  Visibility(
                    visible: _hovered,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: Builder(
                      builder: (buttonContext) => IconButton(
                        icon: const Icon(Icons.more_horiz, size: 18),
                        tooltip: 'Channel options',
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          final box =
                              buttonContext.findRenderObject() as RenderBox;
                          _openMenu(
                            box.localToGlobal(box.size.bottomLeft(Offset.zero)),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!_hasMenu) return tile;

    tile = GestureDetector(
      onLongPressStart: (d) => _openMenu(d.globalPosition),
      onSecondaryTapDown: (d) => _openMenu(d.globalPosition),
      child: tile,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: tile,
    );
  }
}

class _UserPanel extends StatelessWidget {
  const _UserPanel({required this.currentUser});

  final UserProfile currentUser;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: scheme.primary,
                  child: Text(
                    currentUser.username.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: context.surfaces.onlineIndicator,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.surfaces.sidebar,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                currentUser.username,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const VoiceSelfControls(),
            IconButton(
              icon: const Icon(Icons.settings_outlined, size: 20),
              tooltip: 'Settings',
              visualDensity: VisualDensity.compact,
              onPressed: () => context.push('/settings'),
            ),
          ],
        ),
      ),
    );
  }
}
