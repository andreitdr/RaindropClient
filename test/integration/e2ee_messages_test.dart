// End-to-end encrypted text messages against a real RaindropServer: the
// app's own ChannelGroups and message API, the real Rust core, and the real
// delivery service. Same setup as e2ee_devices_test.dart.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/crypto/bridge/frb_generated.dart';
import 'package:raindrop_client/core/crypto/crypto_engine.dart';
import 'package:raindrop_client/core/crypto/message_payload.dart';
import 'package:raindrop_client/core/crypto/mls_crypto_engine.dart';
import 'package:raindrop_client/core/network/raindrop_channel.dart';
import 'package:raindrop_client/core/network/api_exception.dart';
import 'package:raindrop_client/core/network/channels_api.dart';
import 'package:raindrop_client/core/network/e2ee_api.dart';
import 'package:raindrop_client/core/network/event_stream.dart';
import 'package:raindrop_client/core/network/grpc/protocol.dart' as pb;
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

/// A secret that must never appear on the server. The test runner greps the
/// server's database for it afterwards.
const secret = 'ultraviolet-kangaroo-7731';

class _Member {
  _Member(this.groups, this.token, this.deviceId);

  final ChannelGroups groups;
  final String token;
  final String deviceId;
}

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
  setUp(() => dir = Directory.systemTemp.createTempSync('raindrop_messages'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<_Member> member(String name) async {
    final account = await users.register(
      userId: _uuid.v4(),
      username: '$name${DateTime.now().microsecondsSinceEpoch}',
      password: 'correct horse battery',
    );
    final engine = await MlsCryptoEngine.open(
      path: '${dir.path}/$name.db',
      key: Uint8List(32)..fillRange(0, 32, name.length + 3),
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
    return _Member(groups, account.token, keys.deviceId);
  }

  Future<String> send(_Member from, String channelId, String text) async {
    final payload = MessagePayload.text(
      text,
      clientMessageId: _uuid.v4(),
    ).encode();
    final ciphertext = await from.groups.encrypt(channelId, payload);
    final stored = await messages.sendEncrypted(
      from.token,
      channelId: channelId,
      message: ciphertext,
    );
    expect(stored.content, isNull);
    expect(stored.ciphertext, ciphertext);
    await from.groups.rememberSent(
      channelId: channelId,
      messageId: stored.messageId,
      sentAt: stored.sentAtUtc,
      ciphertext: ciphertext,
    );
    return stored.messageId;
  }

  /// What [reader] sees of each message in the channel, oldest first: the
  /// text, or null where it cannot decrypt.
  Future<List<String?>> read(_Member reader, String channelId) async {
    final page = await messages.history(reader.token, channelId: channelId);
    return [
      for (final m in page.messages)
        if (m.ciphertext == null)
          null
        else
          await reader.groups
              .decrypt(
                channelId: channelId,
                messageId: m.messageId,
                sentAt: m.sentAtUtc,
                ciphertext: m.ciphertext!,
                epoch: m.epoch!,
                senderDeviceId: m.senderDeviceId,
              )
              .then(
                (b) => b == null ? null : MessagePayload.tryDecode(b)?.body,
              ),
    ];
  }

  test(
    'encrypted channel messages end to end',
    () async {
      final alice = await member('alice');
      final bob = await member('bob');
      final carol = await member('carol');

      final channelId = (await channels.create(
        alice.token,
        name: 'e2ee${DateTime.now().microsecondsSinceEpoch}',
      )).channelId;

      // The server refuses plaintext outright.
      await expectLater(
        messages.send(alice.token, channelId: channelId, content: 'hello'),
        _apiError('encryption_required'),
      );

      // Alice's first message creates the group, adding Bob and Carol through
      // their key packages; they pick up their Welcomes.
      await send(alice, channelId, secret);
      await bob.groups.onConnected();
      await carol.groups.onConnected();

      expect(await read(bob, channelId), [secret]);
      expect(await read(carol, channelId), [secret]);
      // Alice reads her own from the cache: a device cannot decrypt what it sent.
      expect(await read(alice, channelId), [secret]);

      final replyId = await send(bob, channelId, 'hi alice');
      expect(await read(alice, channelId), [secret, 'hi alice']);
      expect(await read(alice, channelId), [
        secret,
        'hi alice',
      ], reason: 'read twice, from the cache');

      // Dave joins later, by himself: forward-only history.
      final dave = await member('dave');
      await dave.groups.ensureJoined(channelId);
      await send(carol, channelId, 'welcome dave');
      await alice.groups.catchUp(channelId);
      await bob.groups.catchUp(channelId);
      expect(await read(dave, channelId), [null, null, 'welcome dave']);
      expect(await read(alice, channelId), [
        secret,
        'hi alice',
        'welcome dave',
      ]);

      // A ciphertext from an epoch long gone is refused as stale.
      final old = await alice.groups.encrypt(
        channelId,
        MessagePayload.text('late', clientMessageId: 'x').encode(),
      );
      await api.revokeDevice(dave.token, dave.deviceId);

      // Revoking Dave's device: members are told to reconcile, and one of them
      // removes him, which rotates the keys past him.
      alice.groups.onEvent(
        ServerEvent(pb.ServerEvent(groupReconcile: pb.GroupReconcileEvent(channelId: channelId))),
      );
      await Future<void>.delayed(const Duration(seconds: 3));
      await bob.groups.catchUp(channelId);
      await carol.groups.catchUp(channelId);
      final roster = await api.roster(alice.token, channelId);
      expect(roster.map((d) => d.deviceId), isNot(contains(dave.deviceId)));

      await send(bob, channelId, 'dave cannot read this');
      expect((await read(carol, channelId)).last, 'dave cannot read this');

      // Two more key rotations: the old ciphertext's epoch is now more than
      // the two the server accepts behind.
      final group = groupIdForChannel(channelId);
      await alice.groups.catchUp(channelId);
      for (var i = 0; i < 2; i++) {
        final rotation = await alice.groups.engine.selfUpdate(group);
        await api.submitCommit(alice.token, channelId, rotation.commit);
        await alice.groups.engine.mergePendingCommit(group);
      }
      await expectLater(
        messages.sendEncrypted(alice.token, channelId: channelId, message: old),
        _apiError('stale_epoch'),
      );

      // Deleting an encrypted message leaves a tombstone without the ciphertext.
      final tombstone = await messages.delete(bob.token, messageId: replyId);
      expect(tombstone.deleted, isTrue);
      expect(tombstone.ciphertext, isNull);
      expect(tombstone.encrypted, isTrue);

      // A password session cannot post encrypted messages either.
      final passwordOnly = await users.login(
        userId: (await users.me(alice.token)).userId,
        password: 'correct horse battery',
      );
      await expectLater(
        messages.sendEncrypted(
          passwordOnly.token,
          channelId: channelId,
          message: old,
        ),
        _apiError('device_required'),
      );

      expect(utf8.encode(secret), isNotEmpty);
    },
    skip: _skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
