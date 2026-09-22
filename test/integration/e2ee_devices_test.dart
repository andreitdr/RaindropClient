// End-to-end test of device identities against a real RaindropServer, with
// the real Rust crypto core: what the C# server parses and verifies is exactly
// what the Rust core produces.
//
// Needs the crypto library built (`cargo build -p raindrop_crypto_ffi` in
// ../RaindropCrypto) and a server with a fresh database, named by
// RAINDROP_TEST_SERVER (host:port), for example:
//
//   RAINDROP_URLS=https://localhost:5097 RAINDROP_DB_CONNECTION_STRING="Data Source=/tmp/e2ee.db" dotnet run --project ../RaindropServer/ServerCli
//   RAINDROP_TEST_SERVER=localhost:5097 flutter test test/integration
//
// Skips itself when either is missing.
import 'dart:io';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/crypto/bridge/frb_generated.dart';
import 'package:raindrop_client/core/crypto/crypto_engine.dart';
import 'package:raindrop_client/core/crypto/mls_crypto_engine.dart';
import 'package:raindrop_client/core/network/api_client.dart';
import 'package:raindrop_client/core/network/api_exception.dart';
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

class _Device {
  _Device(this.engine, this.userId, this.token, this.api);

  final MlsCryptoEngine engine;
  final String userId;
  final String token;
  final E2eeApi api;

  Future<void> bind(String deviceId) async {
    final nonce = await api.sessionChallenge(token);
    await api.bindSession(
      token,
      deviceId: deviceId,
      signature: await engine.signSessionChallenge(nonce),
    );
  }
}

Matcher _apiError(String code) =>
    throwsA(isA<ApiException>().having((e) => e.code, 'code', code));

