/// The app's view of `raindrop.v1.AttachmentService` (RaindropProto's
/// `attachments.proto`): streaming encrypted files up and back down.
/// Everything here moves ciphertext — encrypting and decrypting is
/// `AttachmentCipher`'s job, and the key never comes near the server.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';

import 'api_exception.dart';
import 'grpc/protocol.dart' as pb;
import 'grpc/wire.dart';
import 'raindrop_channel.dart';

/// Advertised by `ServerService.GetServerInfo` while the server accepts files.
const attachmentsCapability = 'attachments.v1';

/// What the server accepts, so a file can be refused before any of it is
/// encrypted or uploaded. The server checks everything again regardless.
class AttachmentPolicy {
  const AttachmentPolicy({
    required this.enabled,
    required this.maximumFileBytes,
    this.maximumFileBytesByExtension = const {},
    this.allowedExtensions,
    this.blockedExtensions = const [],
    this.allowFilesWithoutExtension = true,
    this.maximumFilesPerMessage = 10,
    this.maximumThumbnailBytes = 512 * 1024,
    this.previewExtensions = const [],
    this.previewAutoLoadMaximumBytes = 0,
    this.uploadFrameBytes = defaultFrameBytes,
  });

  /// What a server that does not say uses: 256 KiB per stream frame.
  static const defaultFrameBytes = 256 * 1024;

  final bool enabled;
  final int maximumFileBytes;
  final Map<String, int> maximumFileBytesByExtension;

  /// The only extensions accepted, or null for any that is not blocked.
  final List<String>? allowedExtensions;
  final List<String> blockedExtensions;
  final bool allowFilesWithoutExtension;
  final int maximumFilesPerMessage;
  final int maximumThumbnailBytes;

  /// Which types the server's owner wants shown inline. The client shows only
  /// those it also knows how to render.
  final List<String> previewExtensions;

  /// The largest previewable file loaded without the member asking.
  final int previewAutoLoadMaximumBytes;

  /// The most bytes one frame of an upload stream may carry.
  final int uploadFrameBytes;

  factory AttachmentPolicy.fromProto(pb.AttachmentPolicy m) => AttachmentPolicy(
    enabled: m.enabled,
    maximumFileBytes: m.maximumFileBytes.toInt(),
    maximumFileBytesByExtension: {
      for (final e in m.maximumFileBytesByExtension.entries)
        e.key: e.value.toInt(),
    },
    allowedExtensions: m.hasAllowedExtensions()
        ? List.unmodifiable(m.allowedExtensions.extensions)
        : null,
    blockedExtensions: List.unmodifiable(m.blockedExtensions),
    allowFilesWithoutExtension: m.allowFilesWithoutExtension,
    maximumFilesPerMessage: m.maximumFilesPerMessage,
    maximumThumbnailBytes: m.maximumThumbnailBytes.toInt(),
    previewExtensions: List.unmodifiable(m.previewExtensions),
    previewAutoLoadMaximumBytes: m.previewAutoLoadMaximumBytes.toInt(),
    uploadFrameBytes: m.uploadFrameBytes > 0
        ? m.uploadFrameBytes
        : defaultFrameBytes,
  );

  /// The largest file accepted with [extension] (lower case, no dot).
  int maximumBytesFor(String extension) =>
      maximumFileBytesByExtension[extension] ?? maximumFileBytes;

  /// Why a file called [name] of [size] bytes would be refused, in words for
  /// the member, or null when the server would take it. The same rules the
  /// server's `ConfiguredAttachmentPolicy` applies.
  String? refusalFor(String name, int size) {
    if (!enabled) return 'This server does not accept files.';
    final extension = extensionOf(name);
    if (extension.isEmpty) {
      if (!allowFilesWithoutExtension) {
        return 'This server does not accept files without an extension.';
      }
    } else if (blockedExtensions.contains(extension) ||
        (allowedExtensions != null &&
            !allowedExtensions!.contains(extension))) {
      return '.$extension files aren\'t allowed on this server.';
    }
    final limit = maximumBytesFor(extension);
    if (size > limit) {
      return '$name is larger than the ${formatBytes(limit)} this server '
          'accepts${extension.isEmpty ? '' : ' for .$extension files'}.';
    }
    return null;
  }

