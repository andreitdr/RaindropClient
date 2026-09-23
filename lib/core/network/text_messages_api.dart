/// Dart mirrors of the C# records in `RaindropServer/Channels/Text/
/// TextChannelContracts.cs` — everything that is only true of *text*
/// channels, kept apart from `channels_api.dart` the same way the server
/// keeps `Channels/Text/` apart from `Channels/`.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'api_client.dart';

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

  factory MessageAttachmentRef.fromJson(Map<String, dynamic> j) =>
      MessageAttachmentRef(
        attachmentId: j['attachmentId'] as String,
        kind: j['kind'] as String? ?? 'file',
        extension: j['extension'] as String? ?? '',
        ciphertextSize: (j['ciphertextSize'] as num?)?.toInt() ?? 0,
        ciphertextSha256: j['ciphertextSha256'] is String
            ? base64.decode(j['ciphertextSha256'] as String)
            : null,
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
/// something to show with `POST /api/users/lookup` (`UsersApi.lookup`).
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

  factory ChannelMessage.fromJson(Map<String, dynamic> j) => ChannelMessage(
    messageId: j['messageId'] as String,
    channelId: j['channelId'] as String,
    authorId: j['authorId'] as String,
    content: j['content'] as String?,
    sentAtUtc: DateTime.parse(j['sentAtUtc'] as String),
    deleted: j['deleted'] as bool? ?? false,
    deletedAtUtc: j['deletedAtUtc'] == null
        ? null
        : DateTime.parse(j['deletedAtUtc'] as String),
    deletedBy: j['deletedBy'] as String?,
    ciphertext: j['ciphertext'] is String
        ? base64.decode(j['ciphertext'] as String)
        : null,
    epoch: (j['epoch'] as num?)?.toInt(),
    senderDeviceId: j['senderDeviceId'] as String?,
    attachments: [
      for (final a in j['attachments'] as List? ?? const [])
        MessageAttachmentRef.fromJson(Map<String, dynamic>.from(a as Map)),
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

  factory MessageReport.fromJson(Map<String, dynamic> j) => MessageReport(
    reportId: j['reportId'] as String,
    messageId: j['messageId'] as String,
    authorId: j['authorId'] as String,
    reporterId: j['reporterId'] as String,
    body: j['body'] as String,
    reason: j['reason'] as String?,
    reportedAtUtc: DateTime.parse(j['reportedAtUtc'] as String),
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

  factory MessageHistoryPage.fromJson(Map<String, dynamic> j) =>
      MessageHistoryPage(
        channelId: j['channelId'] as String,
        messages: [
          for (final m in j['messages'] as List? ?? const [])
            ChannelMessage.fromJson(Map<String, dynamic>.from(m as Map)),
        ],
        nextCursor: j['nextCursor'] as String?,
      );
}

/// Typed wrapper over `/api/channels/text/messages/*`. One instance per
/// connected server, built from that server's [ApiClient].
class TextMessagesApi {
  TextMessagesApi(this._client);

  final ApiClient _client;

  /// Posts a message and returns it as the server stored it, so the caller
  /// can swap its optimistic copy for the real id and timestamp.
  Future<ChannelMessage> send(
    String token, {
    required String channelId,
    required String content,
  }) async => ChannelMessage.fromJson(
    await _client.post(
      '/api/channels/text/messages/send',
      body: {'channelId': channelId, 'content': content},
      token: token,
    ),
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
  }) async => ChannelMessage.fromJson(
    await _client.post(
      '/api/channels/text/messages/send-encrypted',
      body: {
        'channelId': channelId,
        'message': base64.encode(message),
        if (attachmentIds.isNotEmpty) 'attachmentIds': attachmentIds,
      },
      token: token,
    ),
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
  }) => _client.post(
    '/api/channels/text/messages/report',
    body: {
      'messageId': messageId,
      'body': body,
      'clientMessageId': clientMessageId,
      'clientSentAtUnixMs': clientSentAt.millisecondsSinceEpoch,
      'type': type,
      'attestation': base64.encode(attestation),
      'reason': reason,
      // Present only for a message that carries files, whose attestation is
      // the v2 one that also covers them.
      'attachments': ?(attachments == null
          ? null
          : [
              for (final a in attachments)
                {
                  'attachmentId': a.attachmentId,
                  'ciphertextSha256': base64.encode(a.ciphertextSha256),
                },
            ]),
    },
    token: token,
  );

  /// A channel's reported messages, newest first. Needs `manage_messages` in
  /// the channel.
  Future<List<MessageReport>> reports(
    String token, {
    required String channelId,
  }) async {
    final body = await _client.post(
      '/api/channels/text/messages/reports',
      body: {'channelId': channelId},
      token: token,
    );
    return [
      for (final r in body['reports'] as List? ?? const [])
        MessageReport.fromJson(Map<String, dynamic>.from(r as Map)),
    ];
  }

  /// One page of history. [before] is a `nextCursor` from a previous page —
  /// null asks for the newest messages. The cursor is opaque: pass it back
  /// untouched, never parse it.
  Future<MessageHistoryPage> history(
    String token, {
    required String channelId,
    String? before,
    int? limit,
  }) async => MessageHistoryPage.fromJson(
    await _client.post(
      '/api/channels/text/messages/history',
      body: {'channelId': channelId, 'before': before, 'limit': limit},
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
  }) async => ChannelMessage.fromJson(
    await _client.post(
      '/api/channels/text/messages/delete',
      body: {'messageId': messageId},
      token: token,
    ),
  );
}