void main() {
  late Directory dir;
  late ApiClient client;
  late UsersApi users;
  late E2eeApi api;

  setUpAll(() async {
    if (_skip != null) return;
    await RustLib.init(
      externalLibrary: ExternalLibrary.open(File(_library).absolute.path),
    );
    final parts = _server!.split(':');
    client = ApiClient.forServer(host: parts[0], port: int.parse(parts[1]));
    users = UsersApi(client);
    api = E2eeApi(client);
  });
  setUp(() => dir = Directory.systemTemp.createTempSync('raindrop_e2ee'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<MlsCryptoEngine> engine(String name) => MlsCryptoEngine.open(
    path: '${dir.path}/$name.db',
    key: Uint8List(32)..fillRange(0, 32, name.length),
  );

  Future<SessionResult> register(String name) => users.register(
    userId: _uuid.v4(),
    username: '$name${DateTime.now().microsecondsSinceEpoch}',
    password: 'correct horse battery',
  );

  Future<_Device> signIn(SessionResult account, String store) async =>
      _Device(await engine(store), account.user.userId, account.token, api);

  test(
    'devices, binding, linking, revoking, restoring and resetting',
    () async {
      expect(
        (await users.serverInfo()).capabilities,
        contains(e2eeDevicesCapability),
      );

      // Alice's first device establishes her identity.
      final alice = await register('alice');
      final laptop = await signIn(alice, 'laptop');
      final laptopKeys = await laptop.engine.createIdentity(
        userId: alice.user.userId,
        deviceId: _uuid.v4(),
      );
      await api.registerDevice(alice.token, laptopKeys.certificate);
      await api.registerDevice(alice.token, laptopKeys.certificate); // no-op

      // Unbound, she cannot replace her backup; bound, she can.
      final backup = await laptop.engine.sealBackupWithRecoveryKey();
      await expectLater(
        api.putBackup(alice.token, backup.blob),
        _apiError('device_required'),
      );
      await laptop.bind(laptopKeys.deviceId);
      await api.putBackup(alice.token, backup.blob);

      // A signature by another key does not bind.
      final nonce = await api.sessionChallenge(alice.token);
      final other = await engine('other');
      await other.createIdentity(
        userId: alice.user.userId,
        deviceId: _uuid.v4(),
      );
      await expectLater(
        api.bindSession(
          alice.token,
          deviceId: laptopKeys.deviceId,
          signature: await other.signSessionChallenge(nonce),
        ),
        _apiError('invalid_signature'),
      );

      // A device signed by a different identity key is refused.
      await expectLater(
        api.registerDevice(alice.token, (await other.device())!.certificate),
        _apiError('identity_mismatch'),
      );

      // Bob sees Alice's identity key and device.
      final bob = await register('bob');
      final listed = await api.listDevices(bob.token, [alice.user.userId]);
      expect(listed.single.identityKey, laptopKeys.userIdentityKey);
      expect(listed.single.devices.single.deviceId, laptopKeys.deviceId);

      // Alice links her phone: new password session, link through the relay.
      final phoneLogin = await users.login(
        userId: alice.user.userId,
        password: 'correct horse battery',
      );
      final phone = await signIn(phoneLogin, 'phone');
      final phoneDeviceId = _uuid.v4();
      final offer = await phone.engine.beginDeviceLink(
        userId: alice.user.userId,
        deviceId: phoneDeviceId,
      );
      final linkId = await api.startLink(phone.token, offer.offer);
      final code = DeviceLinkCode(linkId: linkId, commitment: offer.commitment);
      expect(await api.takeLinkApproval(phone.token, linkId), isNull);

      final parsed = DeviceLinkCode.tryParse(code.toString().toLowerCase())!;
      final fetched = await api.linkOffer(alice.token, parsed.linkId);
      final approval = await laptop.engine.approveDeviceLink(
        fetched,
        parsed.commitment,
      );
      await api.approveLink(alice.token, parsed.linkId, approval);

      final approved = await api.takeLinkApproval(phone.token, linkId);
      final phoneKeys = await phone.engine.completeDeviceLink(approved!);
      expect(phoneKeys.userIdentityKey, laptopKeys.userIdentityKey);
      await api.registerDevice(phone.token, phoneKeys.certificate);
      await phone.bind(phoneDeviceId);
      expect(
        (await api.listDevices(bob.token, [alice.user.userId])).single.devices,
        hasLength(2),
      );

      // The laptop revokes the phone; the phone's bound session ends.
      await api.revokeDevice(alice.token, phoneDeviceId);
      await expectLater(
        api.listDevices(phone.token, [alice.user.userId]),
        _apiError('invalid_session'),
      );

      // Everything lost: a new install restores from the recovery key.
      final restoreLogin = await users.login(
        userId: alice.user.userId,
        password: 'correct horse battery',
      );
      final restored = await signIn(restoreLogin, 'restored');
      final blob = await api.getBackup(restoreLogin.token);
      final restoredKeys = await restored.engine.restoreWithRecoveryWords(
        backup: blob!,
        words: backup.recoveryWords!,
        deviceId: _uuid.v4(),
      );
      await api.registerDevice(restoreLogin.token, restoredKeys.certificate);
      await restored.bind(restoredKeys.deviceId);

      // An unbound session cannot revoke somebody else's device.
      final thief = await users.login(
        userId: alice.user.userId,
        password: 'correct horse battery',
      );
      await expectLater(
        api.revokeDevice(thief.token, laptopKeys.deviceId),
        _apiError('device_required'),
      );

      // Reset: identity, backup and devices are gone; the old key is refused
      // only until a new one is established, and then the new one is required.
      await api.resetIdentity(thief.token, 'correct horse battery');
      final afterReset = await api.listDevices(bob.token, [alice.user.userId]);
      expect(afterReset.single.identityKey, isNull);
      expect(afterReset.single.devices, isEmpty);
      expect(await api.getBackup(thief.token), isNull);
      await expectLater(
        api.listDevices(alice.token, [alice.user.userId]),
        _apiError('invalid_session'),
      );

      final fresh = await engine('fresh');
      final freshKeys = await fresh.createIdentity(
        userId: alice.user.userId,
        deviceId: _uuid.v4(),
      );
      await api.registerDevice(thief.token, freshKeys.certificate);
      await expectLater(
        api.registerDevice(thief.token, laptopKeys.certificate),
        _apiError('identity_mismatch'),
      );
    },
    skip: _skip,
  );
}
