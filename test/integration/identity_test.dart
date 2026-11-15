// End-to-end test of the passwordless identity against a real RaindropServer,
// with the real Rust crypto core: deriving the account, signing in with a
// device key, a second device of the same person, the vault and recovery
// words, the authenticator, and pairing a device through the relay.
//
// Needs the crypto library built (`cargo build -p raindrop_crypto_ffi` in
// ../RaindropCrypto) and a server named by RAINDROP_TEST_SERVER (host:port).
// Skips itself when either is missing. See e2ee_devices_test.dart.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/crypto/bridge/frb_generated.dart';
import 'package:raindrop_client/core/crypto/crypto_engine.dart';
import 'package:raindrop_client/core/crypto/identity_crypto.dart';
import 'package:raindrop_client/core/crypto/mls_crypto_engine.dart';
import 'package:raindrop_client/core/crypto/totp.dart';
import 'package:raindrop_client/core/network/api_exception.dart';
import 'package:raindrop_client/core/network/e2ee_api.dart';
import 'package:raindrop_client/core/network/raindrop_channel.dart';
import 'package:raindrop_client/core/network/users_api.dart';
import 'package:raindrop_client/core/storage/identity_store.dart';
import 'package:raindrop_client/features/identity/device_sign_in.dart';

const _library = '../RaindropCrypto/target/debug/libraindrop_crypto_ffi.dylib';
final _server = Platform.environment['RAINDROP_TEST_SERVER'];
final _skip = _server == null
    ? 'set RAINDROP_TEST_SERVER'
    : !File(_library).existsSync()
    ? 'build RaindropCrypto first'
    : null;

Matcher _apiError(String code) =>
    throwsA(isA<ApiException>().having((e) => e.code, 'code', code));

