import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/crypto/message_payload.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/event_stream.dart';
import '../../../core/network/text_messages_api.dart';
import '../../security/controllers/channel_groups.dart';
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

  /// The channel groups when the server and this device do end-to-end
  /// encryption; null against a server that does not, where messages are
  /// plaintext as before.
  ChannelGroups? _groups;
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
    _groups = await ref.watch(channelGroupsProvider(arg.serverId).future);

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

    // Joining the channel's group before reading, so messages sent since this
    // device joined can be decrypted. A device that cannot join (no access to
    // the group yet) still sees the timeline, with placeholders.
    try {
      await _groups?.ensureJoined(arg.channelId);
    } on Object catch (e) {
      debugPrint('chat: could not join the encryption group: $e');
    }

    _loaded = true;
    final messages = mergeMessages(await _decodeAll(page.messages), _early);
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

    final ChannelMessage wire;
    try {
      wire = ChannelMessage.fromJson(event.data);
    } on Object {
      return; // A payload this build cannot read is one it ignores.
    }
    unawaited(_applyDecoded(wire));
  }

  Future<void> _applyDecoded(ChannelMessage wire) async {
    final message = await _decode(wire);
    if (_disposed) return;

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
      final decoded = await _decodeAll(page.messages);
      if (_disposed) return;
      final latest = state.valueOrNull;
      if (latest == null) return;
      state = AsyncData(
        latest.copyWith(messages: mergeMessages(latest.messages, decoded)),
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
      final decoded = await _decodeAll(page.messages);
      if (_disposed) return;
      final latest = state.valueOrNull ?? current;
      state = AsyncData(
        latest.copyWith(
          messages: mergeMessages(latest.messages, decoded),
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
      final groups = _groups;
      final stored = groups == null
          ? await session.textMessagesApi.send(
              session.token,
              channelId: arg.channelId,
              content: optimistic.content ?? '',
            )
          : await _sendEncrypted(session, groups, optimistic);
      if (_disposed) return;
      final latest = state.valueOrNull;
      if (latest == null) return;
      // The optimistic copy goes and the server's takes its place, so an
      // event or re-read that already picked it up cannot leave it twice.
      state = AsyncData(
        latest.copyWith(
          messages: mergeMessages(latest.messages, [await _decode(stored)]),
          pending: latest.pending.where((m) => m.id != optimistic.id).toList(),
        ),
      );
    } on Exception {
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
        messages: mergeMessages(latest.messages, [await _decode(tombstone)]),
      ),
    );
  }

  // ── Reporting ────────────────────────────────────────────────────────────

  /// Reports somebody else's encrypted message to the channel's moderators.
  /// This reveals its text to the server: that is the point of a report, and
  /// the UI asks first. The author's attestation goes with it, so the server
  /// can check the text is what their device really wrote.
  Future<void> report(ChatMessage message, {String? reason}) async {
    final session = _session;
    if (session == null || !message.reportable) return;
    await session.textMessagesApi.report(
      session.token,
      messageId: message.id,
      body: message.content ?? '',
      clientMessageId: message.clientMessageId!,
      clientSentAt: message.clientSentAt!,
      type: MessagePayload.textType,
      attestation: message.attestation!,
      reason: reason,
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Encrypts [optimistic] in the channel's group and posts the ciphertext.
  /// A message refused as stale (the group moved on while it was being
  /// encrypted) is encrypted again once, in the group's new epoch.
  Future<ChannelMessage> _sendEncrypted(
    ServerSession session,
    ChannelGroups groups,
    ChatMessage optimistic,
  ) async {
    // Attested, so a recipient can prove to moderators who wrote it.
    final unsigned = MessagePayload.text(
      optimistic.content ?? '',
      clientMessageId: optimistic.id,
    );
    final payload = unsigned
        .withAttestation(
          await groups.engine.signMessageAttestation(
            unsigned.attestationBytes(arg.channelId),
          ),
        )
        .encode();

    for (var attempt = 0; ; attempt++) {
      final ciphertext = await groups.encrypt(arg.channelId, payload);
      try {
        final stored = await session.textMessagesApi.sendEncrypted(
          session.token,
          channelId: arg.channelId,
          message: ciphertext,
        );
        await groups.rememberSent(
          channelId: arg.channelId,
          messageId: stored.messageId,
          sentAt: stored.sentAtUtc,
          ciphertext: ciphertext,
        );
        return stored;
      } on ApiException catch (e) {
        groups.abandon(ciphertext);
        if (e.code != 'stale_epoch' || attempt > 0) rethrow;
        await groups.catchUp(arg.channelId);
      }
    }
  }

  Future<List<ChatMessage>> _decodeAll(List<ChannelMessage> messages) async => [
    for (final m in messages) await _decode(m),
  ];

  /// A message as the chat shows it: plaintext as it came, an encrypted one
  /// decrypted (or a placeholder when this device cannot), a tombstone as a
  /// tombstone.
  Future<ChatMessage> _decode(ChannelMessage m) async {
    if (!m.encrypted) {
      return ChatMessage(
        id: m.messageId,
        authorId: m.authorId,
        content: m.content,
        sentAt: m.sentAtUtc,
        deleted: m.deleted,
        security: MessageSecurity.plaintext,
      );
    }

    final ciphertext = m.ciphertext;
    final groups = _groups;
    MessagePayload? payload;
    if (!m.deleted && ciphertext != null && groups != null) {
      final bytes = await groups.decrypt(
        channelId: m.channelId,
        messageId: m.messageId,
        sentAt: m.sentAtUtc,
        ciphertext: ciphertext,
        epoch: m.epoch!,
        senderDeviceId: m.senderDeviceId,
      );
      payload = bytes == null ? null : MessagePayload.tryDecode(bytes);
    }

    final readable = payload?.type == MessagePayload.textType;
    return ChatMessage(
      id: m.messageId,
      authorId: m.authorId,
      content: m.deleted ? null : (readable ? payload!.body : null),
      sentAt: m.sentAtUtc,
      deleted: m.deleted,
      security: m.deleted || readable
          ? MessageSecurity.encrypted
          : MessageSecurity.undecryptable,
      senderDeviceId: m.senderDeviceId,
      attestation: readable ? payload!.attestation : null,
      clientMessageId: readable ? payload!.clientMessageId : null,
      clientSentAt: readable ? payload!.sentAt : null,
    );
  }

  static List<ChatMessage> _replacePending(
    List<ChatMessage> pending,
    ChatMessage replacement,
  ) => [
    for (final m in pending)
      if (m.id == replacement.id) replacement else m,
  ];
}
