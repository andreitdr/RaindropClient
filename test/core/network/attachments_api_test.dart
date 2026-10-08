import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/crypto/attachment_cipher.dart';
import 'package:raindrop_client/core/network/attachments_api.dart';
import 'package:raindrop_client/core/network/grpc/protocol.dart' as pb;
import 'package:raindrop_client/core/storage/attachment_cache.dart';

void main() {
  const mb = 1024 * 1024;

  final policy = AttachmentPolicy.fromProto(
    pb.AttachmentPolicy(
      enabled: true,
      maximumFileBytes: Int64(25 * mb),
      maximumFileBytesByExtension: {'mp4': Int64(500 * mb)}.entries,
      blockedExtensions: ['exe', 'bat'],
      allowFilesWithoutExtension: false,
      maximumFilesPerMessage: 10,
      previewExtensions: ['png', 'mp4'],
      previewAutoLoadMaximumBytes: Int64(10 * mb),
      uploadFrameBytes: 256 * 1024,
    ),
  );

  test('an absent allow-list means any extension, an empty one none', () {
    expect(policy.allowedExtensions, isNull);
    expect(policy.uploadFrameBytes, 256 * 1024);
    final none = AttachmentPolicy.fromProto(
      pb.AttachmentPolicy(
        enabled: true,
        maximumFileBytes: Int64(mb),
        allowedExtensions: pb.ExtensionList(),
      ),
    );
    expect(none.allowedExtensions, isEmpty);
    expect(none.refusalFor('a.png', 1), isNotNull);
  });

  test('a file is checked the way the server checks it', () {
    expect(policy.refusalFor('photo.PNG', 3 * mb), isNull);
    expect(policy.refusalFor('setup.exe', 10), contains('.exe'));
    expect(policy.refusalFor('Makefile', 10), contains('without an extension'));
    expect(policy.refusalFor('big.png', 26 * mb), contains('25 MB'));
    expect(policy.refusalFor('film.mp4', 400 * mb), isNull);
    expect(policy.refusalFor('film.mp4', 501 * mb), contains('500 MB'));
    expect(
      const AttachmentPolicy(
        enabled: false,
        maximumFileBytes: mb,
      ).refusalFor('a.png', 1),
      isNotNull,
    );
  });

  test('an allow-list accepts only what it names', () {
    final strict = AttachmentPolicy.fromProto(
      pb.AttachmentPolicy(
        enabled: true,
        maximumFileBytes: Int64(mb),
        allowFilesWithoutExtension: true,
        allowedExtensions: pb.ExtensionList(extensions: ['png']),
      ),
    );
    expect(strict.refusalFor('a.png', 1), isNull);
    expect(strict.refusalFor('a.zip', 1), isNotNull);
  });

  test('extensions are read as the server reads them', () {
    expect(extensionOf('Holiday.JPG'), 'jpg');
    expect(extensionOf('archive.tar.gz'), 'gz');
    expect(extensionOf('.bashrc'), '');
    expect(extensionOf('trailing.'), '');
    expect(extensionOf('no_extension'), '');
    expect(extensionOf('dir.d/file'), '');
    expect(extensionOf('weird.p!ng'), '');
  });

  test('the ciphertext length matches the Rust core and the server', () {
    expect(attachmentCiphertextLength(0), 36);
    expect(attachmentCiphertextLength(1), 37);
    expect(attachmentCiphertextLength(65536), 20 + 65536 + 16);
    expect(attachmentCiphertextLength(65537), 20 + 65537 + 32);
  });

  test('sizes read like people write them', () {
    expect(formatBytes(512), '512 B');
    expect(formatBytes(1536), '1.5 KB');
    expect(formatBytes(25 * mb), '25 MB');
    expect(formatBytes((1.4 * 1024 * mb).round()), '1.4 GB');
  });

  test('a sender\'s file name never becomes a path', () {
    expect(safeFileName('../../etc/passwd'), 'passwd');
    expect(safeFileName(r'C:\Users\x\evil.exe'), 'evil.exe');
    expect(safeFileName('..'), 'file');
    expect(safeFileName(''), 'file');
    expect(safeFileName('a<b>c.txt'), 'a_b_c.txt');
    final long = safeFileName('${'x' * 300}.mp4');
    expect(long.length, 120);
    expect(long.endsWith('.mp4'), isTrue);
  });
}