void main() {
  late Directory dir;
  late RaindropChannel client;
  late UsersApi users;
  late E2eeApi api;
  late Uint8List serverKey;

  setUpAll(() async {
    if (_skip != null) return;
    await RustLib.init(
      externalLibrary: ExternalLibrary.open(File(_library).absolute.path),
    );
    final parts = _server!.split(':');
    client = RaindropChannel.forServer(host: parts[0], port: int.parse(parts[1]));
    users = UsersApi(client);
    api = E2eeApi(client);
    serverKey = (await users.serverInfo()).identityKey!;
  });
  setUp(() => dir = Directory.systemTemp.createTempSync('raindrop_identity'));
  tearDown(() => dir.deleteSync(recursive: true));

  var stores = 0;
  Future<MlsCryptoEngine> engine() => MlsCryptoEngine.open(
    path: '${dir.path}/device-${stores++}.db',
    key: Uint8List(32)..fillRange(0, 32, stores),
  );

  String name(String base) => '$base${DateTime.now().microsecondsSinceEpoch}';

  Future<ClientIdentity> newPerson() async => ClientIdentity(
    root: await IdentityCrypto.newRoot(),
    recoverySeed: (await IdentityCrypto.newRecoveryKey()).seed,
  );

  Future<SessionResult> signIn(
    MlsCryptoEngine device,
    ClientIdentity identity, {
    String? username,
    String? code,
  }) => signInWithDevice(
    api: users,
    engine: device,
    identity: identity,
    serverKey: serverKey,
    username: username,
    typedCode: code,
  );

  test('a person signs in from two devices with no password', () async {
    final alice = await newPerson();
    final accountId = await IdentityCrypto.accountId(alice.root, serverKey);
    expect((await users.status(accountId)).state, 'unregistered');

    // The first device makes the account.
    final phone = await engine();
    final username = name('alice');
    final first = await signIn(phone, alice, username: username);
    expect(first.user.userId, accountId);
    expect(first.user.username, username);

    // Its session is bound from the start: it may store the vault at once.
    final lookupId = await IdentityCrypto.lookupId(alice.recoverySeed, serverKey);
    await api.putVault(
      first.token,
      lookupId: lookupId,
      sealedRoot: await IdentityCrypto.sealRoot(
        seed: alice.recoverySeed,
        serverKey: serverKey,
        root: alice.root,
      ),
      vault: await IdentityCrypto.sealVault(
        root: alice.root,
        serverKey: serverKey,
        plaintext: Uint8List.fromList(utf8.encode('servers')),
      ),
    );

    // A lapsed session is simply signed in again; nothing is asked.
    await users.logout(first.token);
    await expectLater(users.me(first.token), _apiError('invalid_session'));
    final again = await signIn(phone, alice);
    expect((await users.me(again.token)).userId, accountId);

    // A second device holds the same root and nothing else of the first.
    final laptop = await engine();
    final second = await signIn(laptop, alice);
    expect(second.user.userId, accountId);
    expect((await laptop.device())!.deviceId, isNot((await phone.device())!.deviceId));
    expect((await users.me(again.token)).userId, accountId); // both stay in

    final devices = await api.listDevices(second.token, [accountId]);
    expect(devices.single.devices, hasLength(2));

    // The laptop reads the vault the phone sealed.
    final stored = (await api.getVault(second.token))!;
    expect(stored.lookupId, lookupId);
    expect(
      utf8.decode(
        await IdentityCrypto.openVault(
          root: alice.root,
          serverKey: serverKey,
          blob: stored.vault,
        ),
      ),
      'servers',
    );

    // Somebody else's root is a different account, and cannot join this one.
    final mallory = await newPerson();
    expect(
      await IdentityCrypto.accountId(mallory.root, serverKey),
      isNot(accountId),
    );
  }, skip: _skip);

  test('recovery words bring the identity back, and the authenticator guards it', () async {
    final recovery = await IdentityCrypto.newRecoveryKey();
    final bob = ClientIdentity(
      root: await IdentityCrypto.newRoot(),
      recoverySeed: recovery.seed,
    );
    final phone = await engine();
    final session = await signIn(phone, bob, username: name('bob'));
    await api.putVault(
      session.token,
      lookupId: await IdentityCrypto.lookupId(bob.recoverySeed, serverKey),
      sealedRoot: await IdentityCrypto.sealRoot(
        seed: bob.recoverySeed,
        serverKey: serverKey,
        root: bob.root,
      ),
      vault: await IdentityCrypto.sealVault(
        root: bob.root,
        serverKey: serverKey,
        plaintext: Uint8List(1),
      ),
    );

    final secret = Totp.newSecret();
    final backupCodes = Totp.newBackupCodes();
    await api.enrollAuthenticator(
      session.token,
      secret: secret,
      code: Totp.code(secret),
      backupCodes: backupCodes,
    );
    expect((await api.authenticatorStatus(session.token)).enabled, isTrue);

    // Every device is lost. A new one has the 24 words and the address.
    final seed = await IdentityCrypto.seedFromWords(recovery.words);
    final sealed = await api.sealedRoot(
      await IdentityCrypto.lookupId(seed, serverKey),
    );
    final root = await IdentityCrypto.openRoot(
      seed: seed,
      serverKey: serverKey,
      blob: sealed,
    );
    expect(root, bob.root);
    final recovered = ClientIdentity(root: root, recoverySeed: seed);

    // The words alone are not the account.
    final tablet = await engine();
    await expectLater(signIn(tablet, recovered), _apiError('authenticator_required'));
    await expectLater(
      signIn(tablet, recovered, code: '000000'),
      _apiError('invalid_authenticator_code'),
    );
    // A backup code stands in for the lost authenticator, once.
    final back = await signIn(tablet, recovered, code: backupCodes.first);
    expect(back.user.userId, session.user.userId);
    expect((await api.authenticatorStatus(back.token)).backupCodesLeft, 9);

    // Wrong words find nothing, and open nothing.
    final wrong = (await IdentityCrypto.newRecoveryKey()).seed;
    await expectLater(
      api.sealedRoot(await IdentityCrypto.lookupId(wrong, serverKey)),
      _apiError('vault_not_found'),
    );
    await expectLater(
      IdentityCrypto.openRoot(seed: wrong, serverKey: serverKey, blob: sealed),
      throwsA(
        isA<CryptoException>().having(
          (e) => e.kind,
          'kind',
          CryptoErrorKind.backupLocked,
        ),
      ),
    );

    // A device that was paired holds the secret, and needs nothing typed.
    final paired = ClientIdentity(
      root: bob.root,
      recoverySeed: bob.recoverySeed,
      authenticatorSecret: secret,
    );
    // The enrolment spent the current 30-second step; a paired device waits
    // it out, as the app does by signing in again on the next attempt.
    await Future<void>.delayed(
      Totp.untilNextStep() + const Duration(seconds: 1),
    );
    final laptop = await engine();
    expect((await signIn(laptop, paired)).user.userId, session.user.userId);
  }, timeout: const Timeout(Duration(minutes: 2)), skip: _skip);

  test('a device with no account is paired through the relay', () async {
    final carol = await newPerson();
    final phone = await engine();
    final session = await signIn(phone, carol, username: name('carol'));

    // The new device knows nothing but the server's address.
    final begun = await IdentityCrypto.beginPairing(
      deviceName: "Carol's laptop",
      platform: 'macos',
    );
    final started = await api.startPairing(begun.offer);
    expect(await api.takePairingApproval(started.pairingId, started.takeToken), isNull);

    // The phone takes the code, checks who is asking, and seals the identity.
    final offer = await api.pairingOffer(session.token, started.pairingId);
    final asking = await IdentityCrypto.readPairingOffer(offer, begun.commitment);
    expect(asking.deviceName, "Carol's laptop");
    await expectLater(
      IdentityCrypto.readPairingOffer(offer, Uint8List(16)),
      throwsA(isA<CryptoException>()),
    );
    await api.approvePairing(
      session.token,
      started.pairingId,
      await IdentityCrypto.approvePairing(
        offer: offer,
        commitment: begun.commitment,
        payload: carol.root,
      ),
    );

    // The laptop collects it, once, and is now Carol too.
    final approval = (await api.takePairingApproval(
      started.pairingId,
      started.takeToken,
    ))!;
    expect(await api.takePairingApproval(started.pairingId, started.takeToken), isNull);
    final root = await IdentityCrypto.completePairing(
      approval: approval,
      offer: begun.offer,
      exchangeSecret: begun.exchangeSecret,
    );
    expect(root, carol.root);

    final laptop = await engine();
    final paired = await signIn(
      laptop,
      ClientIdentity(root: root, recoverySeed: carol.recoverySeed),
    );
    expect(paired.user.userId, session.user.userId);
  }, skip: _skip);
}
