// The last way back: someone who lost every device, the recovery words and
// any backup takes their account over with a new identity and a claim code
// the server's owner issues from its console.
//
// Needs a live server whose console this test can type into and whose output
// it can read:
//
//   tail -f <commands> | dotnet ServerCli.dll > <log>
//
// with RAINDROP_TEST_SERVER, RAINDROP_TEST_CONSOLE=<commands> and
// RAINDROP_TEST_CONSOLE_LOG=<log>. Skipped otherwise.
import 'dart:io';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/crypto/bridge/frb_generated.dart';
import 'package:raindrop_client/core/crypto/identity_crypto.dart';
import 'package:raindrop_client/core/crypto/mls_crypto_engine.dart';
import 'package:raindrop_client/core/network/api_exception.dart';
import 'package:raindrop_client/core/network/e2ee_api.dart';
import 'package:raindrop_client/core/network/raindrop_channel.dart';
import 'package:raindrop_client/core/network/users_api.dart';
import 'package:raindrop_client/core/storage/identity_store.dart';
import 'package:raindrop_client/features/identity/device_sign_in.dart';
import 'package:raindrop_client/features/onboarding/models/claim_code.dart';

const _library = '../RaindropCrypto/target/debug/libraindrop_crypto_ffi.dylib';
final _server = Platform.environment['RAINDROP_TEST_SERVER'];
final _console = Platform.environment['RAINDROP_TEST_CONSOLE'];
final _log = Platform.environment['RAINDROP_TEST_CONSOLE_LOG'];
final _skip = _server == null || _console == null || _log == null
    ? 'set RAINDROP_TEST_SERVER, RAINDROP_TEST_CONSOLE and RAINDROP_TEST_CONSOLE_LOG'
    : !File(_library).existsSync()
    ? 'build RaindropCrypto first'
    : null;

void main() {
  late Directory dir;
  late UsersApi users;
  late E2eeApi api;
  late Uint8List serverKey;

  setUpAll(() async {
    if (_skip != null) return;
    await RustLib.init(externalLibrary: ExternalLibrary.open(File(_library).absolute.path));
    final parts = _server!.split(':');
    final client = RaindropChannel.forServer(host: parts[0], port: int.parse(parts[1]));
    users = UsersApi(client);
    api = E2eeApi(client);
    serverKey = (await users.serverInfo()).identityKey!;
  });
  setUp(() => dir = Directory.systemTemp.createTempSync('raindrop_reclaim'));
  tearDown(() => dir.deleteSync(recursive: true));

  var stores = 0;
  Future<MlsCryptoEngine> engine() => MlsCryptoEngine.open(
    path: '${dir.path}/device-${stores++}.db',
    key: Uint8List(32)..fillRange(0, 32, stores),
  );

  Future<ClientIdentity> newPerson() async => ClientIdentity(
    root: await IdentityCrypto.newRoot(),
    recoverySeed: (await IdentityCrypto.newRecoveryKey()).seed,
  );

  /// Types `reclaim <username>` and `yes` into the server's console, and
  /// reads the code it prints.
  Future<ClaimCode> issueClaim(String username) async {
    final log = File(_log!);
    final before = log.readAsStringSync().length;
    File(_console!).writeAsStringSync('reclaim $username\nyes\n', mode: FileMode.append, flush: true);
    for (var i = 0; i < 100; i++) {
      final printed = log.readAsStringSync().substring(before);
      final match = RegExp(r'RDC1-[0-9a-f-]{36}-[0-9a-f]{32}').firstMatch(printed);
      if (match != null) return ClaimCode.tryParse(match.group(0)!)!;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throw StateError('The console printed no claim code.');
  }

  test('a new identity takes the account back with the owner\'s claim code', () async {
    // Erin's account, on a phone she then loses with everything else.
    final erin = await newPerson();
    final username = 'erin${DateTime.now().microsecondsSinceEpoch}';
    final phone = await engine();
    final before = await signInWithDevice(
      api: users,
      engine: phone,
      identity: erin,
      serverKey: serverKey,
      username: username,
    );
    final accountId = before.user.userId;

    // A new identity cannot simply sign in to it.
    final reborn = await newPerson();
    final laptop = await engine();
    await expectLater(
      signInWithDevice(
        api: users,
        engine: laptop,
        identity: reborn,
        serverKey: serverKey,
        accountId: accountId,
      ),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'identity_mismatch')),
    );

    // With the owner's code it can: same account, same name, new identity.
    final claim = await issueClaim(username);
    expect(claim.accountId, accountId);
    final after = await signInWithDevice(
      api: users,
      engine: laptop,
      identity: reborn,
      serverKey: serverKey,
      accountId: claim.accountId,
      claimCode: claim.text,
    );
    expect(after.user.userId, accountId);
    expect(after.user.username, username);

    // The code is spent, and the lost phone is out: its session and its key.
    final again = await engine();
    await expectLater(
      signInWithDevice(
        api: users,
        engine: again,
        identity: reborn,
        serverKey: serverKey,
        accountId: accountId,
        claimCode: claim.text,
      ),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'invalid_claim')),
    );
    await expectLater(users.me(before.token), throwsA(isA<ApiException>()));
    await expectLater(
      signInWithDevice(api: users, engine: phone, identity: erin, serverKey: serverKey),
      throwsA(isA<ApiException>()),
    );

    // The new identity's next device joins by its certificate, like any.
    final tablet = await engine();
    final third = await signInWithDevice(
      api: users,
      engine: tablet,
      identity: reborn,
      serverKey: serverKey,
      accountId: accountId,
    );
    expect(third.user.userId, accountId);
    final devices = await api.listDevices(third.token, [accountId]);
    expect(devices.single.devices, hasLength(2));
  }, skip: _skip);
}
