import 'dart:convert';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:msgpack_dart/msgpack_dart.dart' as msgpack;

import '../network/grpc/protocol.dart' as pb;

/// What goes *inside* an end-to-end encrypted message — the plaintext of an
/// MLS application message, which only the channel's members ever see.
///
/// Version 2, what this build writes, is the byte `0x02` followed by a
/// protobuf `raindrop.v1.MessagePayload` (RaindropProto's `payload.proto`), so
/// a newer client can add fields an older one skips. Version 1 was MessagePack
/// — `{v: 1, t: type, b: body, c: clientMessageId, s: sentAt (ms), x: {f:
/// files}, a: attestation}` — whose first byte is always a map marker, never
/// `0x02`; it is still read, so history from before the switch decrypts as it
/// did.
///
/// [attestation] is the sending device's Ed25519 signature over
/// [attestationBytes]. Recipients do not need it (MLS already tells them who
/// sent the message); it is what lets one of them *prove* it to moderators,
/// who cannot decrypt anything, when reporting the message.
///
/// [type] is an open string (`text`, `files`) so a plugin or a later build can
/// send other kinds of content in the same channel; a client shows what it
/// understands and a placeholder for the rest. MLS pads the ciphertext to a
/// multiple of 256 bytes, so the size of this says little about the text.
///
/// A `files` message carries its caption in [body] and its files in [files]:
/// each one's attachment id on the server, its own key, name, MIME type, size
/// and ciphertext hash — see [AttachmentDescriptor]. Its attestation is the v2
/// one ([attestsFiles]), which also covers the files. (The attestation's
/// versions are its own, and have nothing to do with the encoding's.)
class MessagePayload {
  const MessagePayload({
    required this.type,
    required this.body,
    required this.clientMessageId,
    required this.sentAt,
    this.files = const [],
    this.attestation,
  });

  /// The version byte this build writes in front of the protobuf message.
  static const version = 2;

  /// The [type] of a plain text message.
  static const textType = 'text';

  /// The [type] of a message that carries files, with an optional caption.
  static const filesType = 'files';

  final String type;
  final String body;

  /// Chosen by the sender before encrypting, so its own copy can be matched
  /// up with the server's echo.
  final String clientMessageId;

  /// The sender's clock; informational. The server's `sentAtUtc` orders the
  /// timeline.
  final DateTime sentAt;

  /// The files a `files` message carries, in the order they are shown; empty
  /// for any other message, and for descriptors this build cannot read.
  final List<AttachmentDescriptor> files;

  /// Whether the attestation is the v2 one, which also signs [files].
  bool get attestsFiles => type == filesType && files.isNotEmpty;

  /// The sender's device signature over [attestationBytes], or null from a
  /// client that does not attest.
  final Uint8List? attestation;

