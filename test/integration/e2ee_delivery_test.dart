// End-to-end test of the MLS delivery service against a real RaindropServer,
// with the real Rust crypto core producing the MLS traffic — so what the C#
// server parses (MlsFraming) and orders is exactly what OpenMLS writes.
//
// Same setup as e2ee_devices_test.dart: build ../RaindropCrypto, start a
// server with a fresh database, and set RAINDROP_TEST_SERVER=host:port.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/crypto/bridge/frb_generated.dart';
import 'package:raindrop_client/core/crypto/crypto_engine.dart';
import 'package:raindrop_client/core/crypto/mls_crypto_engine.dart';
import 'package:raindrop_client/core/network/raindrop_channel.dart';
import 'package:raindrop_client/core/network/api_exception.dart';
import 'package:raindrop_client/core/network/channels_api.dart';
import 'package:raindrop_client/core/network/e2ee_api.dart';
import 'package:raindrop_client/core/network/users_api.dart';
import 'package:uuid/uuid.dart';

const _library = '../RaindropCrypto/target/debug/libraindrop_crypto_ffi.dylib';
final _server = Platform.environment['RAINDROP_TEST_SERVER'];
final _skip = _server == null
    ? 'set RAINDROP_TEST_SERVER'
    : !File(_library).existsSync()
    ? 'build RaindropCrypto first'
    : null;

const _uuid = Uuid();

/// One user with one bound device.
class _Member {
  _Member(this.engine, this.userId, this.deviceId, this.token);

  final MlsCryptoEngine engine;
  final String userId;
  final String deviceId;
  final String token;

  DeviceRef get ref => DeviceRef(userId: userId, deviceId: deviceId);
}

