import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../core/crypto/attachment_cipher.dart';
import '../../../core/crypto/crypto_engine.dart';
import '../../../core/crypto/message_payload.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/attachments_api.dart';
import '../../../core/storage/attachment_cache.dart';
import '../../servers/controllers/session_controller.dart';
import '../models/message.dart';

/// Encrypts and decrypts attachment files. A provider so a test can stand in
/// for the Rust core.
final attachmentCipherProvider = Provider<AttachmentCipher>(
  (ref) => const RustAttachmentCipher(),
);

/// What the server accepts, or null when it takes no files at all — it does
/// not offer `attachments.v1`, or its owner switched attachments off. Read
/// once per session; the composer hides its attach button while this is null.
final attachmentPolicyProvider =
    FutureProvider.family<AttachmentPolicy?, String>((ref, serverId) async {
      final session = await ref.watch(serverSessionProvider(serverId).future);
      if (session == null) return null;
      final info = await session.usersApi.serverInfo();
      if (!info.capabilities.contains(attachmentsCapability)) return null;
      final policy = await session.attachmentsApi.policy(session.token);
      return policy.enabled ? policy : null;
    });

/// Uploading and opening attachments on one server.
final attachmentTransfersProvider =
    Provider.family<AttachmentTransfers, String>(
      (ref, serverId) => AttachmentTransfers(ref, serverId),
    );

