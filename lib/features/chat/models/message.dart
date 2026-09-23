import 'dart:typed_data';

import '../../../core/crypto/message_payload.dart';
import '../../../core/network/attachments_api.dart';
import '../../../core/network/text_messages_api.dart';

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

/// A file in a message, outgoing or received.
///
/// Outgoing, it starts as [localPath] with an upload [progress], and gains its
/// [descriptor] once it is encrypted and uploaded — kept on a failed send, so
/// retrying does not upload it again. Received, [descriptor] is what the
/// encrypted message says about it and [serverRef] what the server stored.
class ChatAttachment {
  const ChatAttachment({
    required this.name,
    required this.size,
    required this.mimeType,
    this.descriptor,
    this.serverRef,
    this.localPath,
    this.progress,
  });

  /// The sender's file name — shown, and used to name a file saved from it,
  /// never trusted as a path.
  final String name;
  final int size;
  final String mimeType;
  final AttachmentDescriptor? descriptor;
  final MessageAttachmentRef? serverRef;

  /// Outgoing: the file on this device.
  final String? localPath;

  /// Outgoing: how much has been uploaded, 0 to 1; null before it starts.
  final double? progress;

  String get extension => extensionOf(name);

  bool get outgoing => localPath != null;

  /// A received file the server does not list for this message — named in
  /// the encrypted payload but not attached to it, so nothing to fetch.
  bool get unavailable =>
      !outgoing && (descriptor == null || serverRef == null);

  /// The extension the sender declared to the server is not the one in the
  /// name inside the encrypted message: a client that lied to get past the
  /// server's type rules. Such a file is never previewed.
  bool get extensionMismatch =>
      serverRef != null && serverRef!.extension != extension;

  ChatAttachment copyWith({
    AttachmentDescriptor? descriptor,
    double? progress,
  }) => ChatAttachment(
    name: name,
    size: size,
    mimeType: mimeType,
    descriptor: descriptor ?? this.descriptor,
    serverRef: serverRef,
    localPath: localPath,
    progress: progress ?? this.progress,
  );
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
    this.attachments = const [],
    this.payloadType,
    this.unsupported = false,
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

  /// The files the message carries, in the order the sender listed them.
  /// Thumbnails are not listed here; they belong to the file they preview.
  final List<ChatAttachment> attachments;

  /// The encrypted payload's type (`text`, `files`), which a report signs.
  final String? payloadType;

  /// Decrypted, but a kind of message this build does not know how to show —
  /// sent by a newer client or a plugin.
  final bool unsupported;

  /// Whether the message carries what a report needs.
  bool get reportable =>
      !deleted &&
      security == MessageSecurity.encrypted &&
      attestation != null &&
      senderDeviceId != null;

  ChatMessage copyWith({
    MessageStatus? status,
    List<ChatAttachment>? attachments,
  }) => ChatMessage(
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
    attachments: attachments ?? this.attachments,
    payloadType: payloadType,
    unsupported: unsupported,
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
