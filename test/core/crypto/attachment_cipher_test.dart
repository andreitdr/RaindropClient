// Exercises RustAttachmentCipher through the real Rust library: files go in
// and come back through the bridge, and a tampered or substituted ciphertext
// is refused. Needs the library built first:
//
//   cd ../RaindropCrypto && cargo build -p raindrop_crypto_ffi
//
// and skips itself when it is not there.
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/crypto/attachment_cipher.dart';
import 'package:raindrop_client/core/crypto/bridge/frb_generated.dart';
import 'package:raindrop_client/core/crypto/crypto_engine.dart';

String? _library() {
  const base = '../RaindropCrypto/target/debug/';
  for (final name in [
    'libraindrop_crypto_ffi.dylib',
    'libraindrop_crypto_ffi.so',
    'raindrop_crypto_ffi.dll',
  ]) {
    if (File('$base$name').existsSync()) {
      return File('$base$name').absolute.path;
    }
  }
  return null;
}

void main() {
  final library = _library();
  const cipher = RustAttachmentCipher();
  late Directory dir;

  setUpAll(() async {
    if (library != null) {
      await RustLib.init(externalLibrary: ExternalLibrary.open(library));
    }
  });
  setUp(() => dir = Directory.systemTemp.createTempSync('raindrop_attachment'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('a file encrypts and decrypts through the bridge', () async {
    final plaintext = Uint8List.fromList(
      List.generate(200000, (i) => i * 7 % 256),
    );
    final input = File('${dir.path}/in.bin')..writeAsBytesSync(plaintext);
    final sealedPath = '${dir.path}/in.rda';

    final sealed = await cipher.encryptFile(input.path, sealedPath);
    final ciphertext = File(sealedPath).readAsBytesSync();
    expect(sealed.ciphertextLength, ciphertext.length);
    expect(
      sealed.ciphertextLength,
      attachmentCiphertextLength(plaintext.length),
    );
    expect(sealed.ciphertextLength, cipher.ciphertextLength(plaintext.length));
    expect(sealed.ciphertextSha256, sha256.convert(ciphertext).bytes);

    final out = '${dir.path}/out.bin';
    await cipher.decryptFile(
      sealedPath,
      out,
      key: sealed.key,
      expectedSha256: sealed.ciphertextSha256,
    );
    expect(File(out).readAsBytesSync(), plaintext);
  }, skip: library == null ? 'build raindrop_crypto_ffi first' : null);

  test(
    'a substituted or tampered file is refused and leaves nothing behind',
    () async {
      final a = await cipher.encryptBytes(Uint8List.fromList([1, 2, 3]));
      final b = await cipher.encryptBytes(Uint8List.fromList([1, 2, 3]));

      // The right key, but a different file than the message names.
      await expectLater(
        cipher.decryptBytes(
          b.ciphertext,
          key: a.sealed.key,
          expectedSha256: a.sealed.ciphertextSha256,
        ),
        throwsA(
          isA<CryptoException>().having(
            (e) => e.kind,
            'kind',
            CryptoErrorKind.verification,
          ),
        ),
      );

      final tampered = Uint8List.fromList(a.ciphertext)..[25] ^= 1;
      final path = '${dir.path}/tampered.rda';
      File(path).writeAsBytesSync(tampered);
      await expectLater(
        cipher.decryptFile(
          path,
          '${dir.path}/out',
          key: a.sealed.key,
          expectedSha256: sha256.convert(tampered).bytes as Uint8List,
        ),
        throwsA(isA<CryptoException>()),
      );
      expect(File('${dir.path}/out').existsSync(), isFalse);

      expect(
        await cipher.decryptBytes(
          a.ciphertext,
          key: a.sealed.key,
          expectedSha256: a.sealed.ciphertextSha256,
        ),
        [1, 2, 3],
      );
    },
    skip: library == null ? 'build raindrop_crypto_ffi first' : null,
  );
}
