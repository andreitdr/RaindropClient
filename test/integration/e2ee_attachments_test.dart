// End-to-end encrypted file attachments against a real RaindropServer: the
// Rust core's attachment format, the chunked upload, a `files` message through
// the channel's MLS group, the download, and the v2 attestation a report
// checks. Same setup as e2ee_messages_test.dart.
//
// After running it, grep the server's database files *and its attachments
// folder* for the test's secret: it must appear in neither.
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/crypto/attachment_cipher.dart';
import 'package:raindrop_client/core/crypto/bridge/frb_generated.dart';
import 'package:raindrop_client/core/crypto/message_payload.dart';
import 'package:raindrop_client/core/crypto/mls_crypto_engine.dart';
import 'package:raindrop_client/core/network/api_client.dart';
import 'package:raindrop_client/core/network/api_exception.dart';
import 'package:raindrop_client/core/network/attachments_api.dart';
import 'package:raindrop_client/core/network/channels_api.dart';
import 'package:raindrop_client/core/network/e2ee_api.dart';
import 'package:raindrop_client/core/network/text_messages_api.dart';
import 'package:raindrop_client/core/network/users_api.dart';
import 'package:raindrop_client/features/security/controllers/channel_groups.dart';
import 'package:uuid/uuid.dart';

const _library = '../RaindropCrypto/target/debug/libraindrop_crypto_ffi.dylib';
final _server = Platform.environment['RAINDROP_TEST_SERVER'];
final _skip = _server == null
    ? 'set RAINDROP_TEST_SERVER'
    : !File(_library).existsSync()
    ? 'build RaindropCrypto first'
    : null;

const _uuid = Uuid();

/// A secret that must never appear on the server, in its database or its
/// attachments folder.
const secret = 'infrared-platypus-4418';

class _Member {
  _Member(this.groups, this.token);

  final ChannelGroups groups;
  final String token;
}

Matcher _apiError(String code) =>
    throwsA(isA<ApiException>().having((e) => e.code, 'code', code));

