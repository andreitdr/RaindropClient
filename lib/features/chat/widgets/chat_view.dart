import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/platform/platform_info.dart';
import '../../../core/widgets/adaptive.dart';
import '../../channels/models/channel.dart';
import '../../servers/controllers/session_controller.dart';
import '../../servers/controllers/user_lookup.dart';
import '../controllers/chat_controller.dart';
import '../models/message.dart';

class ChatView extends ConsumerStatefulWidget {
  const ChatView({
    super.key,
    required this.serverId,
    required this.channel,
    this.leading,
    this.trailingActions = const [],
  });

  final String serverId;
  final Channel channel;
  final Widget? leading;
  final List<Widget> trailingActions;

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  final _composerController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  ChatScope get _scope =>
      (serverId: widget.serverId, channelId: widget.channel.id);

  @override
  void dispose() {
    _composerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Only follow the conversation when the reader is already at the bottom —
  /// yanking them down while they are reading back through history is the
  /// one thing a chat client must not do.
  bool get _isAtBottom {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    return position.maxScrollExtent - position.pixels < 120;
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animate) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  Future<void> _send() async {
    final text = _composerController.text.trim();
    if (text.isEmpty || _sending) return;

    _composerController.clear();
    setState(() => _sending = true);
    _scrollToBottom();
    try {
      await ref.read(chatProvider(_scope).notifier).send(text);
    } on ApiException catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showError(ApiException e) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));

  @override
  Widget build(BuildContext context) {
    final timelineAsync = ref.watch(chatProvider(_scope));
    final currentUserId = ref
        .watch(serverSessionProvider(widget.serverId))
        .valueOrNull
        ?.currentUser
        .userId;

    // Anything arriving — our own send, or somebody else's message picked up
    // by the poller — follows the bottom of the list if that is where we are.
    ref.listen(chatProvider(_scope), (previous, next) {
      final before = previous?.valueOrNull?.all.length ?? 0;
      final after = next.valueOrNull?.all.length ?? 0;
      if (after > before && _isAtBottom) _scrollToBottom();
    });

    return Column(
      children: [
        _ChatTopBar(
          channel: widget.channel,
          leading: widget.leading,
          actions: widget.trailingActions,
        ),
        const Divider(height: 1),
        Expanded(
          child: timelineAsync.when(
            loading: () => const Center(child: AdaptiveActivityIndicator()),
            error: (err, _) => _TimelineError(
              error: err,
              onRetry: () => ref.invalidate(chatProvider(_scope)),
            ),
            data: (timeline) => _Timeline(
              scope: _scope,
              timeline: timeline,
              channelName: widget.channel.name,
              currentUserId: currentUserId,
              canManageMessages: widget.channel.canManageMessages,
              scrollController: _scrollController,
            ),
          ),
        ),
        _Composer(
          controller: _composerController,
          channel: widget.channel,
          sending: _sending,
          onSend: _send,
        ),
      ],
    );
  }
}

class _Timeline extends ConsumerWidget {
  const _Timeline({
    required this.scope,
    required this.timeline,
    required this.channelName,
    required this.currentUserId,
    required this.canManageMessages,
    required this.scrollController,
  });

  final ChatScope scope;
  final ChatTimeline timeline;
  final String channelName;

  /// Who is signed in, for telling which messages are theirs.
  final String? currentUserId;

  /// Whether we may delete *other* members' messages in this channel.
  final bool canManageMessages;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = timeline.all;
    if (messages.isEmpty && !timeline.hasOlder) {
      return _EmptyChannelState(channelName: channelName);
    }

    // The header row is the "load earlier" affordance, so it scrolls with
    // the history it belongs to rather than floating over it.
    final headerCount = timeline.hasOlder ? 1 : 0;

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: messages.length + headerCount,
      itemBuilder: (context, index) {
        if (headerCount == 1 && index == 0) {
          return _LoadOlderButton(
            loading: timeline.loadingOlder,
            onPressed: () => ref.read(chatProvider(scope).notifier).loadOlder(),
          );
        }
        final message = messages[index - headerCount];
        return _MessageRow(
          key: ValueKey(message.id),
          scope: scope,
          message: message,
          canDelete: canDeleteMessage(
            message,
            currentUserId: currentUserId,
            canManageMessages: canManageMessages,
          ),
        );
      },
    );
  }
}

class _ChatTopBar extends StatelessWidget {
  const _ChatTopBar({
    required this.channel,
    this.leading,
    required this.actions,
  });

  final Channel channel;
  final Widget? leading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      left: false,
      right: false,
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            ?leading,
            const SizedBox(width: 8),
            Icon(
              channel.type == ChannelType.voice
                  ? Icons.volume_up_outlined
                  : Icons.tag,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(channel.name, style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            ...actions,
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _LoadOlderButton extends StatelessWidget {
  const _LoadOlderButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: loading
            ? const Padding(
                padding: EdgeInsets.all(8),
                child: AdaptiveActivityIndicator(),
              )
            : TextButton(
                onPressed: onPressed,
                child: const Text('Load earlier messages'),
              ),
      ),
    );
  }
}

