import 'dart:typed_data';

import 'bridge/api/attachment.dart' as rust;
import 'bridge/api/session.dart' as rust_session;
import 'crypto_engine.dart';

/// A file after encryption: [key] and [ciphertextSha256] go into the message
/// that shares it, [ciphertextLength] is what the upload declares.
class SealedFile {
  const SealedFile({
    required this.key,
    required this.ciphertextSha256,
    required this.ciphertextLength,
  });

  final Uint8List key;
  final Uint8List ciphertextSha256;
  final int ciphertextLength;
}

/// Encrypting a file before it is uploaded and decrypting one after it is
/// downloaded, in the Rust core's `raindrop/attachment/v1` format — a fresh
/// key per file, which travels inside the MLS message that shares it. Not
/// tied to a server or a session, because a file's key is its own.
///
/// An interface for the same reason [CryptoEngine] is one: the app never names
/// the bridge, and a test (or a later backend) can stand in for it.
abstract interface class AttachmentCipher {
  /// Encrypts the file at [inputPath] into [outputPath] under a fresh key.
  /// Streams from disk; nothing the size of the file crosses into Dart.
  Future<SealedFile> encryptFile(String inputPath, String outputPath);

  /// Decrypts a downloaded attachment into [outputPath], refusing
  /// ([CryptoErrorKind.verification]) one whose ciphertext does not hash to
  /// [expectedSha256] or does not open with [key]. [outputPath] only appears
  /// once the whole file has verified.
  Future<void> decryptFile(
    String inputPath,
    String outputPath, {
    required Uint8List key,
    required Uint8List expectedSha256,
  });

  /// [encryptFile] for bytes in memory — a generated thumbnail.
  Future<({SealedFile sealed, Uint8List ciphertext})> encryptBytes(
    Uint8List plaintext,
  );

  /// [decryptFile] for bytes in memory.
  Future<Uint8List> decryptBytes(
    Uint8List ciphertext, {
    required Uint8List key,
    required Uint8List expectedSha256,
  });

  /// How many bytes of ciphertext a file of [plaintextLength] bytes becomes.
  int ciphertextLength(int plaintextLength);
}

/// [AttachmentCipher] over the Rust core, reached through the bridge.
class RustAttachmentCipher implements AttachmentCipher {
  const RustAttachmentCipher();

  @override
  Future<SealedFile> encryptFile(String inputPath, String outputPath) => _guard(
    () async => _sealed(
      await rust.encryptAttachmentFile(
        inputPath: inputPath,
        outputPath: outputPath,
      ),
    ),
  );

  @override
  Future<void> decryptFile(
    String inputPath,
    String outputPath, {
    required Uint8List key,
    required Uint8List expectedSha256,
  }) => _guard(
    () => rust.decryptAttachmentFile(
      inputPath: inputPath,
      outputPath: outputPath,
      key: key,
      expectedSha256: expectedSha256,
    ),
  );

  @override
  Future<({SealedFile sealed, Uint8List ciphertext})> encryptBytes(
    Uint8List plaintext,
  ) => _guard(() async {
    final result = await rust.encryptAttachmentBytes(plaintext: plaintext);
    return (sealed: _sealed(result.sealed), ciphertext: result.ciphertext);
  });

  @override
  Future<Uint8List> decryptBytes(
    Uint8List ciphertext, {
    required Uint8List key,
    required Uint8List expectedSha256,
  }) => _guard(
    () => rust.decryptAttachmentBytes(
      ciphertext: ciphertext,
      key: key,
      expectedSha256: expectedSha256,
    ),
  );

  @override
  int ciphertextLength(int plaintextLength) => rust
      .attachmentCiphertextLength(plaintextLength: BigInt.from(plaintextLength))
      .toInt();

  static SealedFile _sealed(rust.SealedAttachment s) => SealedFile(
    key: s.key,
    ciphertextSha256: s.ciphertextSha256,
    ciphertextLength: s.ciphertextLength.toInt(),
  );

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on rust_session.CryptoFailure catch (e) {
      throw CryptoException(switch (e.kind) {
        rust_session.CryptoFailureKind.verification =>
          CryptoErrorKind.verification,
        rust_session.CryptoFailureKind.malformed => CryptoErrorKind.malformed,
        rust_session.CryptoFailureKind.notFound => CryptoErrorKind.notFound,
        _ => CryptoErrorKind.other,
      }, e.message);
    }
  }
}

/// The ciphertext length of the `raindrop/attachment/v1` format, computed in
/// Dart — the same formula the Rust core and the server use (see
/// `RaindropCrypto/docs/attachments.md`), for code that has no bridge, such as
/// checking a file against the server's limits before encrypting it.
int attachmentCiphertextLength(int plaintextLength) {
  const segment = 64 * 1024;
  final segments = plaintextLength == 0
      ? 1
      : (plaintextLength + segment - 1) ~/ segment;
  return 20 + plaintextLength + 16 * segments;
}
