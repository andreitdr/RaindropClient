/// Dart mirrors of `RaindropServer/Attachments/AttachmentContracts.cs` and the
/// wrapper over `/api/attachments/*`: uploading encrypted files in chunks and
/// downloading them again. Everything here moves ciphertext — encrypting and
/// decrypting is `AttachmentCipher`'s job, and the key never comes near the
/// server.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'api_client.dart';

/// Advertised by `GET /api/server/info` while the server accepts files.
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
    this.uploadChunkBytes = 8 * 1024 * 1024,
  });

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
  final int uploadChunkBytes;

  factory AttachmentPolicy.fromJson(Map<String, dynamic> j) => AttachmentPolicy(
    enabled: j['enabled'] as bool? ?? false,
    maximumFileBytes: (j['maximumFileBytes'] as num?)?.toInt() ?? 0,
    maximumFileBytesByExtension: {
      for (final e
          in (j['maximumFileBytesByExtension'] as Map? ?? const {}).entries)
        '${e.key}': (e.value as num).toInt(),
    },
    allowedExtensions: (j['allowedExtensions'] as List?)?.cast<String>(),
    blockedExtensions: List<String>.from(
      j['blockedExtensions'] as List? ?? const [],
    ),
    allowFilesWithoutExtension:
        j['allowFilesWithoutExtension'] as bool? ?? true,
    maximumFilesPerMessage:
        (j['maximumFilesPerMessage'] as num?)?.toInt() ?? 10,
    maximumThumbnailBytes:
        (j['maximumThumbnailBytes'] as num?)?.toInt() ?? 512 * 1024,
    previewExtensions: List<String>.from(
      j['previewExtensions'] as List? ?? const [],
    ),
    previewAutoLoadMaximumBytes:
        (j['previewAutoLoadMaximumBytes'] as num?)?.toInt() ?? 0,
    uploadChunkBytes:
        (j['uploadChunkBytes'] as num?)?.toInt() ?? 8 * 1024 * 1024,
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
    required this.chunkSize,
  });

  final String attachmentId;

  /// `uploading`, `uploaded` or `attached`.
  final String state;
  final int ciphertextSize;

  /// Where the next chunk starts.
  final int receivedSize;
  final int chunkSize;

  bool get complete => state != 'uploading';

  factory UploadStatus.fromJson(Map<String, dynamic> j) => UploadStatus(
    attachmentId: j['attachmentId'] as String,
    state: j['state'] as String,
    ciphertextSize: (j['ciphertextSize'] as num).toInt(),
    receivedSize: (j['receivedSize'] as num).toInt(),
    chunkSize: (j['chunkSize'] as num).toInt(),
  );
}

/// Typed wrapper over `/api/attachments/*`. One per connected server.
class AttachmentsApi {
  AttachmentsApi(this._client);

  final ApiClient _client;

  Future<AttachmentPolicy> policy(String token) async =>
      AttachmentPolicy.fromJson(
        await _client.get('/api/attachments/policy', token: token),
      );

  /// Starts an upload of an encrypted file for [channelId]. Only [extension]
  /// and the ciphertext's size tell the server anything about the file.
  Future<UploadStatus> create(
    String token, {
    required String channelId,
    required String extension,
    required int ciphertextSize,
    String kind = 'file',
  }) async => UploadStatus.fromJson(
    await _client.post(
      '/api/attachments/uploads/create',
      body: {
        'channelId': channelId,
        'extension': extension,
        'ciphertextSize': ciphertextSize,
        'kind': kind,
      },
      token: token,
    ),
  );

  /// Sends the chunk starting at [offset]; the server refuses one that does
  /// not start where it has got to (`upload_offset_mismatch`).
  Future<UploadStatus> chunk(
    String token, {
    required String attachmentId,
    required int offset,
    required Uint8List bytes,
    void Function(int sent, int total)? onProgress,
  }) async => UploadStatus.fromJson(
    await _client.putBytes(
      '/api/attachments/uploads/chunk',
      bytes,
      headers: {
        'Raindrop-Attachment-Id': attachmentId,
        'Raindrop-Upload-Offset': '$offset',
      },
      token: token,
      onProgress: onProgress,
    ),
  );

  Future<UploadStatus> status(
    String token, {
    required String attachmentId,
  }) async => UploadStatus.fromJson(
    await _client.post(
      '/api/attachments/uploads/status',
      body: {'attachmentId': attachmentId},
      token: token,
    ),
  );

  /// Finishes an upload; the server checks what it stored against
  /// [ciphertextSha256] (`hash_mismatch` throws the upload away).
  Future<UploadStatus> complete(
    String token, {
    required String attachmentId,
    required Uint8List ciphertextSha256,
  }) async => UploadStatus.fromJson(
    await _client.post(
      '/api/attachments/uploads/complete',
      body: {
        'attachmentId': attachmentId,
        'ciphertextSha256': base64.encode(ciphertextSha256),
      },
      token: token,
    ),
  );

  Future<void> cancel(String token, {required String attachmentId}) =>
      _client.post(
        '/api/attachments/uploads/cancel',
        body: {'attachmentId': attachmentId},
        token: token,
      );

  /// Downloads an attachment's ciphertext into [savePath], resuming from
  /// [fromByte] when part of it is already there.
  Future<void> download(
    String token, {
    required String attachmentId,
    required String savePath,
    int fromByte = 0,
    void Function(int received, int total)? onProgress,
  }) => _client.downloadTo(
    '/api/attachments/download',
    savePath,
    body: {'attachmentId': attachmentId},
    token: token,
    fromByte: fromByte,
    onProgress: onProgress,
  );
}
