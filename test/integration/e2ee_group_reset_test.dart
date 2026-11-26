// A channel's group that a member breaks with a commit nobody can process,
// recovered end to end against a real RaindropServer: the app's own
// ChannelGroups, the real Rust core and the real delivery service. Same setup
// as e2ee_messages_test.dart; skips itself unless RAINDROP_TEST_SERVER names a
// server that keeps group generations (`e2ee.group-reset.v1`).
import 'dart:io';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/crypto/bridge/frb_generated.dart';
import 'package:raindrop_client/core/crypto/crypto_engine.dart';
import 'package:raindrop_client/core/crypto/message_payload.dart';
import 'package:raindrop_client/core/crypto/mls_crypto_engine.dart';
import 'package:raindrop_client/core/network/api_exception.dart';
import 'package:raindrop_client/core/network/channels_api.dart';
import 'package:raindrop_client/core/network/e2ee_api.dart';
import 'package:raindrop_client/core/network/raindrop_channel.dart';
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

class _Member {
  _Member(this.groups, this.token);

  final ChannelGroups groups;
  final String token;
}

/// A commit for [groupId]'s [epoch] with the right framing and contents no
/// member can decrypt: what a member who wants to break a group submits.
Uint8List _garbageCommit(Uint8List groupId, int epoch) {
  const privateMessage = [0, 1, 0, 2];
  const commit = 3;
  return Uint8List.fromList([
    ...privateMessage,
    groupId.length,
    ...groupId,
    for (var shift = 56; shift >= 0; shift -= 8) (epoch >> shift) & 0xff,
    commit,
    ...List.filled(96, 0xAB),
  ]);
}

void main() {
  late Directory dir;
  late UsersApi users;
  late ChannelsApi channels;
  late TextMessagesApi messages;
  late E2eeApi api;
  var generations = false;

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
    generations = (await users.serverInfo()).capabilities.contains(
      e2eeGroupResetCapability,
    );
  });
  setUp(() => dir = Directory.systemTemp.createTempSync('raindrop_reset'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<_Member> member(String name) async {
    final account = await users.register(
      userId: _uuid.v4(),
      username: '$name${DateTime.now().microsecondsSinceEpoch}',
      password: 'correct horse battery',
    );
    final engine = await MlsCryptoEngine.open(
      path: '${dir.path}/$name.db',
      key: Uint8List(32)..fillRange(0, 32, name.length + 11),
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
      generations: generations,
    );
    await groups.topUpKeyPackages();
    return _Member(groups, account.token);
  }

  Future<void> send(_Member from, String channelId, String text) async {
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
    await from.groups.rememberSent(
      channelId: channelId,
      messageId: stored.messageId,
      sentAt: stored.sentAtUtc,
      ciphertext: ciphertext,
    );
  }

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
    'a commit nobody can process is reported, the group starts a new '
    'generation, and everyone carries on in it with their history',
    () async {
      if (!generations) {
        markTestSkipped('the server does not keep group generations');
        return;
      }
      final alice = await member('alice');
      final bob = await member('bob');
      final mallory = await member('mallory');
      final channelId = (await channels.create(
        alice.token,
        name: 'reset${DateTime.now().microsecondsSinceEpoch}',
      )).channelId;

      await send(alice, channelId, 'before');
      await bob.groups.onConnected();
      await mallory.groups.onConnected();
      expect(await read(bob, channelId), ['before']);

      // Mallory submits garbage for the current epoch. The server cannot tell.
      final state = await api.groupState(mallory.token, channelId);
      expect(state.generation, 0);
      await api.submitCommit(
        mallory.token,
        channelId,
        _garbageCommit(groupIdForChannel(channelId), state.epoch),
      );

      // Alice's next message finds it, reports it, and starts generation 1.
      await send(alice, channelId, 'after');
      expect(await api.groupGeneration(alice.token, channelId), 1);
      final fresh = await api.groupState(alice.token, channelId);
      expect(fresh.generation, 1);

      // Bob never heard of the reset: the message tells him where to go, and
      // his history from generation 0 is still in his cache.
      expect(await read(bob, channelId), ['before', 'after']);
      await send(bob, channelId, 'still here');
      expect(await read(alice, channelId), ['before', 'after', 'still here']);

      // A commit for the old generation's group is refused outright.
      await expectLater(
        api.submitCommit(
          mallory.token,
          channelId,
          _garbageCommit(groupIdForChannel(channelId), fresh.epoch),
        ),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', 'wrong_group'),
        ),
      );
    },
    skip: _skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
