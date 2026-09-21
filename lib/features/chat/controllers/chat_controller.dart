import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/event_stream.dart';
import '../../../core/network/text_messages_api.dart';
import '../../servers/controllers/live_sync.dart';
import '../../servers/controllers/session_controller.dart';
import '../models/message.dart';

/// Which channel on which server a timeline belongs to. Both halves matter:
/// the same client can be signed into several servers at once, and channel
/// ids are only unique within one.
typedef ChatScope = ({String serverId, String channelId});

/// How often the newest page is re-read *while the event stream is down*.
///
/// New messages and deletions normally arrive as `message.created` and
/// `message.deleted` events (see [LiveSync]); this poll only runs while the
/// stream is reconnecting, or against a server too old to have one. Three
/// seconds is frequent enough to feel like a chat and cheap enough that an
/// idle client costs one small query per channel it has open.
const _fallbackPollInterval = Duration(seconds: 3);

/// How many messages the first load and each re-read ask for. The server caps
/// this at its own maximum (200 by default) whatever we send.
const _pageSize = 50;

/// One channel's messages, as far as this client knows them.
class ChatTimeline {
  const ChatTimeline({
    required this.messages,
    this.pending = const [],
    this.olderCursor,
    this.loadingOlder = false,
  });

  /// Confirmed messages, oldest first — the order they are rendered in.
  final List<ChatMessage> messages;

  /// Optimistic messages that are still in flight or have failed. They sit
  /// after [messages] because they are, by definition, the newest thing the
  /// user did; they carry a local id until the server hands back a real one.
  final List<ChatMessage> pending;

  /// The opaque cursor for the page *before* [messages], or null once the
  /// beginning of the channel has been reached.
  final String? olderCursor;

  final bool loadingOlder;

  bool get hasOlder => olderCursor != null;

  /// What the chat pane renders, top to bottom.
  List<ChatMessage> get all => [...messages, ...pending];

  ChatTimeline copyWith({
    List<ChatMessage>? messages,
    List<ChatMessage>? pending,
    String? olderCursor,
    bool clearOlderCursor = false,
    bool? loadingOlder,
  }) => ChatTimeline(
    messages: messages ?? this.messages,
    pending: pending ?? this.pending,
    olderCursor: clearOlderCursor ? null : (olderCursor ?? this.olderCursor),
    loadingOlder: loadingOlder ?? this.loadingOlder,
  );
}

/// Sending and receiving text messages for one channel.
///
/// Auto-disposing on purpose: the event subscription (and any fallback poll)
/// lives as long as the provider, so leaving a channel stops listening to it.
final chatProvider = AsyncNotifierProvider.autoDispose
    .family<ChatController, ChatTimeline, ChatScope>(ChatController.new);

