import 'dart:typed_data';

/// Where a message is between the composer and the server.
enum MessageStatus {
  /// The server has it; [ChatMessage.id] is the real message id.
  sent,

  /// Shown optimistically while `POST .../messages/send` is in flight.
  sending,

  /// The send failed. The message stays in the timeline so its text isn't
  /// lost, and can be retried or discarded.
  failed,
}

/// How a message was protected, which the chat pane shows.
enum MessageSecurity {
  /// End-to-end encrypted and decrypted on this device.
  encrypted,

  /// End-to-end encrypted, but this device cannot read it: it was sent before
  /// this device joined the channel's group (history is forward-only), or it
  /// is from a newer client.
  undecryptable,

  /// Posted before the server required end-to-end encryption. The server
  /// could read it.
  plaintext,
}

/// One message as the chat pane renders it.
///
/// [authorId] is a UUID rather than a name, exactly as the server sends it —
/// an account can be renamed or erased and the message still points at the
/// same person, so the name is resolved separately and never stored here.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.authorId,
    required this.content,
    required this.sentAt,
    this.deleted = false,
    this.status = MessageStatus.sent,
    this.security = MessageSecurity.encrypted,
    this.senderDeviceId,
    this.attestation,
    this.clientMessageId,
    this.clientSentAt,
  });

  final String id;
  final String authorId;

  /// Null once the message has been deleted — the row survives as a
  /// tombstone that keeps its place in the conversation.
  final String? content;

  /// UTC, as the server stores it. Convert with `.toLocal()` to display.
  final DateTime sentAt;

  final bool deleted;
  final MessageStatus status;
  final MessageSecurity security;

  /// What reporting an encrypted message needs to prove who sent it: the
  /// sending device, its attestation, and the fields it signed. Null for a
  /// message that cannot be reported (plaintext, undecryptable, or from a
  /// client that does not attest).
  final String? senderDeviceId;
  final Uint8List? attestation;
  final String? clientMessageId;
  final DateTime? clientSentAt;

  /// Whether the message carries what a report needs.
  bool get reportable =>
      !deleted &&
      security == MessageSecurity.encrypted &&
      attestation != null &&
      senderDeviceId != null;

  ChatMessage copyWith({MessageStatus? status}) => ChatMessage(
    id: id,
    authorId: authorId,
    content: content,
    sentAt: sentAt,
    deleted: deleted,
    status: status ?? this.status,
    security: security,
    senderDeviceId: senderDeviceId,
    attestation: attestation,
    clientMessageId: clientMessageId,
    clientSentAt: clientSentAt,
  );
}

/// Whether the account [currentUserId] may delete [message] — which decides
/// whether the chat pane offers the option at all.
///
/// Two independent rules, mirroring `TextChannelService.DeleteAsync` on the
/// server:
///
/// * **Your own message is always deletable.** No permission is involved, so
///   [canManageMessages] is never consulted for it — a member whose roles
///   grant nothing at all can still take back what they said.
/// * **Somebody else's** needs `manage_messages` in the channel, which is
///   what [canManageMessages] reports.
///
/// A message that is already a tombstone, or that has not reached the server
/// yet (still sending, or failed — those are discarded, not deleted), has
/// nothing to delete. The server checks all of this again regardless.
bool canDeleteMessage(
  ChatMessage message, {
  required String? currentUserId,
  required bool canManageMessages,
}) {
  if (message.deleted || message.status != MessageStatus.sent) return false;
  if (currentUserId != null && message.authorId == currentUserId) return true;
  return canManageMessages;
}

/// Folds messages just read (or just received) into the ones already held: an
/// id that is already known is replaced — which is how a deletion shows up —
/// and the result is sorted by the same `(sentAt, messageId)` pair the server
/// pages by, so the order here always matches the order there.
///
/// The one exception to "replaced" is a tombstone: a message never becomes
/// readable again, so a copy that is not deleted never overwrites one that is.
/// Without that, a re-read that started before a delete and finished after it
/// would bring the text back on screen — a message the server has already
/// destroyed.
///
/// A re-read only ever reads the newest page, so a burst of more than a page
/// of messages while the stream was down could leave a hole in the middle of
/// the timeline. Scrolling back re-reads across it.
List<ChatMessage> mergeMessages(
  List<ChatMessage> existing,
  Iterable<ChatMessage> incoming,
) {
  final byId = {for (final m in existing) m.id: m};
  for (final m in incoming) {
    if ((byId[m.id]?.deleted ?? false) && !m.deleted) continue;
    byId[m.id] = m;
  }
  return byId.values.toList()..sort((a, b) {
    final byTime = a.sentAt.compareTo(b.sentAt);
    return byTime != 0 ? byTime : a.id.compareTo(b.id);
  });
}
