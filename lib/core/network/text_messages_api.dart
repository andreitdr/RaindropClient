/// The app's view of `raindrop.v1.TextChannelService` (RaindropProto's
/// `text.proto`) — everything that is only true of *text* channels, kept apart
/// from `channels_api.dart` the same way the server keeps `Channels/Text/`
/// apart from `Channels/`.
library;

import 'dart:typed_data';

import 'grpc/protocol.dart' as pb;
import 'grpc/wire.dart';
import 'raindrop_channel.dart';

/// An encrypted file a message carries, as far as the server can describe it.
/// Its name, type and key are inside the message's ciphertext.
class MessageAttachmentRef {
  const MessageAttachmentRef({
    required this.attachmentId,
    required this.kind,
    required this.extension,
    required this.ciphertextSize,
    this.ciphertextSha256,
  });

  final String attachmentId;

  /// `file`, or `thumbnail` for a preview of another file in the message.
  final String kind;

  /// The extension the sender declared to the server. Compared with the name
  /// inside the encrypted message before anything is previewed.
  final String extension;
  final int ciphertextSize;
  final Uint8List? ciphertextSha256;

  factory MessageAttachmentRef.fromProto(pb.MessageAttachment m) =>
      MessageAttachmentRef(
        attachmentId: m.attachmentId,
        kind: Wire.attachmentKind(m.kind),
        extension: m.extension_3,
        ciphertextSize: m.ciphertextSize.toInt(),
        ciphertextSha256: Wire.optionalBytes(
          m.hasCiphertextSha256(),
          m.ciphertextSha256,
        ),
      );
}

/// A message as the server stored it.
///
/// A deleted message still arrives, with [content] null and [deleted] set:
/// the row survives so the message keeps its place in the conversation and
/// its link to the author's UUID. Render it as "message deleted" rather than
/// dropping it, or paging drifts.
///
/// [authorId] is a UUID, never a username — an account can be renamed or
/// erased and the message still points at the same person. Turn it into
/// something to show with `UserService.LookupUser` (`UsersApi.lookup`).
class ChannelMessage {
  const ChannelMessage({
    required this.messageId,
    required this.channelId,
    required this.authorId,
    required this.content,
    required this.sentAtUtc,
    required this.deleted,
    this.deletedAtUtc,
    this.deletedBy,
    this.ciphertext,
    this.epoch,
    this.senderDeviceId,
    this.attachments = const [],
  });

  final String messageId;
  final String channelId;
  final String authorId;
  final String? content;
  final DateTime sentAtUtc;
  final bool deleted;
  final DateTime? deletedAtUtc;
  final String? deletedBy;

  /// For an end-to-end encrypted message: the MLS ciphertext, which only the
  /// channel group's members can decrypt. [content] is null for these. Null
  /// again once the message is deleted.
  final Uint8List? ciphertext;

  /// The MLS epoch an encrypted message was sent in; null for plaintext.
  final int? epoch;

  /// Which of the author's devices sent an encrypted message.
  final String? senderDeviceId;

  /// The encrypted files the message carries; empty for none, and once it is
  /// deleted.
  final List<MessageAttachmentRef> attachments;

  /// Whether the message was end-to-end encrypted (deleted or not).
  bool get encrypted => epoch != null;

  factory ChannelMessage.fromProto(pb.ChannelMessage m) => ChannelMessage(
    messageId: m.messageId,
    channelId: m.channelId,
    authorId: m.authorId,
    content: m.hasContent() ? m.content : null,
    sentAtUtc: Wire.time(m.sentAt),
    deleted: m.deleted,
    deletedAtUtc: Wire.optionalTime(m.hasDeletedAt(), m.deletedAt),
    deletedBy: m.hasDeletedBy() ? m.deletedBy : null,
    ciphertext: Wire.optionalBytes(m.hasCiphertext(), m.ciphertext),
    epoch: m.hasEpoch() ? m.epoch.toInt() : null,
    senderDeviceId: m.hasSenderDeviceId() ? m.senderDeviceId : null,
    attachments: [
      for (final a in m.attachments) MessageAttachmentRef.fromProto(a),
    ],
  );
}

/// A reported message, for moderators. [body] was revealed by the reporter
/// and verified by the server against the author's device attestation.
class MessageReport {
  const MessageReport({
    required this.reportId,
    required this.messageId,
    required this.authorId,
    required this.reporterId,
    required this.body,
    required this.reason,
    required this.reportedAtUtc,
  });

  final String reportId;
  final String messageId;
  final String authorId;
  final String reporterId;
  final String body;
  final String? reason;
  final DateTime reportedAtUtc;

  factory MessageReport.fromProto(pb.MessageReport m) => MessageReport(
    reportId: m.reportId,
    messageId: m.messageId,
    authorId: m.authorId,
    reporterId: m.reporterId,
    body: m.body,
    reason: m.hasReason() ? m.reason : null,
    reportedAtUtc: Wire.time(m.reportedAt),
  );
}