class _TimelineError extends StatelessWidget {
  const _TimelineError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 40, color: scheme.error),
            const SizedBox(height: 12),
            Text(
              error is ApiException
                  ? (error as ApiException).message
                  : 'Could not load this channel.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _EmptyChannelState extends StatelessWidget {
  const _EmptyChannelState({required this.channelName});

  final String channelName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tag,
              size: 44,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              'Welcome to #$channelName',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'This is the beginning of the channel. Say something.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageRow extends ConsumerStatefulWidget {
  const _MessageRow({
    super.key,
    required this.scope,
    required this.message,
    required this.canDelete,
  });

  final ChatScope scope;
  final ChatMessage message;

  /// Whether this account may delete this message — see [canDeleteMessage].
  final bool canDelete;

  @override
  ConsumerState<_MessageRow> createState() => _MessageRowState();
}

class _MessageRowState extends ConsumerState<_MessageRow> {
  bool _hovered = false;

  ChatMessage get _message => widget.message;

  /// Touch has no hover, so a message's actions live behind a long press.
  /// Only a message that is really on the server has any: there is nothing
  /// to copy or delete on a tombstone, or on one still being sent.
  bool get _hasSheet =>
      !isDesktopPlatform &&
      !_message.deleted &&
      _message.status == MessageStatus.sent;

  Future<void> _openSheet() async {
    final action = await showModalBottomSheet<_MessageAction>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: const Text('Copy text'),
                onTap: () => Navigator.pop(sheetContext, _MessageAction.copy),
              ),
              if (widget.canDelete)
                ListTile(
                  leading: Icon(Icons.delete_outline, color: scheme.error),
                  title: Text(
                    'Delete message',
                    style: TextStyle(color: scheme.error),
                  ),
                  onTap: () =>
                      Navigator.pop(sheetContext, _MessageAction.delete),
                ),
            ],
          ),
        );
      },
    );

    switch (action) {
      case _MessageAction.copy:
        await Clipboard.setData(ClipboardData(text: _message.content ?? ''));
      case _MessageAction.delete:
        if (mounted) await _delete();
      case null:
    }
  }

  Future<void> _delete() async {
    final confirmed = await showAdaptiveConfirm(
      context,
      title: 'Delete message?',
      message:
          'This deletes the message for everyone. The server owner keeps a '
          'copy.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    final chat = ref.read(chatProvider(widget.scope).notifier);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await chat.delete(_message.id);
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final message = _message;
    final authorName = displayNameFor(ref, (
      serverId: widget.scope.serverId,
      userId: message.authorId,
    ));
    final failed = message.status == MessageStatus.failed;
    final showHoverDelete = widget.canDelete && isDesktopPlatform;

    Widget row = Opacity(
      opacity: message.status == MessageStatus.sending ? 0.55 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: failed ? scheme.error : scheme.primary,
              child: Text(
                authorName.characters.first.toUpperCase(),
                style: TextStyle(
                  color: failed ? scheme.onError : scheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          authorName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat.Hm().format(message.sentAt.toLocal()),
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  _MessageBody(message: message),
                  if (failed)
                    _FailedActions(scope: widget.scope, localId: message.id),
                ],
              ),
            ),
            if (showHoverDelete)
              // Kept in the layout while hidden so the text does not reflow
              // when the pointer arrives.
              Visibility(
                visible: _hovered,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  tooltip: 'Delete message',
                  visualDensity: VisualDensity.compact,
                  color: scheme.onSurfaceVariant,
                  onPressed: _delete,
                ),
              ),
          ],
        ),
      ),
    );

    if (_hasSheet) {
      row = GestureDetector(onLongPress: _openSheet, child: row);
    }
    if (showHoverDelete) {
      row = MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: row,
      );
    }
    return row;
  }
}

enum _MessageAction { copy, delete }

/// A deleted message keeps its place with no text — the server sends the
/// tombstone deliberately, so dropping it here would misrepresent history.
class _MessageBody extends StatelessWidget {
  const _MessageBody({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (message.deleted || message.content == null) {
      return Text(
        'Message deleted',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    // Selecting text is a long press on touch and a right-click on desktop —
    // the very gestures the row uses for its own actions. On touch the row's
    // sheet (which has "Copy text") takes them over, so the text is plain
    // there; on desktop selection keeps them and delete is a hover button.
    return isDesktopPlatform
        ? SelectableText(message.content!)
        : Text(message.content!);
  }
}

class _FailedActions extends ConsumerWidget {
  const _FailedActions({required this.scope, required this.localId});

  final ChatScope scope;
  final String localId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          'Not sent',
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: scheme.error),
        ),
        TextButton(
          onPressed: () async {
            try {
              await ref.read(chatProvider(scope).notifier).retry(localId);
            } on ApiException {
              // The message stays marked as failed; nothing more to say.
            }
          },
          child: const Text('Retry'),
        ),
        TextButton(
          onPressed: () =>
              ref.read(chatProvider(scope).notifier).discard(localId),
          child: const Text('Discard'),
        ),
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.channel,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final Channel channel;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    // The server answers 403 for a channel we may not post in, so ask the
    // permissions it already sent rather than finding out by being refused.
    final canSend = channel.type == ChannelType.text && channel.canSendMessages;

    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: canSend,
                    minLines: 1,
                    maxLines: 5,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: canSend
                          ? 'Message #${channel.name}'
                          : channel.type == ChannelType.text
                          ? "You can't post in #${channel.name}"
                          : 'Only text channels carry messages',
                    ),
                    onSubmitted: (_) => onSend(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded),
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: canSend && !sending ? onSend : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
