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
import 'attachment_transfers.dart';

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
    // An encrypted message names the local id it was sent under; a plaintext
    // one can only be matched on its text.
    final echo =
        pending.where((m) => m.id == message.clientMessageId).firstOrNull ??
        pending
            .where(
              (m) =>
                  m.status == MessageStatus.sending &&
                  m.attachments.isEmpty &&
                  m.content == message.content,
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
  ///
  /// [files] go with it, encrypted and uploaded first; each shows its upload
  /// progress in the pending message. Files need end-to-end encryption, since
  /// their keys travel inside the message: without it they are refused.
  Future<void> send(
    String content, {
    List<ChatAttachment> files = const [],
  }) async {
    final session = _session;
    final current = state.valueOrNull;
    if (session == null || current == null) return;

    final text = content.trim();
    if (text.isEmpty && files.isEmpty) return;
    if (files.isNotEmpty && _groups == null) {
      throw const AttachmentRefused(
        'Files are end-to-end encrypted, and this device cannot encrypt here yet.',
      );
    }

    final optimistic = ChatMessage(
      id: 'local-${_uuid.v4()}',
      authorId: session.currentUser.userId,
      content: text,
      sentAt: DateTime.now().toUtc(),
      status: MessageStatus.sending,
      attachments: files,
      payloadType: files.isEmpty
          ? MessagePayload.textType
          : MessagePayload.filesType,
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

  /// Drops a failed message. The message itself was never sent; files that
  /// were already uploaded for it are thrown away on the server too.
  void discard(String localId) {
    final current = state.valueOrNull;
    if (current == null) return;
    final message = current.pending.where((m) => m.id == localId).firstOrNull;
    final uploaded = [
      for (final a in message?.attachments ?? const <ChatAttachment>[])
        if (a.descriptor case final d?) ...[
          d.attachmentId,
          if (d.thumbnail case final t?) t.attachmentId,
        ],
    ];
    if (uploaded.isNotEmpty) {
      unawaited(
        ref.read(attachmentTransfersProvider(arg.serverId)).cancel(uploaded),
      );
    }
    state = AsyncData(
      current.copyWith(
        pending: current.pending.where((m) => m.id != localId).toList(),
      ),
    );
  }

  Future<void> _deliver(ChatMessage optimistic) async {
    final session = _session!;
    var sending = optimistic;
    try {
      final groups = _groups;
      if (optimistic.attachments.isNotEmpty) {
        sending = await _uploadAll(optimistic);
        final transfers = ref.read(attachmentTransfersProvider(arg.serverId));
        for (final file in sending.attachments) {
          if ((file.descriptor, file.localPath) case (final d?, final path?)) {
            transfers.rememberSent(d.attachmentId, path);
          }
        }
      }
      final stored = groups == null
          ? await session.textMessagesApi.send(
              session.token,
              channelId: arg.channelId,
              content: optimistic.content ?? '',
            )
          : await _sendEncrypted(session, groups, sending);
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
      // What was uploaded stays with the message, so a retry sends it
      // without uploading it again.
      final current =
          latest.pending.where((m) => m.id == optimistic.id).firstOrNull ??
          sending;
      state = AsyncData(
        latest.copyWith(
          pending: _replacePending(
            latest.pending,
            current.copyWith(status: MessageStatus.failed),
          ),
        ),
      );
      rethrow;
    }
  }

  /// Encrypts and uploads every file of [message] that is not up yet, showing
  /// each one's progress on the pending message, and returns the message with
  /// every file's descriptor in place.
  Future<ChatMessage> _uploadAll(ChatMessage message) async {
    final transfers = ref.read(attachmentTransfersProvider(arg.serverId));
    var current = message;

    void show(ChatMessage updated) {
      current = updated;
      final latest = state.valueOrNull;
      if (_disposed || latest == null) return;
      state = AsyncData(
        latest.copyWith(pending: _replacePending(latest.pending, updated)),
      );
    }

    for (var i = 0; i < current.attachments.length; i++) {
      if (current.attachments[i].descriptor != null) continue;
      var lastShown = -1.0;
      final descriptor = await transfers.upload(
        channelId: arg.channelId,
        file: current.attachments[i],
        onProgress: (progress) {
          // A redraw per percent, not per packet.
          if (progress - lastShown < 0.01 && progress < 1) return;
          lastShown = progress;
          show(
            current.copyWith(
              attachments: [
                for (var j = 0; j < current.attachments.length; j++)
                  j == i
                      ? current.attachments[j].copyWith(progress: progress)
                      : current.attachments[j],
              ],
            ),
          );
        },
      );
      show(
        current.copyWith(
          attachments: [
            for (var j = 0; j < current.attachments.length; j++)
              j == i
                  ? current.attachments[j].copyWith(
                      descriptor: descriptor,
                      progress: 1,
                    )
                  : current.attachments[j],
          ],
        ),
      );
    }
    return current;
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
    final withFiles = message.payloadType == MessagePayload.filesType;
    await session.textMessagesApi.report(
      session.token,
      messageId: message.id,
      body: message.content ?? '',
      clientMessageId: message.clientMessageId!,
      clientSentAt: message.clientSentAt!,
      type: message.payloadType ?? MessagePayload.textType,
      attestation: message.attestation!,
      reason: reason,
      // The v2 attestation covers the files too, so they go with it.
      attachments: withFiles ? _payloadOf(message).attestedFiles : null,
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
    // Attested, so a recipient can prove to moderators who wrote it — under
    // the v2 context when there are files, which covers them too.
    final unsigned = _payloadOf(optimistic);
    final canonical = unsigned.attestationBytes(arg.channelId);
    final payload = unsigned
        .withAttestation(
          unsigned.attestsFiles
              ? await groups.engine.signMessageAttestationV2(canonical)
              : await groups.engine.signMessageAttestation(canonical),
        )
        .encode();
    final attachmentIds = [
      for (final file in unsigned.attestedFiles) file.attachmentId,
    ];

    for (var attempt = 0; ; attempt++) {
      final ciphertext = await groups.encrypt(arg.channelId, payload);
      try {
        final stored = await session.textMessagesApi.sendEncrypted(
          session.token,
          channelId: arg.channelId,
          message: ciphertext,
          attachmentIds: attachmentIds,
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

  /// The payload [message] is sent as: its text alone, or its caption and its
  /// uploaded files. Built again the same way for a report, so the attested
  /// bytes match.
  MessagePayload _payloadOf(ChatMessage message) {
    final files = [for (final a in message.attachments) ?a.descriptor];
    return files.isEmpty
        ? MessagePayload.text(
            message.content ?? '',
            clientMessageId: message.id,
          )
        : MessagePayload.files(
            message.content ?? '',
            files,
            clientMessageId: message.id,
          );
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

    // Decrypted but of a kind this build cannot show: say so, rather than
    // calling it unreadable.
    final understood =
        payload != null &&
        (payload.type == MessagePayload.textType ||
            payload.type == MessagePayload.filesType);
    final readable = understood && !m.deleted;
    return ChatMessage(
      id: m.messageId,
      authorId: m.authorId,
      content: readable ? payload.body : null,
      sentAt: m.sentAtUtc,
      deleted: m.deleted,
      security: m.deleted || payload != null
          ? MessageSecurity.encrypted
          : MessageSecurity.undecryptable,
      unsupported: payload != null && !understood && !m.deleted,
      senderDeviceId: m.senderDeviceId,
      attestation: readable ? payload.attestation : null,
      clientMessageId: payload?.clientMessageId,
      clientSentAt: readable ? payload.sentAt : null,
      payloadType: readable ? payload.type : null,
      attachments: readable ? _attachmentsOf(payload, m.attachments) : const [],
    );
  }

  /// The files a decrypted message describes, each paired with what the
  /// server stored for it. One the server does not list for this message is
  /// kept, marked unavailable, rather than fetched: the payload may only name
  /// files the message really carries.
  static List<ChatAttachment> _attachmentsOf(
    MessagePayload payload,
    List<MessageAttachmentRef> stored,
  ) {
    final byId = {
      for (final ref in stored) ref.attachmentId.toLowerCase(): ref,
    };
    return [
      for (final file in payload.files)
        ChatAttachment(
          name: file.name,
          size: file.size,
          mimeType: file.mimeType,
          descriptor: file,
          serverRef: byId[file.attachmentId.toLowerCase()],
        ),
    ];
  }

  static List<ChatMessage> _replacePending(
    List<ChatMessage> pending,
    ChatMessage replacement,
  ) => [
    for (final m in pending)
      if (m.id == replacement.id) replacement else m,
  ];
}