void main() {
  late Directory dir;
  late UsersApi users;
  late ChannelsApi channels;
  late TextMessagesApi messages;
  late AttachmentsApi attachments;
  late E2eeApi api;
  const cipher = RustAttachmentCipher();

  setUpAll(() async {
    if (_skip != null) return;
    await RustLib.init(
      externalLibrary: ExternalLibrary.open(File(_library).absolute.path),
    );
    final parts = _server!.split(':');
    final client = ApiClient.forServer(
      host: parts[0],
      port: int.parse(parts[1]),
    );
    users = UsersApi(client);
    channels = ChannelsApi(client);
    messages = TextMessagesApi(client);
    attachments = AttachmentsApi(client);
    api = E2eeApi(client);
  });
  setUp(() => dir = Directory.systemTemp.createTempSync('raindrop_files'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<_Member> member(String name) async {
    final account = await users.register(
      userId: _uuid.v4(),
      username: '$name${DateTime.now().microsecondsSinceEpoch}',
      password: 'correct horse battery',
    );
    final engine = await MlsCryptoEngine.open(
      path: '${dir.path}/$name.db',
      key: Uint8List(32)..fillRange(0, 32, name.length + 5),
    );
    final keys = await engine.createIdentity(
      userId: account.user.userId,
      deviceId: _uuid.v4(),
    );
    await api.registerDevice(account.token, keys.certificate);
    final nonce = await api.sessionChallenge(account.token);
    await api.bindSession(
      account.token,
      deviceId: keys.deviceId,
      signature: await engine.signSessionChallenge(nonce),
    );
    final groups = ChannelGroups(
      engine: engine,
      api: api,
      token: account.token,
      self: DeviceRef(userId: keys.userId, deviceId: keys.deviceId),
    );
    await groups.topUpKeyPackages();
    return _Member(groups, account.token);
  }

  /// Encrypts [plaintext] as a file and uploads it in chunks the size the
  /// server asks for.
  Future<AttachmentDescriptor> upload(
    _Member from,
    String channelId,
    String name,
    Uint8List plaintext,
  ) async {
    final input = File('${dir.path}/$name')..writeAsBytesSync(plaintext);
    final sealedPath = '${input.path}.rda';
    final sealed = await cipher.encryptFile(input.path, sealedPath);
    final encrypted = File(sealedPath).readAsBytesSync();

    final status = await attachments.create(
      from.token,
      channelId: channelId,
      extension: extensionOf(name),
      ciphertextSize: sealed.ciphertextLength,
    );
    for (var offset = 0; offset < encrypted.length; offset += status.chunkSize) {
      await attachments.chunk(
        from.token,
        attachmentId: status.attachmentId,
        offset: offset,
        bytes: encrypted.sublist(offset, min(offset + status.chunkSize, encrypted.length)),
      );
    }
    await attachments.complete(
      from.token,
      attachmentId: status.attachmentId,
      ciphertextSha256: sealed.ciphertextSha256,
    );

    return AttachmentDescriptor(
      attachmentId: status.attachmentId,
      key: sealed.key,
      name: name,
      mimeType: 'text/plain',
      size: plaintext.length,
      ciphertextSha256: sealed.ciphertextSha256,
    );
  }

  /// Posts a `files` message, attested under v2, and returns it as stored with
  /// the payload it carried.
  Future<(ChannelMessage, MessagePayload)> sendFiles(
    _Member from,
    String channelId,
    String caption,
    List<AttachmentDescriptor> files,
  ) async {
    final unsigned = MessagePayload.files(caption, files, clientMessageId: _uuid.v4());
    final payload = unsigned.withAttestation(
      await from.groups.engine.signMessageAttestationV2(unsigned.attestationBytes(channelId)),
    );
    final ciphertext = await from.groups.encrypt(channelId, payload.encode());
    final stored = await messages.sendEncrypted(
      from.token,
      channelId: channelId,
      message: ciphertext,
      attachmentIds: [for (final f in payload.attestedFiles) f.attachmentId],
    );
    await from.groups.rememberSent(
      channelId: channelId,
      messageId: stored.messageId,
      sentAt: stored.sentAtUtc,
      ciphertext: ciphertext,
    );
    return (stored, payload);
  }

  test(
    'encrypted files end to end',
    () async {
      final alice = await member('alice');
      final bob = await member('bob');
      final channelId = (await channels.create(
        alice.token,
        name: 'files${DateTime.now().microsecondsSinceEpoch}',
      )).channelId;

      final policy = await attachments.policy(alice.token);
      expect(policy.enabled, isTrue);

      // A file larger than one chunk would be with a small chunk size, with
      // the secret inside it.
      final content = Uint8List.fromList(
        [for (var i = 0; i < 3000; i++) ...'$secret $i\n'.codeUnits],
      );
      final file = await upload(alice, channelId, 'notes.txt', content);

      // The server refuses what its rules refuse, before any bytes.
      await expectLater(
        attachments.create(alice.token, channelId: channelId, extension: 'exe', ciphertextSize: 36),
        _apiError('file_type_not_allowed'),
      );
      await expectLater(
        attachments.create(
          alice.token,
          channelId: channelId,
          extension: 'txt',
          ciphertextSize: attachmentCiphertextLength(policy.maximumBytesFor('txt') + 1),
        ),
        _apiError('file_too_large'),
      );
      await expectLater(
        attachments.create(alice.token, channelId: channelId, extension: 'txt', ciphertextSize: 35),
        _apiError('invalid_attachment'),
      );

      // Bob cannot fetch Alice's upload before she sends it.
      await expectLater(
        attachments.download(bob.token, attachmentId: file.attachmentId, savePath: '${dir.path}/early'),
        _apiError('attachment_not_found'),
      );

      final (stored, payload) = await sendFiles(alice, channelId, 'my notes', [file]);
      expect(stored.attachments.single.attachmentId, file.attachmentId);
      expect(stored.attachments.single.extension, 'txt');

      // A file goes out in one message only.
      await expectLater(sendFiles(alice, channelId, 'again', [file]), _apiError('attachment_already_sent'));

      // Bob decrypts the message, fetches the file and opens it byte for byte.
      await bob.groups.onConnected();
      final page = await messages.history(bob.token, channelId: channelId);
      final received = page.messages.last;
      final bytes = await bob.groups.decrypt(
        channelId: channelId,
        messageId: received.messageId,
        sentAt: received.sentAtUtc,
        ciphertext: received.ciphertext!,
        epoch: received.epoch!,
        senderDeviceId: received.senderDeviceId,
      );
      final decoded = MessagePayload.tryDecode(bytes!)!;
      expect(decoded.type, MessagePayload.filesType);
      expect(decoded.body, 'my notes');
      final descriptor = decoded.files.single;
      expect(received.attachments.single.attachmentId, descriptor.attachmentId);

      final downloaded = '${dir.path}/download.rda';
      await attachments.download(bob.token, attachmentId: descriptor.attachmentId, savePath: downloaded);
      expect(sha256.convert(File(downloaded).readAsBytesSync()).bytes, descriptor.ciphertextSha256);
      final opened = '${dir.path}/opened.txt';
      await cipher.decryptFile(
        downloaded,
        opened,
        key: descriptor.key,
        expectedSha256: descriptor.ciphertextSha256,
      );
      expect(File(opened).readAsBytesSync(), content);

      // A download can be resumed.
      final partial = File('${dir.path}/partial.rda')
        ..writeAsBytesSync(File(downloaded).readAsBytesSync().sublist(0, 1000));
      await attachments.download(
        bob.token,
        attachmentId: descriptor.attachmentId,
        savePath: partial.path,
        fromByte: 1000,
      );
      expect(partial.readAsBytesSync(), File(downloaded).readAsBytesSync());

      // Bob reports it: the v2 attestation covers the file, and a report that
      // names another hash is refused.
      await messages.report(
        bob.token,
        messageId: received.messageId,
        body: decoded.body,
        clientMessageId: decoded.clientMessageId,
        clientSentAt: decoded.sentAt,
        type: decoded.type,
        attestation: decoded.attestation!,
        attachments: decoded.attestedFiles,
      );
      await expectLater(
        messages.report(
          bob.token,
          messageId: received.messageId,
          body: decoded.body,
          clientMessageId: decoded.clientMessageId,
          clientSentAt: decoded.sentAt,
          type: decoded.type,
          attestation: decoded.attestation!,
          attachments: [(attachmentId: descriptor.attachmentId, ciphertextSha256: Uint8List(32))],
        ),
        _apiError('invalid_attestation'),
      );
      expect(payload.attestsFiles, isTrue);

      // Deleting the message takes the file with it.
      await messages.delete(alice.token, messageId: stored.messageId);
      await expectLater(
        attachments.download(bob.token, attachmentId: descriptor.attachmentId, savePath: '${dir.path}/late'),
        _apiError('attachment_not_found'),
      );
    },
    skip: _skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