  /// What an attestation signs, byte for byte as the server recomputes it
  /// (`MessageReportService`): the channel id (lower case), the client
  /// message id, the send time in ms, the type and the body — each text field
  /// as a 4-byte big-endian length and its UTF-8. The device adds its own
  /// context string before signing.
  ///
  /// When the message carries files ([attestsFiles]) the v2 layout follows:
  /// a 4-byte big-endian count, then for each file in [attestedFiles] order
  /// its id (lower case, as a field like the others) and the 32 bytes of its
  /// ciphertext's SHA-256. Signed with `signMessageAttestationV2`.
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
    if (attestsFiles) {
      final attested = attestedFiles;
      out.add(
        (ByteData(4)..setUint32(0, attested.length)).buffer.asUint8List(),
      );
      for (final file in attested) {
        field(file.attachmentId.toLowerCase());
        out.add(file.ciphertextSha256);
      }
    }
    return out.toBytes();
  }

  /// Every attachment a `files` message names, in the order its attestation
  /// covers them: each file, followed by its thumbnail when it has one.
  List<({String attachmentId, Uint8List ciphertextSha256})> get attestedFiles =>
      [
        for (final file in files) ...[
          (
            attachmentId: file.attachmentId,
            ciphertextSha256: file.ciphertextSha256,
          ),
          if (file.thumbnail case final thumbnail?)
            (
              attachmentId: thumbnail.attachmentId,
              ciphertextSha256: thumbnail.ciphertextSha256,
            ),
        ],
      ];

  MessagePayload withAttestation(Uint8List signature) => MessagePayload(
    type: type,
    body: body,
    clientMessageId: clientMessageId,
    sentAt: sentAt,
    files: files,
    attestation: signature,
  );

  factory MessagePayload.text(String body, {required String clientMessageId}) =>
      MessagePayload(
        type: textType,
        body: body,
        clientMessageId: clientMessageId,
        sentAt: DateTime.now().toUtc(),
      );

  /// A message carrying [files], with [caption] (possibly empty) as its text.
  factory MessagePayload.files(
    String caption,
    List<AttachmentDescriptor> files, {
    required String clientMessageId,
  }) => MessagePayload(
    type: filesType,
    body: caption,
    clientMessageId: clientMessageId,
    sentAt: DateTime.now().toUtc(),
    files: files,
  );

  /// The bytes to encrypt: [version], then the protobuf message.
  Uint8List encode() {
    final message = pb.MessagePayload(
      type: type,
      body: body,
      clientMessageId: clientMessageId,
      sentAtUnixMs: Int64(sentAt.millisecondsSinceEpoch),
      attestation: attestation,
      files: [for (final file in files) file.toProto()],
    );
    return Uint8List.fromList([version, ...message.writeToBuffer()]);
  }

  /// Decodes a payload, or returns null for bytes that are not one — a newer
  /// version, or garbage — which the chat shows as a placeholder.
  static MessagePayload? tryDecode(Uint8List bytes) {
    if (bytes.isEmpty) return null;
    return bytes[0] == version ? _decodeV2(bytes) : _decodeV1(bytes);
  }

  static MessagePayload? _decodeV2(Uint8List bytes) {
    final pb.MessagePayload message;
    try {
      message = pb.MessagePayload.fromBuffer(Uint8List.sublistView(bytes, 1));
    } on Object {
      return null;
    }
    return MessagePayload(
      type: message.type,
      body: message.body,
      clientMessageId: message.clientMessageId,
      sentAt: DateTime.fromMillisecondsSinceEpoch(
        message.sentAtUnixMs.toInt(),
        isUtc: true,
      ),
      files: [
        for (final file in message.files)
          ?AttachmentDescriptor.tryFromProto(file),
      ],
      attestation: message.hasAttestation()
          ? Uint8List.fromList(message.attestation)
          : null,
    );
  }

  /// Version 1, MessagePack: read so older history still decrypts, never
  /// written.
  static MessagePayload? _decodeV1(Uint8List bytes) {
    try {
      final map = msgpack.deserialize(bytes);
      if (map is! Map || map['v'] != 1) return null;
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
      final files = ext is Map ? ext['f'] : null;
      return MessagePayload(
        type: type,
        body: body,
        clientMessageId: clientMessageId,
        sentAt: DateTime.fromMillisecondsSinceEpoch(sentAt, isUtc: true),
        files: [
          if (files is List)
            for (final item in files)
              if (item is Map) ?AttachmentDescriptor.tryDecode(item),
        ],
        attestation: _bytes(map['a']),
      );
    } on Object {
      return null;
    }
  }
}

/// One encrypted file as a `files` message describes it — everything a
/// recipient needs to fetch it and open it, none of which the server sees
/// except [attachmentId]:
///
/// `{i: attachment id, k: key, n: name, m: MIME type, s: size in bytes,
/// h: ciphertext SHA-256, t?: thumbnail, pw?/ph?: pixel size, d?: duration ms}`
///
/// The name is the sender's file name, never trusted as a path: only its last
/// component is ever used, and only to name a file the member chose to save.
class AttachmentDescriptor {
  const AttachmentDescriptor({
    required this.attachmentId,
    required this.key,
    required this.name,
    required this.mimeType,
    required this.size,
    required this.ciphertextSha256,
    this.thumbnail,
    this.width,
    this.height,
    this.duration,
  });

  final String attachmentId;

  /// The file's own `raindrop/attachment/v1` key.
  final Uint8List key;
  final String name;
  final String mimeType;

  /// The plaintext size.
  final int size;

  /// What the downloaded ciphertext must hash to before it is opened.
  final Uint8List ciphertextSha256;

  /// A small preview image the sender made, uploaded as its own attachment.
  final ThumbnailDescriptor? thumbnail;

  /// For an image or video, its size in pixels, so the timeline can reserve
  /// the space before it has loaded.
  final int? width;
  final int? height;