class ChatController
    extends AutoDisposeFamilyAsyncNotifier<ChatTimeline, ChatScope> {
  static const _uuid = Uuid();

  ServerSession? _session;
  bool _disposed = false;
  bool _polling = false;

  /// False until the first page has been read. Events that arrive before
  /// then are held in [_early] and folded into that page, so nothing sent
  /// while it was loading is lost.
  bool _loaded = false;
  final _early = <ChatMessage>[];

  @override
  Future<ChatTimeline> build(ChatScope arg) async {
    // Riverpod reuses this instance when the provider rebuilds (a new session,
    // say), so everything per-build starts over here.
    _disposed = false;
    _loaded = false;
    _early.clear();
    ref.onDispose(() => _disposed = true);

    final session = await ref.watch(serverSessionProvider(arg.serverId).future);
    _session = session;
    if (session == null) return const ChatTimeline(messages: []);

    // Subscribed before the first read, not after: an event that lands while
    // the page is in flight is buffered rather than missed.
    LiveSync(
      ref,
      serverId: arg.serverId,
      onEvent: _apply,
      resync: _resync,
      fallbackPoll: _fallbackPollInterval,
    );

    final page = await session.textMessagesApi.history(
      session.token,
      channelId: arg.channelId,
      limit: _pageSize,
    );

    _loaded = true;
    final messages = mergeMessages(
      page.messages.map(_toChatMessage).toList(),
      _early,
    );
    _early.clear();

    return ChatTimeline(messages: messages, olderCursor: page.nextCursor);
  }

  // ── Receiving ────────────────────────────────────────────────────────────

  /// A pushed `message.created` or `message.deleted` for this channel. Both
  /// carry the whole message — the tombstone, for a deletion — so either is
  /// simply merged on id, exactly like a page that was read.
  void _apply(ServerEvent event) {
    if (event.channelId != arg.channelId) return;
    if (event.type != ServerEventTypes.messageCreated &&
        event.type != ServerEventTypes.messageDeleted) {
      return;
    }

    final ChatMessage message;
    try {
      message = _toChatMessage(ChannelMessage.fromJson(event.data));
    } on Object {
      return; // A payload this build cannot read is one it ignores.
    }

    final current = state.valueOrNull;
    if (!_loaded || current == null) {
      _early.add(message);
      return;
    }

    state = AsyncData(
      current.copyWith(
        messages: mergeMessages(current.messages, [message]),
        pending: _withoutEchoOf(current.pending, message),
      ),
    );
  }

  /// Our own message, pushed back to us before the send's response arrived.
  /// The server's copy now shows, so the optimistic one it replaces goes —
  /// the first one still sending with the same text. When the response
  /// arrives it finds nothing left to remove and merges on id, a no-op.
  List<ChatMessage> _withoutEchoOf(
    List<ChatMessage> pending,
    ChatMessage message,
  ) {
    if (message.authorId != _session?.currentUser.userId) return pending;
    final echo = pending
        .where(
          (m) =>
              m.status == MessageStatus.sending && m.content == message.content,
        )
        .firstOrNull;
    return echo == null
        ? pending
        : pending.where((m) => m.id != echo.id).toList();
  }

  /// Re-reads the newest page and folds it into what we already have — after
  /// every (re)connect of the event stream, and as the fallback poll while it
  /// is down. Rereading rather than asking for "messages since X" is also how
  /// deletions that happened while disconnected arrive, since a deleted
  /// message comes back as a tombstone at its original position.
  Future<void> _resync() async {
    final session = _session;
    final current = state.valueOrNull;
    // Skip if a poll is still running or the last one left us in an error
    // state — the next tick tries again either way.
    if (session == null || current == null || _polling) return;
    _polling = true;
    try {
      final page = await session.textMessagesApi.history(
        session.token,
        channelId: arg.channelId,
        limit: _pageSize,
      );
      if (_disposed) return;
      final latest = state.valueOrNull;
      if (latest == null) return;
      state = AsyncData(
        latest.copyWith(
          messages: mergeMessages(
            latest.messages,
            page.messages.map(_toChatMessage),
          ),
        ),
      );
    } on ApiException {
      // A re-read that fails is not worth surfacing: the timeline on screen is
      // still the last good one, and the stream or the next poll brings the
      // rest.
    } finally {
      _polling = false;
    }
  }

  /// Fetches the page before the oldest message held, for scrolling back
  /// through history. Does nothing once the channel's beginning is reached.
  Future<void> loadOlder() async {
    final session = _session;
    final current = state.valueOrNull;
    if (session == null ||
        current == null ||
        current.loadingOlder ||
        !current.hasOlder) {
      return;
    }

    state = AsyncData(current.copyWith(loadingOlder: true));
    try {
      final page = await session.textMessagesApi.history(
        session.token,
        channelId: arg.channelId,
        before: current.olderCursor,
        limit: _pageSize,
      );
      if (_disposed) return;
      final latest = state.valueOrNull ?? current;
      state = AsyncData(
        latest.copyWith(
          messages: mergeMessages(
            latest.messages,
            page.messages.map(_toChatMessage),
          ),
          olderCursor: page.nextCursor,
          clearOlderCursor: page.nextCursor == null,
          loadingOlder: false,
        ),
      );
    } on ApiException {
      if (_disposed) return;
      final latest = state.valueOrNull ?? current;
      state = AsyncData(latest.copyWith(loadingOlder: false));
      rethrow;
    }
  }

  // ── Sending ──────────────────────────────────────────────────────────────

  /// Posts a message, showing it immediately and replacing it with the
  /// server's copy — the real id and timestamp — once that comes back. A
  /// failure leaves it in the timeline as [MessageStatus.failed] rather than
  /// throwing away what the user typed.
  Future<void> send(String content) async {
    final session = _session;
    final current = state.valueOrNull;
    if (session == null || current == null) return;

    final text = content.trim();
    if (text.isEmpty) return;

    final optimistic = ChatMessage(
      id: 'local-${_uuid.v4()}',
      authorId: session.currentUser.userId,
      content: text,
      sentAt: DateTime.now().toUtc(),
      status: MessageStatus.sending,
    );
    state = AsyncData(
      current.copyWith(pending: [...current.pending, optimistic]),
    );

    await _deliver(optimistic);
  }

  /// Tries a failed message again, from the timeline rather than the composer.
  Future<void> retry(String localId) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final message = current.pending
        .where((m) => m.id == localId && m.status == MessageStatus.failed)
        .firstOrNull;
    if (message == null) return;

    state = AsyncData(
      current.copyWith(
        pending: _replacePending(
          current.pending,
          message.copyWith(status: MessageStatus.sending),
        ),
      ),
    );
    await _deliver(message);
  }

  /// Drops a failed message. Nothing was ever sent, so there is nothing to
  /// tell the server about.
  void discard(String localId) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        pending: current.pending.where((m) => m.id != localId).toList(),
      ),
    );
  }

  Future<void> _deliver(ChatMessage optimistic) async {
    final session = _session!;
    try {
      final stored = await session.textMessagesApi.send(
        session.token,
        channelId: arg.channelId,
        content: optimistic.content ?? '',
      );
      if (_disposed) return;
      final latest = state.valueOrNull;
      if (latest == null) return;
      // The optimistic copy goes and the server's takes its place, so an
      // event or re-read that already picked it up cannot leave it twice.
      state = AsyncData(
        latest.copyWith(
          messages: mergeMessages(latest.messages, [_toChatMessage(stored)]),
          pending: latest.pending.where((m) => m.id != optimistic.id).toList(),
        ),
      );
    } on ApiException {
      if (_disposed) return;
      final latest = state.valueOrNull;
      if (latest == null) return;
      state = AsyncData(
        latest.copyWith(
          pending: _replacePending(
            latest.pending,
            optimistic.copyWith(status: MessageStatus.failed),
          ),
        ),
      );
      rethrow;
    }
  }

  // ── Deleting ─────────────────────────────────────────────────────────────

  /// Deletes the message with [messageId] and shows the tombstone the server
  /// answers with. Not optimistic: the server decides who may delete what, so
  /// the message stays as it is until it says yes. The `message.deleted`
  /// event that follows carries the same tombstone and merges on id.
  ///
  /// Throws the server's [ApiException] — `missing_permission` for somebody
  /// else's message without `manage_messages` — for the caller to show.
  Future<void> delete(String messageId) async {
    final session = _session;
    if (session == null) return;

    final tombstone = await session.textMessagesApi.delete(
      session.token,
      messageId: messageId,
    );
    if (_disposed) return;
    final latest = state.valueOrNull;
    if (latest == null) return;
    state = AsyncData(
      latest.copyWith(
        messages: mergeMessages(latest.messages, [_toChatMessage(tombstone)]),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static ChatMessage _toChatMessage(ChannelMessage m) => ChatMessage(
    id: m.messageId,
    authorId: m.authorId,
    content: m.content,
    sentAt: m.sentAtUtc,
    deleted: m.deleted,
  );

  static List<ChatMessage> _replacePending(
    List<ChatMessage> pending,
    ChatMessage replacement,
  ) => [
    for (final m in pending)
      if (m.id == replacement.id) replacement else m,
  ];
}
