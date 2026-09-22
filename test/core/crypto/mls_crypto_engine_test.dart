// Exercises MlsCryptoEngine through the real Rust library, so a mismatch
// between the generated bridge and the crate shows up here rather than in the
// app. Needs the library built first:
//
//   cd ../RaindropCrypto && cargo build -p raindrop_crypto_ffi
//
// and skips itself when it is not there.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/crypto/bridge/frb_generated.dart';
import 'package:raindrop_client/core/crypto/crypto_engine.dart';
import 'package:raindrop_client/core/crypto/mls_crypto_engine.dart';

String? _library() {
  const base = '../RaindropCrypto/target/debug/';
  for (final name in [
    'libraindrop_crypto_ffi.dylib',
    'libraindrop_crypto_ffi.so',
    'raindrop_crypto_ffi.dll',
  ]) {
    if (File('$base$name').existsSync()) {
      return File('$base$name').absolute.path;
    }
  }
  return null;
}

Uint8List _bytes(String s) => Uint8List.fromList(utf8.encode(s));

void main() {
  final library = _library();
  late Directory dir;

  setUpAll(() async {
    if (library != null) {
      await RustLib.init(externalLibrary: ExternalLibrary.open(library));
    }
  });
  setUp(() => dir = Directory.systemTemp.createTempSync('raindrop_crypto'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<MlsCryptoEngine> engine(String name, int keyByte) =>
      MlsCryptoEngine.open(
        path: '${dir.path}/$name.db',
        key: Uint8List(32)..fillRange(0, 32, keyByte),
      );

  final channel = groupIdForChannel('6f1c2d3e-4a5b-4c6d-8e7f-001122334455');

  test('two engines talk through the real bridge', () async {
    final alice = await engine('alice', 1);
    final bob = await engine('bob', 2);
    await alice.createIdentity(userId: 'alice', deviceId: 'a1');
    await bob.createIdentity(userId: 'bob', deviceId: 'b1');

    await alice.createGroup(channel);
    final commit = await alice.addMembers(
      channel,
      await bob.generateKeyPackages(1),
    );
    await alice.mergePendingCommit(channel);
    expect(await bob.joinFromWelcome(commit.welcome!), channel);

    final ciphertext = await alice.encrypt(channel, _bytes('hello over ffi'));
    final received = await bob.receiveMessage(
      messageId: 'm1',
      sentAt: DateTime.utc(2026),
      message: ciphertext,
    );
    expect(utf8.decode(received!.payload), 'hello over ffi');
    expect(received.senderUserId, 'alice');
    expect((await bob.cachedMessages(channel)).single.messageId, 'm1');

    final aliceKey = await alice.exportSecret(
      channel,
      label: 'raindrop/voice/v1',
      context: channel,
    );
    expect(
      await bob.exportSecret(
        channel,
        label: 'raindrop/voice/v1',
        context: channel,
      ),
      aliceKey,
    );

    alice.dispose();
    bob.dispose();
  }, skip: library == null ? 'build RaindropCrypto first' : false);

  test('errors arrive as CryptoException', () async {
    final first = await engine('store', 3);
    first.dispose();

    await expectLater(
      MlsCryptoEngine.open(
        path: '${dir.path}/store.db',
        key: Uint8List(32)..fillRange(0, 32, 4),
      ),
      throwsA(
        isA<CryptoException>().having(
          (e) => e.kind,
          'kind',
          CryptoErrorKind.storeLocked,
        ),
      ),
    );

    final alice = await engine('alice2', 5);
    await alice.createIdentity(userId: 'alice', deviceId: 'a1');
    await alice.createGroup(channel);
    final bob = await engine('bob2', 6);
    await bob.createIdentity(userId: 'bob', deviceId: 'b1');
    final commit = await alice.addMembers(
      channel,
      await bob.generateKeyPackages(1),
    );
    await alice.mergePendingCommit(channel);
    await bob.joinFromWelcome(commit.welcome!);

    // A second "bob" with a different identity key is refused.
    final impostor = await engine('impostor', 7);
    await impostor.createIdentity(userId: 'bob', deviceId: 'b2');
    await expectLater(
      alice.addMembers(channel, await impostor.generateKeyPackages(1)),
      throwsA(
        isA<CryptoException>()
            .having((e) => e.kind, 'kind', CryptoErrorKind.identityChanged)
            .having((e) => e.userId, 'userId', 'bob'),
      ),
    );

    final words = (await alice.sealBackupWithRecoveryKey()).recoveryWords!;
    expect(words.split(' '), hasLength(24));
    expect(
      safetyNumber(
        userA: 'alice',
        keyA: (await alice.device())!.userIdentityKey,
        userB: 'bob',
        keyB: (await bob.device())!.userIdentityKey,
      ),
      hasLength(60),
    );
  }, skip: library == null ? 'build RaindropCrypto first' : false);

  test('channel ids become 16-byte group ids', () {
    expect(groupIdForChannel('00112233-4455-6677-8899-aabbccddeeff'), [
      0x00,
      0x11,
      0x22,
      0x33,
      0x44,
      0x55,
      0x66,
      0x77,
      0x88,
      0x99,
      0xaa,
      0xbb,
      0xcc,
      0xdd,
      0xee,
      0xff,
    ]);
    expect(() => groupIdForChannel('nope'), throwsArgumentError);
  });
}