  /// For audio or video, how long it plays.
  final Duration? duration;

  pb.AttachmentDescriptor toProto() => pb.AttachmentDescriptor(
    attachmentId: attachmentId,
    key: key,
    name: name,
    mimeType: mimeType,
    size: Int64(size),
    ciphertextSha256: ciphertextSha256,
    thumbnail: thumbnail?.toProto(),
    width: width,
    height: height,
    durationMs: duration == null ? null : Int64(duration!.inMilliseconds),
  );

  /// Reads one descriptor, or returns null for one this build cannot use —
  /// a key or hash of the wrong length is never guessed at.
  static AttachmentDescriptor? tryFromProto(pb.AttachmentDescriptor m) {
    if (m.key.length != 32 || m.ciphertextSha256.length != 32) return null;
    return AttachmentDescriptor(
      attachmentId: m.attachmentId,
      key: Uint8List.fromList(m.key),
      name: m.name,
      mimeType: m.mimeType,
      size: m.size.toInt(),
      ciphertextSha256: Uint8List.fromList(m.ciphertextSha256),
      thumbnail: m.hasThumbnail()
          ? ThumbnailDescriptor.tryFromProto(m.thumbnail)
          : null,
      width: m.hasWidth() ? m.width : null,
      height: m.hasHeight() ? m.height : null,
      duration: m.hasDurationMs()
          ? Duration(milliseconds: m.durationMs.toInt())
          : null,
    );
  }

  /// Decodes one version 1 (MessagePack) descriptor, or returns null for one
  /// this build cannot read.
  static AttachmentDescriptor? tryDecode(Map<Object?, Object?> map) {
    final id = map['i'];
    final key = _bytes(map['k']);
    final name = map['n'];
    final mime = map['m'];
    final size = map['s'];
    final hash = _bytes(map['h']);
    if (id is! String ||
        key == null ||
        key.length != 32 ||
        name is! String ||
        mime is! String ||
        size is! int ||
        hash == null ||
        hash.length != 32) {
      return null;
    }
    final thumbnail = map['t'];
    final duration = map['d'];
    return AttachmentDescriptor(
      attachmentId: id,
      key: key,
      name: name,
      mimeType: mime,
      size: size,
      ciphertextSha256: hash,
      thumbnail: thumbnail is Map
          ? ThumbnailDescriptor.tryDecode(thumbnail)
          : null,
      width: map['pw'] is int ? map['pw'] as int : null,
      height: map['ph'] is int ? map['ph'] as int : null,
      duration: duration is int ? Duration(milliseconds: duration) : null,
    );
  }
}

/// A sender-made preview image of a file: `{i, k, h}` as in
/// [AttachmentDescriptor], always a JPEG.
class ThumbnailDescriptor {
  const ThumbnailDescriptor({
    required this.attachmentId,
    required this.key,
    required this.ciphertextSha256,
  });

  final String attachmentId;
  final Uint8List key;
  final Uint8List ciphertextSha256;

  pb.ThumbnailDescriptor toProto() => pb.ThumbnailDescriptor(
    attachmentId: attachmentId,
    key: key,
    ciphertextSha256: ciphertextSha256,
  );

  static ThumbnailDescriptor? tryFromProto(pb.ThumbnailDescriptor m) {
    if (m.key.length != 32 || m.ciphertextSha256.length != 32) return null;
    return ThumbnailDescriptor(
      attachmentId: m.attachmentId,
      key: Uint8List.fromList(m.key),
      ciphertextSha256: Uint8List.fromList(m.ciphertextSha256),
    );
  }

  /// Decodes a version 1 (MessagePack) thumbnail.
  static ThumbnailDescriptor? tryDecode(Map<Object?, Object?> map) {
    final id = map['i'];
    final key = _bytes(map['k']);
    final hash = _bytes(map['h']);
    if (id is! String ||
        key == null ||
        key.length != 32 ||
        hash == null ||
        hash.length != 32) {
      return null;
    }
    return ThumbnailDescriptor(
      attachmentId: id,
      key: key,
      ciphertextSha256: hash,
    );
  }
}

Uint8List? _bytes(Object? value) => switch (value) {
  final Uint8List bytes => bytes,
  final List<int> bytes => Uint8List.fromList(bytes),
  _ => null,
};
