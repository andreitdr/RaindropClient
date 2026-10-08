// The media keys of end-to-end encrypted calls, against a real
// RaindropServer: every member of a voice channel's MLS group derives the
// same key, a rotation moves everyone to a new one, and a device removed
// from the group cannot follow. (Encrypting the audio itself happens in
// LiveKit's frame cryptor on a device; see docs/voice.md for checking that
// by hand.) Same setup as e2ee_devices_test.dart.
import 'dart:io';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/crypto/bridge/frb_generated.dart';
import 'package:raindrop_client/core/crypto/crypto_engine.dart';
import 'package:raindrop_client/core/crypto/mls_crypto_engine.dart';
import 'package:raindrop_client/core/network/raindrop_channel.dart';
import 'package:raindrop_client/core/network/channels_api.dart';
import 'package:raindrop_client/core/network/e2ee_api.dart';
import 'package:raindrop_client/core/network/event_stream.dart';
import 'package:raindrop_client/core/network/grpc/protocol.dart' as pb;
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

void main() {
  late Directory dir;
  late UsersApi users;
  late ChannelsApi channels;
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
    api = E2eeApi(client);
  });
  setUp(() => dir = Directory.systemTemp.createTempSync('raindrop_voice'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<(ChannelGroups, String, String)> member(String name) async {
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
    return (groups, account.token, keys.deviceId);
  }

  test(
    'voice media keys come from the channel group and rotate',
    () async {
      expect(
        (await users.serverInfo()).capabilities,
        contains(e2eeVoiceCapability),
      );

      final (alice, aliceToken, _) = await member('alice');
      final (bob, _, _) = await member('bob');
      final (carol, carolToken, carolDevice) = await member('carol');

      final voice = await channels.create(
        aliceToken,
        name: 'call${DateTime.now().microsecondsSinceEpoch}',
        type: ChannelTypeNames.voice,
      );
      final channelId = voice.channelId;

      // Alice starts the call: her key creates the group and adds Bob and
      // Carol, who pick up their Welcomes.
      final first = await alice.mediaKey(channelId);
      expect(first.key, hasLength(32));
      await bob.onConnected();
      await carol.onConnected();
      for (final other in [bob, carol]) {
        final key = await other.mediaKey(channelId);
        expect(key.key, first.key);
        expect(key.index, first.index);
      }

      // The key is specific to this channel's group and label: a text channel's
      // group, or another label, gives something else.
      final group = groupIdForChannel(channelId);
      expect(
        await alice.engine.exportSecret(
          group,
          label: 'something else',
          context: group,
        ),
        isNot(first.key),
      );

      // A rotation: a new epoch, a new key and slot, and Bob follows it — the
      // epoch change is what a call listens for to switch keys.
      final bobChanged = bob.epochChanges.firstWhere((c) => c == channelId);
      await alice.rotate(channelId);
      await bob.catchUp(channelId);
      await bobChanged.timeout(const Duration(seconds: 5));
      final rotated = await alice.mediaKey(channelId);
      expect(rotated.key, isNot(first.key));
      expect(rotated.index, (first.index + 1) % ChannelGroups.mediaKeyRingSize);
      expect((await bob.mediaKey(channelId)).key, rotated.key);

      // Carol's device is revoked; the group removes her, and the key moves on
      // without her.
      await api.revokeDevice(carolToken, carolDevice);
      alice.onEvent(
        ServerEvent(pb.ServerEvent(groupReconcile: pb.GroupReconcileEvent(channelId: channelId))),
      );
      await Future<void>.delayed(const Duration(seconds: 3));
      await bob.catchUp(channelId);
      final afterRemoval = await alice.mediaKey(channelId);
      expect(afterRemoval.key, isNot(rotated.key));
      expect((await bob.mediaKey(channelId)).key, afterRemoval.key);
      expect(
        (await alice.engine.members(group)).map((m) => m.deviceId),
        isNot(contains(carolDevice)),
      );
    },
    skip: _skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
