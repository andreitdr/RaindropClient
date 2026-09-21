/// Dart mirrors of the C# records in `RaindropServer/Channels/Text/
/// TextChannelContracts.cs` — everything that is only true of *text*
/// channels, kept apart from `channels_api.dart` the same way the server
/// keeps `Channels/Text/` apart from `Channels/`.
library;

import 'api_client.dart';

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
  });

  final String messageId;
  final String channelId;
  final String authorId;
  final String? content;
  final DateTime sentAtUtc;
  final bool deleted;
  final DateTime? deletedAtUtc;
  final String? deletedBy;

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
