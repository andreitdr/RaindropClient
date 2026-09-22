import 'dart:convert';
import 'dart:typed_data';

import 'package:msgpack_dart/msgpack_dart.dart' as msgpack;

/// What goes *inside* an end-to-end encrypted message: MessagePack, so it is
/// compact and a newer client can add fields an older one ignores.
///
/// `{v: 1, t: type, b: body, c: clientMessageId, s: sentAt (ms), x: ext,
/// a: attestation}`
///
/// [attestation] is the sending device's Ed25519 signature over
/// [attestationBytes]. Recipients do not need it (MLS already tells them who
/// sent the message); it is what lets one of them *prove* it to moderators,
/// who cannot decrypt anything, when reporting the message.
///
/// [type] is an open string (`text` today) so a plugin or a later build can
/// send other kinds of content in the same channel; a client shows what it
/// understands and a placeholder for the rest. MLS pads the ciphertext to a
/// multiple of 256 bytes, so the size of this says little about the text.
class MessagePayload {
  const MessagePayload({
    required this.type,
    required this.body,
    required this.clientMessageId,
    required this.sentAt,
    this.ext = const {},
    this.attestation,
  });

  static const version = 1;

  /// The [type] of a plain text message.
  static const textType = 'text';

  final String type;
  final String body;

  /// Chosen by the sender before encrypting, so its own copy can be matched
  /// up with the server's echo.
  final String clientMessageId;

  /// The sender's clock; informational. The server's `sentAtUtc` orders the
  /// timeline.
  final DateTime sentAt;

  final Map<String, Object?> ext;

  /// The sender's device signature over [attestationBytes], or null from a
  /// client that does not attest.
  final Uint8List? attestation;

  /// What an attestation signs, byte for byte as the server recomputes it
  /// (`MessageReportService`): the channel id (lower case), the client
  /// message id, the send time in ms, the type and the body — each text field
  /// as a 4-byte big-endian length and its UTF-8. The device adds its own
  /// context string before signing.
  Uint8List attestationBytes(String channelId) {
    final out = BytesBuilder();
    void field(String value) {
      final bytes = utf8.encode(value);
      out.add((ByteData(4)..setUint32(0, bytes.length)).buffer.asUint8List());
      out.add(bytes);
    }

    field(channelId.toLowerCase());
    field(clientMessageId);
    out.add(
      (ByteData(
        8,
      )..setInt64(0, sentAt.millisecondsSinceEpoch)).buffer.asUint8List(),
    );
    field(type);
    field(body);
    return out.toBytes();
  }

  MessagePayload withAttestation(Uint8List signature) => MessagePayload(
    type: type,
    body: body,
    clientMessageId: clientMessageId,
    sentAt: sentAt,
    ext: ext,
    attestation: signature,
  );

  factory MessagePayload.text(String body, {required String clientMessageId}) =>
      MessagePayload(
        type: textType,
        body: body,
        clientMessageId: clientMessageId,
        sentAt: DateTime.now().toUtc(),
      );

  Uint8List encode() => msgpack.serialize({
    'v': version,
    't': type,
    'b': body,
    'c': clientMessageId,
    's': sentAt.millisecondsSinceEpoch,
    'x': ext,
    'a': ?attestation,
  });

  /// Decodes a payload, or returns null for bytes that are not one — a newer
  /// version, or garbage — which the chat shows as a placeholder.
  static MessagePayload? tryDecode(Uint8List bytes) {
    try {
      final map = msgpack.deserialize(bytes);
      if (map is! Map || map['v'] != version) return null;
      final type = map['t'];
      final body = map['b'];
      final clientMessageId = map['c'];
      final sentAt = map['s'];
      if (type is! String ||
          body is! String ||
          clientMessageId is! String ||
          sentAt is! int) {
        return null;
      }
      final ext = map['x'];
      return MessagePayload(
        type: type,
        body: body,
        clientMessageId: clientMessageId,
        sentAt: DateTime.fromMillisecondsSinceEpoch(sentAt, isUtc: true),
        ext: ext is Map
            ? {for (final e in ext.entries) '${e.key}': e.value}
            : const {},
        attestation: switch (map['a']) {
          final Uint8List a => a,
          final List<int> a => Uint8List.fromList(a),
          _ => null,
        },
      );
    } on Object {
      return null;
    }
  }
}