Matcher _apiError(String code) =>
    throwsA(isA<ApiException>().having((e) => e.code, 'code', code));

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
  setUp(() => dir = Directory.systemTemp.createTempSync('raindrop_delivery'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<_Member> member(String name) async {
    final account = await users.register(
      userId: _uuid.v4(),
      username: '$name${DateTime.now().microsecondsSinceEpoch}',
      password: 'correct horse battery',
    );
    final engine = await MlsCryptoEngine.open(
      path: '${dir.path}/$name.db',
      key: Uint8List(32)..fillRange(0, 32, name.length + 1),
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
    return _Member(engine, account.user.userId, keys.deviceId, account.token);
  }

  Future<void> catchUp(_Member m, String channelId, Uint8List group) async {
    final sync = await api.syncGroup(
      m.token,
      channelId,
      await m.engine.epoch(group),
    );
    expect(sync.resyncRequired, isFalse);
    for (final commit in sync.commits) {
      await m.engine.process(commit.message);
    }
    expect(await m.engine.epoch(group), sync.epoch);
  }

  test('groups, key packages, welcomes, external joins and forks', () async {
    expect(
      (await users.serverInfo()).capabilities,
      contains(e2eeDeliveryCapability),
    );

    final alice = await member('alice');
    final bob = await member('bob');
    final carol = await member('carol');

    final channel = await channels.create(
      alice.token,
      name: 'secret${DateTime.now().microsecondsSinceEpoch}',
    );
    final channelId = channel.channelId;
    final group = groupIdForChannel(channelId);

    // Alice starts the group.
    await expectLater(
      api.groupState(alice.token, channelId),
      _apiError('group_not_found'),
    );
    await alice.engine.createGroup(group);
    final created = await api.createGroup(
      alice.token,
      channelId,
      await alice.engine.groupInfo(group),
    );
    expect(created.epoch, 0);
    await expectLater(
      api.createGroup(
        alice.token,
        channelId,
        await alice.engine.groupInfo(group),
      ),
      _apiError('group_exists'),
    );

    // Everyone who can see the channel belongs in its group.
    final roster = await api.roster(alice.token, channelId);
    expect(roster, containsAll([alice.ref, bob.ref, carol.ref]));

    // Bob uploads key packages; Alice claims one and adds him.
    expect(
      await api.uploadKeyPackages(
        bob.token,
        await bob.engine.generateKeyPackages(3),
        lastResort: (await bob.engine.generateKeyPackages(
          1,
          lastResort: true,
        )).single,
      ),
      3,
    );
    final claimed = await api.claimKeyPackages(alice.token, channelId, [
      bob.ref,
    ]);
    // At most 2 left: tests running in parallel on the same server may
    // claim Bob's packages too, since everybody can see every channel there.
    expect(await api.keyPackageCount(bob.token), lessThanOrEqualTo(2));

    final add = await alice.engine.addMembers(group, [claimed[bob.ref]!]);
    expect(
      await api.submitCommit(
        alice.token,
        channelId,
        add.commit,
        welcome: add.welcome,
        welcomeRecipients: [bob.ref],
      ),
      1,
    );
    await alice.engine.mergePendingCommit(group);
    await api.putGroupInfo(
      alice.token,
      channelId,
      await alice.engine.groupInfo(group),
    );

    // Bob picks up his Welcome. (Other tests on the same server may welcome
    // him into their channels too; only this channel's is looked at.)
    Future<List<PendingWelcome>> mine() async => [
      for (final w in await api.welcomes(bob.token))
        if (w.channelId == channelId) w,
    ];
    final welcome = (await mine()).single;
    expect(await bob.engine.joinFromWelcome(welcome.welcome), group);
    await api.ackWelcomes(bob.token, [welcome.welcomeId]);
    expect(await mine(), isEmpty);

    // Carol joins by herself from the published group info.
    final state = await api.groupState(carol.token, channelId);
    expect(state.groupInfoEpoch, 1);
    final join = await carol.engine.joinByExternalCommit(state.groupInfo!);
    expect(
      await api.submitCommit(carol.token, channelId, join.commit.commit),
      2,
    );
    await carol.engine.mergePendingCommit(group);
    await catchUp(alice, channelId, group);
    await catchUp(bob, channelId, group);

    // Alice and Bob both rotate keys in epoch 2: only one commit wins.
    final fromAlice = await alice.engine.selfUpdate(group);
    final fromBob = await bob.engine.selfUpdate(group);
    expect(await api.submitCommit(alice.token, channelId, fromAlice.commit), 3);
    await alice.engine.mergePendingCommit(group);
    await expectLater(
      api.submitCommit(bob.token, channelId, fromBob.commit),
      _apiError('epoch_conflict'),
    );
    await bob.engine.discardPendingCommit(group);
    await catchUp(bob, channelId, group);
    await catchUp(carol, channelId, group);

    // Everyone is in the same epoch with the same keys.
    final key = await alice.engine.exportSecret(
      group,
      label: 'raindrop/voice/v1',
      context: group,
    );
    for (final m in [bob, carol]) {
      expect(await m.engine.epoch(group), 3);
      expect(
        await m.engine.exportSecret(
          group,
          label: 'raindrop/voice/v1',
          context: group,
        ),
        key,
      );
    }
    final hello = await carol.engine.encrypt(group, utf8.encode('hi all'));
    expect(
      utf8.decode(
        (await bob.engine.process(hello) as GroupApplicationMessage).payload,
      ),
      'hi all',
    );

    // A stale group info is refused; so is a commit meant for another group.
    await expectLater(
      api.putGroupInfo(alice.token, channelId, state.groupInfo!),
      _apiError('epoch_conflict'),
    );
    final other = await channels.create(
      alice.token,
      name: 'other${DateTime.now().microsecondsSinceEpoch}',
    );
    final next = await alice.engine.selfUpdate(group);
    await expectLater(
      api.submitCommit(alice.token, other.channelId, next.commit),
      _apiError('wrong_group'),
    );
    await alice.engine.discardPendingCommit(group);
    await expectLater(
      api.submitCommit(
        alice.token,
        channelId,
        Uint8List.fromList([0, 1, 0, 2, 9]),
      ),
      _apiError('invalid_mls_message'),
    );

    // Only devices take part: a password session gets nothing.
    final passwordOnly = await users.login(
      userId: bob.userId,
      password: 'correct horse battery',
    );
    await expectLater(
      api.syncGroup(passwordOnly.token, channelId, 0),
      _apiError('device_required'),
    );

    // A revoked device is out of the roster, gets no key package handed out,
    // and its waiting key packages are gone.
    await api.revokeDevice(bob.token, bob.deviceId);
    expect(await api.roster(alice.token, channelId), isNot(contains(bob.ref)));
    expect(
      await api.claimKeyPackages(alice.token, channelId, [bob.ref]),
      isEmpty,
    );

    // The full log is still there for a device catching up from the start.
    final full = await api.syncGroup(alice.token, channelId, 0);
    expect(full.commits.map((c) => c.epoch), [0, 1, 2]);
  }, skip: _skip);
}