/// One page of a channel's history.
///
/// [messages] is in chronological order, oldest first, the way it is
/// rendered. Paging runs the other way: the first request returns the
/// *newest* page, and [nextCursor] leads further into the past until it
/// comes back null at the beginning of the channel.
class MessageHistoryPage {
  const MessageHistoryPage({
    required this.channelId,
    required this.messages,
    this.nextCursor,
  });

  final String channelId;
  final List<ChannelMessage> messages;
  final String? nextCursor;

  bool get hasMore => nextCursor != null;

  factory MessageHistoryPage.fromProto(pb.GetHistoryResponse m) =>
      MessageHistoryPage(
        channelId: m.channelId,
        messages: [
          for (final message in m.messages) ChannelMessage.fromProto(message),
        ],
        nextCursor: m.hasNextCursor() ? m.nextCursor : null,
      );
}

/// `raindrop.v1.TextChannelService`. One instance per connected server, built
/// on that server's [RaindropChannel].
class TextMessagesApi {
  TextMessagesApi(this._channel)
    : _text = pb.TextChannelServiceClient(_channel.channel);

  final RaindropChannel _channel;
  final pb.TextChannelServiceClient _text;

  /// Posts a message and returns it as the server stored it, so the caller
  /// can swap its optimistic copy for the real id and timestamp.
  Future<ChannelMessage> send(
    String token, {
    required String channelId,
    required String content,
  }) async => ChannelMessage.fromProto(
    (await _channel.call(
      (o) => _text.sendMessage(
        pb.SendMessageRequest(channelId: channelId, content: content),
        options: o,
      ),
      token: token,
    )).message,
  );

  /// Posts an end-to-end encrypted message — the MLS ciphertext this
  /// device's group produced — and returns it as the server stored it. Throws
  /// `stale_epoch` when the group has moved on: catch up and encrypt again.
  ///
  /// [attachmentIds] are finished uploads (`AttachmentsApi.complete`) the
  /// message carries, in the order its payload lists them.
  Future<ChannelMessage> sendEncrypted(
    String token, {
    required String channelId,
    required Uint8List message,
    List<String> attachmentIds = const [],
  }) async => ChannelMessage.fromProto(
    (await _channel.call(
      (o) => _text.sendEncryptedMessage(
        pb.SendEncryptedMessageRequest(
          channelId: channelId,
          message: message,
          attachmentIds: attachmentIds,
        ),
        options: o,
      ),
      token: token,
    )).message,
  );

  /// Reports an end-to-end encrypted message to the channel's moderators,
  /// revealing its text. [attestation] is the author's device signature from
  /// the message's payload over the other fields, which the server checks
  /// against that device's key — `invalid_attestation` if it does not match.
  Future<void> report(
    String token, {
    required String messageId,
    required String body,
    required String clientMessageId,
    required DateTime clientSentAt,
    required String type,
    required Uint8List attestation,
    String? reason,
    List<({String attachmentId, Uint8List ciphertextSha256})>? attachments,
  }) => _channel.call(
    (o) => _text.reportMessage(
      pb.ReportMessageRequest(
        messageId: messageId,
        body: body,
        clientMessageId: clientMessageId,
        clientSentAtUnixMs: Wire.int64(clientSentAt.millisecondsSinceEpoch),
        type: type,
        attestation: attestation,
        reason: reason,
        // Present only for a message that carries files, whose attestation is
        // the v2 one that also covers them — its presence is what says so.
        attestedFiles: attachments == null
            ? null
            : pb.AttestedFiles(
                attachments: [
                  for (final a in attachments)
                    pb.AttestedAttachment(
                      attachmentId: a.attachmentId,
                      ciphertextSha256: a.ciphertextSha256,
                    ),
                ],
              ),
      ),
      options: o,
    ),
    token: token,
  );

  /// A channel's reported messages, newest first. Needs `manage_messages` in
  /// the channel.
  Future<List<MessageReport>> reports(
    String token, {
    required String channelId,
  }) async {
    final response = await _channel.call(
      (o) => _text.listReports(
        pb.ListReportsRequest(channelId: channelId),
        options: o,
      ),
      token: token,
    );
    return [for (final r in response.reports) MessageReport.fromProto(r)];
  }

  /// One page of history. [before] is a `nextCursor` from a previous page —
  /// null asks for the newest messages. The cursor is opaque: pass it back
  /// untouched, never parse it.
  Future<MessageHistoryPage> history(
    String token, {
    required String channelId,
    String? before,
    int? limit,
  }) async => MessageHistoryPage.fromProto(
    await _channel.call(
      (o) => _text.getHistory(
        pb.GetHistoryRequest(
          channelId: channelId,
          before: before,
          limit: limit,
        ),
        options: o,
      ),
      token: token,
    ),
  );

  /// Deletes a message and returns the tombstone the server now holds in its
  /// place, the same record `message.deleted` carries. The author may always
  /// delete their own; anybody else's needs `manage_messages` in the channel.
  /// Deleting one that is already deleted is not an error.
  Future<ChannelMessage> delete(
    String token, {
    required String messageId,
  }) async => ChannelMessage.fromProto(
    (await _channel.call(
      (o) => _text.deleteMessage(
        pb.DeleteMessageRequest(messageId: messageId),
        options: o,
      ),
      token: token,
    )).message,
  );
}
