import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';

/// Where attachment files live on this device, and the rules that keep
/// plaintext off the disk for longer than it is needed.
///
/// * **Ciphertext** (`<cache>/raindrop-attachments/<server>/<id>`) is kept, so
///   opening a file twice downloads it once. It is useless without the key,
///   which lives only in the encrypted message cache. Capped at
///   [ciphertextBudgetBytes], least recently used first out.
/// * **Plaintext** is decrypted into one folder under the system's temporary
///   directory (`raindrop-open`), only when the member opens a file, and that
///   folder is emptied when the app starts and when it goes away — a decrypted
///   file never outlives the session that needed it. A file the member saves
///   goes where they chose, which is theirs to keep.
/// * **Uploads** are encrypted into `raindrop-upload` and deleted as soon as
///   they have been sent.
class AttachmentCache {
  AttachmentCache._(this._ciphertextRoot, this._openRoot, this._uploadRoot);

  /// How much ciphertext is kept for opening files again.
  static const ciphertextBudgetBytes = 512 * 1024 * 1024;

  final Directory _ciphertextRoot;
  final Directory _openRoot;
  final Directory _uploadRoot;

  static AttachmentCache? _instance;

  /// The cache, with the plaintext and upload folders emptied the first time
  /// it is asked for in a run — which `main` does at startup.
  static Future<AttachmentCache> instance() async {
    if (_instance case final cache?) return cache;
    final cacheDir = await getApplicationCacheDirectory();
    final tempDir = await getTemporaryDirectory();
    final cache = AttachmentCache._(
      Directory('${cacheDir.path}/raindrop-attachments'),
      Directory('${tempDir.path}/raindrop-open'),
      Directory('${tempDir.path}/raindrop-upload'),
    );
    await cache.clearPlaintext();
    return _instance = cache;
  }

  /// Deletes every decrypted file and leftover upload. Safe to call any time
  /// nothing is being opened or sent.
  Future<void> clearPlaintext() async {
    for (final dir in [_openRoot, _uploadRoot]) {
      try {
        if (await dir.exists()) await dir.delete(recursive: true);
      } on FileSystemException {
        // A file still open elsewhere; the next start clears it.
      }
    }
  }

  /// Where an attachment's ciphertext is kept for [serverId].
  Future<File> ciphertextFile(String serverId, String attachmentId) async {
    final dir = Directory('${_ciphertextRoot.path}/${_safe(serverId)}');
    await dir.create(recursive: true);
    return File('${dir.path}/${_safe(attachmentId)}');
  }

  /// A fresh path to decrypt a file into, named after [name] so a player or
  /// viewer that looks at the extension is not confused. Each file gets its own
  /// folder, so two files with the same name never collide.
  Future<File> plaintextFile(String name) async {
    final dir = Directory('${_openRoot.path}/${_randomId()}');
    await dir.create(recursive: true);
    return File('${dir.path}/${safeFileName(name)}');
  }

  /// A fresh path to encrypt an outgoing file into.
  Future<File> uploadFile() async {
    await _uploadRoot.create(recursive: true);
    return File('${_uploadRoot.path}/${_randomId()}.rda');
  }

  /// Marks a ciphertext file as just used and trims the cache to its budget.
  Future<void> touchAndTrim(File used) async {
    try {
      await used.setLastModified(DateTime.now());
    } on FileSystemException {
      return;
    }
    if (!await _ciphertextRoot.exists()) return;

    final files = <(File, FileStat)>[];
    await for (final entity in _ciphertextRoot.list(recursive: true)) {
      if (entity is File) files.add((entity, await entity.stat()));
    }
    var total = files.fold<int>(0, (sum, f) => sum + f.$2.size);
    if (total <= ciphertextBudgetBytes) return;

    files.sort((a, b) => a.$2.modified.compareTo(b.$2.modified));
    for (final (file, stat) in files) {
      if (total <= ciphertextBudgetBytes) break;
      if (file.path == used.path) continue;
      try {
        await file.delete();
        total -= stat.size;
      } on FileSystemException {
        // In use; leave it for next time.
      }
    }
  }

  static String _randomId() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  static String _safe(String id) =>
      id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
}

/// A sender-chosen file name made safe to create on this device: only its last
/// path component, without control or reserved characters, never empty, never
/// `.` or `..`, and not absurdly long. The name inside an encrypted message is
/// the sender's word, not a path to be trusted.
String safeFileName(String name) {
  var base = name.split(RegExp(r'[/\\]')).last;
  base = base.replaceAll(RegExp(r'[\x00-\x1f<>:"|?*]'), '_').trim();
  if (base.isEmpty || base == '.' || base == '..') base = 'file';
  if (base.length > 120) {
    final dot = base.lastIndexOf('.');
    final extension = dot > 0 && base.length - dot <= 17
        ? base.substring(dot)
        : '';
    base = base.substring(0, 120 - extension.length) + extension;
  }
  return base;
}