  /// Whether the owner wants files with [extension] shown inline.
  bool previews(String extension) => previewExtensions.contains(extension);
}

/// The extension of a file name as the server compares them: the part after
/// the last dot, lower case; empty for none. A name that is all extension
/// (`.bashrc`) has none, as on every desktop.
String extensionOf(String name) {
  final base = name.split(RegExp(r'[/\\]')).last;
  final dot = base.lastIndexOf('.');
  if (dot <= 0 || dot == base.length - 1) return '';
  final extension = base.substring(dot + 1).toLowerCase();
  return RegExp(r'^[a-z0-9]{1,16}$').hasMatch(extension) ? extension : '';
}

/// A size for people: `512 KB`, `25 MB`, `1.4 GB`. Megabytes are 1,048,576
/// bytes, as the server's configuration counts them.
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  const units = ['KB', 'MB', 'GB', 'TB'];
  var value = bytes / 1024;
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final digits = value >= 10 || value == value.roundToDouble() ? 0 : 1;
  return '${value.toStringAsFixed(digits)} ${units[unit]}';
}

/// Where an upload stands on the server.
class UploadStatus {
  const UploadStatus({
    required this.attachmentId,
    required this.state,
    required this.ciphertextSize,
    required this.receivedSize,
    this.frameBytes = AttachmentPolicy.defaultFrameBytes,
  });

  final String attachmentId;

  /// `uploading`, `uploaded` or `attached`.
  final String state;
  final int ciphertextSize;

  /// Where the next upload stream starts.
  final int receivedSize;

  /// The most bytes one frame of an upload stream may carry.
  final int frameBytes;

  bool get complete => state != 'uploading';

  factory UploadStatus.fromProto(pb.UploadStatus m) => UploadStatus(
    attachmentId: m.attachmentId,
    state: Wire.uploadState(m.state),
    ciphertextSize: m.ciphertextSize.toInt(),
    receivedSize: m.receivedSize.toInt(),
    frameBytes: m.frameBytes > 0
        ? m.frameBytes
        : AttachmentPolicy.defaultFrameBytes,
  );
}

/// `raindrop.v1.AttachmentService`. One per connected server.
class AttachmentsApi {
  AttachmentsApi(this._channel)
    : _attachments = pb.AttachmentServiceClient(_channel.channel);

  final RaindropChannel _channel;
  final pb.AttachmentServiceClient _attachments;

  Future<AttachmentPolicy> policy(String token) async =>
      AttachmentPolicy.fromProto(
        (await _channel.call(
          (o) => _attachments.getAttachmentPolicy(
            pb.GetAttachmentPolicyRequest(),
            options: o,
          ),
          token: token,
        )).policy,
      );

  /// Starts an upload of an encrypted file for [channelId]. Only [extension]
  /// and the ciphertext's size tell the server anything about the file.
  Future<UploadStatus> create(
    String token, {
    required String channelId,
    required String extension,
    required int ciphertextSize,
    String kind = 'file',
  }) async => UploadStatus.fromProto(
    (await _channel.call(
      (o) => _attachments.createUpload(
        pb.CreateUploadRequest(
          channelId: channelId,
          extension_2: extension,
          ciphertextSize: Int64(ciphertextSize),
          kind: Wire.attachmentKindOf(kind),
        ),
        options: o,
      ),
      token: token,
    )).status,
  );

