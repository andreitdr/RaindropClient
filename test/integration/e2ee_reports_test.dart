// Reporting an end-to-end encrypted message against a real RaindropServer:
// the sender's device attests the message inside the encrypted payload, and
// the server verifies a report's text against that attestation — so what the
// Dart client signs and what C# recomputes must match byte for byte. Same
// setup as e2ee_devices_test.dart.
import 'dart:io';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/crypto/bridge/frb_generated.dart';
import 'package:raindrop_client/core/crypto/message_payload.dart';
import 'package:raindrop_client/core/crypto/mls_crypto_engine.dart';
import 'package:raindrop_client/core/network/raindrop_channel.dart';
import 'package:raindrop_client/core/network/api_exception.dart';
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

Matcher _apiError(String code) =>
    throwsA(isA<ApiException>().having((e) => e.code, 'code', code));

void main() {
  late Directory dir;
  late UsersApi users;
  late ChannelsApi channels;
  late TextMessagesApi messages;
  late E2eeApi api;

  setUpAll(() async {
    if (_skip != null) return;
    await RustLib.init(
      externalLibrary: ExternalLibrary.open(File(_library).absolute.path),
    );
    final parts = _server!.split(':');
    final client = RaindropChannel.forServer(
      host: parts[0],
      port: int.parse(parts[1]),
    );
    users = UsersApi(client);
    channels = ChannelsApi(client);
    messages = TextMessagesApi(client);
    api = E2eeApi(client);
  });
  setUp(() => dir = Directory.systemTemp.createTempSync('raindrop_reports'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<(ChannelGroups, String)> member(String name) async {
    final account = await users.register(
      userId: _uuid.v4(),
      username: '$name${DateTime.now().microsecondsSinceEpoch}',
      password: 'correct horse battery',
    );
    final engine = await MlsCryptoEngine.open(
      path: '${dir.path}/$name.db',
      key: Uint8List(32)..fillRange(0, 32, name.length + 7),
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
    return (groups, account.token);
  }

  test(
    'a report proves its text with the author\'s attestation',
    () async {
      final (alice, aliceToken) = await member('alice');
      final (bob, bobToken) = await member('bob');
      final channelId = (await channels.create(
        aliceToken,
        name: 'reports${DateTime.now().microsecondsSinceEpoch}',
      )).channelId;

      // Alice sends an attested message — non-ASCII on purpose, so both sides
      // must agree on UTF-8.
      const text = 'you are all fired — ünïcödé ✓';
      final unsigned = MessagePayload.text(text, clientMessageId: _uuid.v4());
      final payload = unsigned.withAttestation(
        await alice.engine.signMessageAttestation(
          unsigned.attestationBytes(channelId),
        ),
      );
      final ciphertext = await alice.encrypt(channelId, payload.encode());
      final stored = await messages.sendEncrypted(
        aliceToken,
        channelId: channelId,
        message: ciphertext,
      );

      // Bob decrypts it; the attestation travelled inside the encryption.
      await bob.onConnected();
      final decrypted = MessagePayload.tryDecode(
        (await bob.decrypt(
          channelId: channelId,
          messageId: stored.messageId,
          sentAt: stored.sentAtUtc,
          ciphertext: ciphertext,
          epoch: stored.epoch!,
          senderDeviceId: stored.senderDeviceId,
        ))!,
      )!;
      expect(decrypted.body, text);
      expect(decrypted.attestation, isNotNull);

      Future<void> report({String? body}) => messages.report(
        bobToken,
        messageId: stored.messageId,
        body: body ?? decrypted.body,
        clientMessageId: decrypted.clientMessageId,
        clientSentAt: decrypted.sentAt,
        type: decrypted.type,
        attestation: decrypted.attestation!,
        reason: 'threatening',
      );

      // Putting words in Alice's mouth fails; the real text goes through.
      await expectLater(
        report(body: 'you are all promoted — ünïcödé ✓'),
        _apiError('invalid_attestation'),
      );
      await report();

      // Alice created the channel, so she moderates it and sees the report;
      // Bob does not.
      final listed = await messages.reports(aliceToken, channelId: channelId);
      expect(listed.single.body, text);
      expect(listed.single.reason, 'threatening');
      await expectLater(
        messages.reports(bobToken, channelId: channelId),
        _apiError('missing_permission'),
      );
    },
    skip: _skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