/// A file the server refused before any of it was sent, with the reason in
/// words for the member.
class AttachmentRefused implements Exception {
  const AttachmentRefused(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Moves encrypted files between this device and one server.
///
/// **Up:** encrypt the file into a temporary file under a fresh key, declare
/// its extension and ciphertext size, send it in chunks (carrying on from
/// where the server says it got to after an interruption), and finish it
/// against the ciphertext's hash. For an image or a video, a small JPEG
/// preview goes up beside it as a `thumbnail` attachment, since the server
/// cannot make one from a file it cannot read.
///
/// **Down:** fetch the ciphertext into the attachment cache (resuming a
/// partial one), check it against the hash in the message, and decrypt it into
/// the temporary plaintext folder, which is emptied when the app starts. A file
/// is fetched and decrypted once per run however often it is shown.
class AttachmentTransfers {
  AttachmentTransfers(this._ref, this.serverId);

  final Ref _ref;
  final String serverId;

  final _opened = <String, Future<File>>{};
  final _thumbnails = <String, Future<Uint8List>>{};

  AttachmentCipher get _cipher => _ref.read(attachmentCipherProvider);

  Future<ServerSession> _session() async {
    final session = await _ref.read(serverSessionProvider(serverId).future);
    if (session == null) {
      throw ApiException.network('not signed in to this server');
    }
    return session;
  }

  // ── Up ─────────────────────────────────────────────────────────────────

  /// Encrypts and uploads [file] for [channelId], reporting progress from 0 to
  /// 1, and returns what the message has to say about it.
  ///
  /// Throws [AttachmentRefused] for a file the server's rules refuse, and the
  /// server's [ApiException] for anything it refuses on the way.
  Future<AttachmentDescriptor> upload({
    required String channelId,
    required ChatAttachment file,
    required void Function(double progress) onProgress,
  }) async {
    final session = await _session();
    final policy = await _ref.read(attachmentPolicyProvider(serverId).future);
    if (policy == null) {
      throw const AttachmentRefused('This server does not accept files.');
    }
    final refusal = policy.refusalFor(file.name, file.size);
    if (refusal != null) throw AttachmentRefused(refusal);

    final cache = await AttachmentCache.instance();
    final encrypted = await cache.uploadFile();
    try {
      final sealed = await _cipher.encryptFile(file.localPath!, encrypted.path);
      final attachmentId = await _send(
        session,
        channelId: channelId,
        encrypted: encrypted,
        sealed: sealed,
        extension: file.extension,
        kind: 'file',
        // The thumbnail is the last few percent.
        onProgress: (sent) => onProgress(sent * 0.95),
      );

      final preview = await _previewOf(file);
      ThumbnailDescriptor? thumbnail;
      if (preview != null &&
          preview.jpeg.length <= policy.maximumThumbnailBytes) {
        thumbnail = await _uploadThumbnail(session, channelId, preview.jpeg);
      }
      onProgress(1);

      return AttachmentDescriptor(
        attachmentId: attachmentId,
        key: sealed.key,
        name: file.name,
        mimeType: file.mimeType,
        size: file.size,
        ciphertextSha256: sealed.ciphertextSha256,
        thumbnail: thumbnail,
        width: preview?.width,
        height: preview?.height,
        duration: preview?.duration,
      );
    } finally {
      if (await encrypted.exists()) await encrypted.delete();
    }
  }

  /// Throws away uploads that will not be sent after all — best effort, since
  /// the server expires them anyway.
  Future<void> cancel(Iterable<String> attachmentIds) async {
    final session = await _session();
    for (final id in attachmentIds) {
      try {
        await session.attachmentsApi.cancel(session.token, attachmentId: id);
      } on ApiException {
        // Already gone, or the server is unreachable: it expires on its own.
      }
    }
  }

  Future<String> _send(
    ServerSession session, {
    required String channelId,
    required File encrypted,
    required SealedFile sealed,
    required String extension,
    required String kind,
    required void Function(double sent) onProgress,
  }) async {
    final api = session.attachmentsApi;
    final status = await api.create(
      session.token,
      channelId: channelId,
      extension: extension,
      ciphertextSize: sealed.ciphertextLength,
      kind: kind,
    );
    final id = status.attachmentId;
    final total = sealed.ciphertextLength;

    // One stream from wherever the server has got to. A stream that breaks
    // keeps what the server committed, so each retry asks where that is and
    // streams the rest of the file from there.
    var offset = status.receivedSize;
    var failures = 0;
    while (offset < total) {
      final from = offset;
      try {
        final after = await api.upload(
          session.token,
          attachmentId: id,
          offset: from,
          data: encrypted.openRead(from, total),
          frameBytes: status.frameBytes,
          onProgress: (sent) => onProgress((from + sent) / total),
        );
        offset = after.receivedSize;
        failures = 0;
      } on ApiException catch (e) {
        // A dropped connection, or bytes the server already had: ask where it
        // got to and carry on from there, a few times before giving up.
        final retriable =
            e.code == 'network_error' || e.code == 'upload_offset_mismatch';
        if (!retriable || ++failures > 3) rethrow;
        await Future<void>.delayed(Duration(seconds: failures));
        offset = (await api.status(
          session.token,
          attachmentId: id,
        )).receivedSize;
      }
    }

    await api.complete(
      session.token,
      attachmentId: id,
      ciphertextSha256: sealed.ciphertextSha256,
    );
    return id;
  }

  Future<ThumbnailDescriptor?> _uploadThumbnail(
    ServerSession session,
    String channelId,
    Uint8List jpeg,
  ) async {
    try {
      final sealed = await _cipher.encryptBytes(jpeg);
      final api = session.attachmentsApi;
      final status = await api.create(
        session.token,
        channelId: channelId,
        extension: 'jpg',
        ciphertextSize: sealed.sealed.ciphertextLength,
        kind: 'thumbnail',
      );
      await api.uploadBytes(
        session.token,
        attachmentId: status.attachmentId,
        bytes: sealed.ciphertext,
        frameBytes: status.frameBytes,
      );
      await api.complete(
        session.token,
        attachmentId: status.attachmentId,
        ciphertextSha256: sealed.sealed.ciphertextSha256,
      );
      return ThumbnailDescriptor(
        attachmentId: status.attachmentId,
        key: sealed.sealed.key,
        ciphertextSha256: sealed.sealed.ciphertextSha256,
      );
    } on Object catch (e) {
      // A file without a preview is still a file.
      debugPrint('attachments: thumbnail not sent: $e');
      return null;
    }
  }

  // ── Down ───────────────────────────────────────────────────────────────

  /// Remembers that an attachment this device just sent is the file at
  /// [path], so showing the sent message does not download it again.
  void rememberSent(String attachmentId, String path) =>
      _opened.putIfAbsent(attachmentId, () => Future.value(File(path)));

  /// The decrypted file behind [attachment], fetching it if this run has not
  /// yet. An outgoing file is simply the one on this device.
  Future<File> open(
    ChatAttachment attachment, {
    void Function(double)? onProgress,
  }) {
    if (attachment.localPath case final path?) return Future.value(File(path));
    final descriptor = attachment.descriptor;
    final ref = attachment.serverRef;
    if (descriptor == null || ref == null) {
      return Future.error(
        const AttachmentRefused('This file is not available.'),
      );
    }
    return _opened.putIfAbsent(descriptor.attachmentId, () async {
      try {
        final ciphertext = await _fetch(
          descriptor.attachmentId,
          ref.ciphertextSize,
          onProgress,
        );
        final cache = await AttachmentCache.instance();
        final out = await cache.plaintextFile(descriptor.name);
        try {
          await _cipher.decryptFile(
            ciphertext.path,
            out.path,
            key: descriptor.key,
            expectedSha256: descriptor.ciphertextSha256,
          );
        } on CryptoException {
          // Not the file the message names: throw the copy away so the next
          // attempt fetches it afresh rather than failing the same way.
          if (await ciphertext.exists()) await ciphertext.delete();
          rethrow;
        }
        return out;
      } catch (_) {
        unawaited(_opened.remove(descriptor.attachmentId));
        rethrow;
      }
    });
  }

  /// The decrypted preview image of a file.
  Future<Uint8List> thumbnail(ThumbnailDescriptor thumbnail) =>
      _thumbnails.putIfAbsent(thumbnail.attachmentId, () async {
        try {
          final ciphertext = await _fetch(thumbnail.attachmentId, null, null);
          return await _cipher.decryptBytes(
            await ciphertext.readAsBytes(),
            key: thumbnail.key,
            expectedSha256: thumbnail.ciphertextSha256,
          );
        } catch (_) {
          unawaited(_thumbnails.remove(thumbnail.attachmentId));
          rethrow;
        }
      });

  /// Downloads an attachment's ciphertext into the cache, carrying on from a
  /// partial copy when [size] says there is more to come.
  Future<File> _fetch(
    String attachmentId,
    int? size,
    void Function(double)? onProgress,
  ) async {
    final session = await _session();
    final cache = await AttachmentCache.instance();
    final file = await cache.ciphertextFile(serverId, attachmentId);

    var have = await file.exists() ? await file.length() : 0;
    if (size != null && have > size) {
      await file.delete();
      have = 0;
    }
    if (size == null || have < size) {
      await session.attachmentsApi.download(
        session.token,
        attachmentId: attachmentId,
        savePath: file.path,
        fromByte: size == null ? 0 : have,
        onProgress: size == null || onProgress == null
            ? null
            : (received, _) => onProgress((have + received) / size),
      );
    }
    unawaited(cache.touchAndTrim(file));
    return file;
  }

  // ── Previews the sender makes ──────────────────────────────────────────

  Future<_Preview?> _previewOf(ChatAttachment file) async {
    final kind = previewKindOf(file.extension);
    try {
      return switch (kind) {
        PreviewKind.image when file.size <= 64 * 1024 * 1024 =>
          await Isolate.run(() => _imagePreview(file.localPath!)),
        PreviewKind.video => await _videoPreview(file.localPath!),
        _ => null,
      };
    } on Object catch (e) {
      debugPrint('attachments: no preview for ${file.name}: $e');
      return null;
    }
  }

  /// A still from a few seconds into a video, grabbed by the media player
  /// without showing it anywhere.
  static Future<_Preview?> _videoPreview(String path) async {
    final player = Player();
    try {
      final controller = VideoController(player);
      await player.open(Media(Uri.file(path).toString()), play: false);
      await controller.waitUntilFirstFrameRendered.timeout(
        const Duration(seconds: 5),
      );
      final duration = player.state.duration;
      if (duration > const Duration(seconds: 4)) {
        await player.seek(const Duration(seconds: 2));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
      final frame = await player.screenshot(format: 'image/jpeg');
      if (frame == null) return null;
      final shrunk = await Isolate.run(() => _shrink(frame));
      return shrunk == null
          ? null
          : _Preview(
              shrunk.jpeg,
              width: player.state.width ?? shrunk.width,
              height: player.state.height ?? shrunk.height,
              duration: duration > Duration.zero ? duration : null,
            );
    } finally {
      await player.dispose();
    }
  }
}

/// A preview image made on the sender's side.
class _Preview {
  const _Preview(this.jpeg, {this.width, this.height, this.duration});

  final Uint8List jpeg;
  final int? width;
  final int? height;
  final Duration? duration;
}

/// Thumbnails fit in a 320-pixel square: sharp enough for the timeline, small
/// enough to fetch with the message.
const _thumbnailEdge = 320;

_Preview? _imagePreview(String path) {
  final shrunk = _shrink(File(path).readAsBytesSync());
  return shrunk == null
      ? null
      : _Preview(shrunk.jpeg, width: shrunk.width, height: shrunk.height);
}

({Uint8List jpeg, int width, int height})? _shrink(Uint8List encoded) {
  final image = img.decodeImage(encoded);
  if (image == null) return null;
  final small = image.width >= image.height
      ? img.copyResize(image, width: min(_thumbnailEdge, image.width))
      : img.copyResize(image, height: min(_thumbnailEdge, image.height));
  return (
    jpeg: img.encodeJpg(small, quality: 75),
    width: image.width,
    height: image.height,
  );
}

/// How the chat can show a file inline, by extension — what it knows how to
/// render, before the server's `preview.extensions` is consulted.
enum PreviewKind { image, video, audio, none }

PreviewKind previewKindOf(String extension) => switch (extension) {
  'png' || 'jpg' || 'jpeg' || 'gif' || 'webp' || 'bmp' => PreviewKind.image,
  'mp4' || 'webm' || 'mov' || 'mkv' || 'm4v' => PreviewKind.video,
  'mp3' ||
  'm4a' ||
  'ogg' ||
  'oga' ||
  'wav' ||
  'flac' ||
  'opus' ||
  'aac' => PreviewKind.audio,
  _ => PreviewKind.none,
};

int min(int a, int b) => a < b ? a : b;