  /// Streams [data] — the ciphertext from [offset] on — into the upload, in
  /// frames of at most [frameBytes]. The server refuses a stream that does
  /// not start where it has got to (`upload_offset_mismatch`). A stream that
  /// breaks keeps what the server committed: ask [status] where it stands
  /// and stream again from there.
  ///
  /// [onProgress] is told how many bytes of this stream have been handed to
  /// the connection.
  Future<UploadStatus> upload(
    String token, {
    required String attachmentId,
    required int offset,
    required Stream<List<int>> data,
    int frameBytes = AttachmentPolicy.defaultFrameBytes,
    void Function(int sent)? onProgress,
  }) async {
    Stream<pb.UploadRequest> frames() async* {
      yield pb.UploadRequest(
        header: pb.UploadHeader(
          attachmentId: attachmentId,
          offset: Int64(offset),
        ),
      );
      var sent = 0;
      await for (final chunk in data) {
        for (var at = 0; at < chunk.length; at += frameBytes) {
          final end = at + frameBytes < chunk.length
              ? at + frameBytes
              : chunk.length;
          yield pb.UploadRequest(data: chunk.sublist(at, end));
          sent += end - at;
          onProgress?.call(sent);
        }
      }
    }

    return UploadStatus.fromProto(
      (await _channel.call(
        (o) => _attachments.upload(frames(), options: o),
        token: token,
        // A large file takes as long as it takes; the stream is the deadline.
        timeout: null,
      )).status,
    );
  }

  /// Uploads [bytes] whole — a thumbnail, small enough to send in one go.
  Future<UploadStatus> uploadBytes(
    String token, {
    required String attachmentId,
    required Uint8List bytes,
    int frameBytes = AttachmentPolicy.defaultFrameBytes,
  }) => upload(
    token,
    attachmentId: attachmentId,
    offset: 0,
    data: Stream.value(bytes),
    frameBytes: frameBytes,
  );

  Future<UploadStatus> status(
    String token, {
    required String attachmentId,
  }) async => UploadStatus.fromProto(
    (await _channel.call(
      (o) => _attachments.getUploadStatus(
        pb.GetUploadStatusRequest(attachmentId: attachmentId),
        options: o,
      ),
      token: token,
    )).status,
  );

  /// Finishes an upload; the server checks what it stored against
  /// [ciphertextSha256] (`hash_mismatch` throws the upload away).
  Future<UploadStatus> complete(
    String token, {
    required String attachmentId,
    required Uint8List ciphertextSha256,
  }) async => UploadStatus.fromProto(
    (await _channel.call(
      (o) => _attachments.completeUpload(
        pb.CompleteUploadRequest(
          attachmentId: attachmentId,
          ciphertextSha256: ciphertextSha256,
        ),
        options: o,
      ),
      token: token,
    )).status,
  );

  Future<void> cancel(String token, {required String attachmentId}) =>
      _channel.call(
        (o) => _attachments.cancelUpload(
          pb.CancelUploadRequest(attachmentId: attachmentId),
          options: o,
        ),
        token: token,
      );

  /// Downloads an attachment's ciphertext into [savePath]. With [fromByte],
  /// asks for the rest of the file only and appends it, to resume a download.
  /// A failure throws [ApiException]; on a resumed download, what was already
  /// in [savePath] stays.
  Future<void> download(
    String token, {
    required String attachmentId,
    required String savePath,
    int fromByte = 0,
    void Function(int received, int total)? onProgress,
  }) async {
    final call = _attachments.download(
      pb.DownloadRequest(attachmentId: attachmentId, offset: Int64(fromByte)),
      options: _channel.options(token: token, timeout: null),
    );

    IOSink? sink;
    var total = -1;
    var received = 0;
    try {
      await for (final frame in _channel.stream(call)) {
        if (frame.hasHeader()) {
          total = frame.header.ciphertextSize.toInt() - fromByte;
          // Opened only once the server has said yes, so a refusal leaves the
          // file exactly as it was.
          sink = File(savePath)
              .openWrite(mode: fromByte > 0 ? FileMode.append : FileMode.write);
          continue;
        }
        final out = sink;
        if (out == null) {
          throw ApiException.network(
            'the download sent data before its header',
          );
        }
        out.add(frame.data);
        received += frame.data.length;
        onProgress?.call(received, total);
      }
    } finally {
      await sink?.close();
    }
  }
}
