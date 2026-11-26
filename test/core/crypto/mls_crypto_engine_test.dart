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
import 'package:raindrop_client/core/crypto/identity_crypto.dart';
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
    final bobsKey = (await bob.device())!.userIdentityKey;
    final impostorsKey = (await impostor.device())!.userIdentityKey;
    await expectLater(
      alice.addMembers(channel, await impostor.generateKeyPackages(1)),
      throwsA(
        isA<CryptoException>()
            .having((e) => e.kind, 'kind', CryptoErrorKind.identityChanged)
            .having((e) => e.userId, 'userId', 'bob')
            // Both keys, so the person can compare them.
            .having((e) => e.pinnedKey, 'pinnedKey', bobsKey)
            .having((e) => e.presentedKey, 'presentedKey', impostorsKey),
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

  test('a refused join is listed as pending, and accepting the presented key '
      'clears it and lets the join through', () async {
    final alice = await engine('alice4', 21);
    await alice.createIdentity(userId: 'alice', deviceId: 'a1');
    await alice.createGroup(channel);
    final bob = await engine('bob4', 22);
    await bob.createIdentity(userId: 'bob', deviceId: 'b1');
    final commit = await alice.addMembers(
      channel,
      await bob.generateKeyPackages(1),
    );
    await alice.mergePendingCommit(channel);
    await bob.joinFromWelcome(commit.welcome!);
    final bobsKey = (await bob.device())!.userIdentityKey;

    // Carol already trusts another key for bob.
    final carol = await engine('carol4', 23);
    await carol.createIdentity(userId: 'carol', deviceId: 'c1');
    final oldKey = Uint8List(32)..fillRange(0, 32, 7);
    await carol.importPins([
      PinnedUser(userId: 'bob', identityKey: oldKey, verified: false),
    ]);
    expect(await carol.pendingIdentityChanges(), isEmpty);

    final info = await alice.groupInfo(channel);
    CryptoException? refused;
    try {
      await carol.joinByExternalCommit(channel, info);
    } on CryptoException catch (e) {
      refused = e;
    }
    expect(refused?.kind, CryptoErrorKind.identityChanged);
    expect(refused?.presentedKey, bobsKey);

    final pending = await carol.pendingIdentityChanges();
    expect(pending, hasLength(1));
    expect(pending.single.userId, 'bob');
    expect(pending.single.pinnedKey, oldKey);
    expect(pending.single.presentedKey, bobsKey);
    expect(pending.single.leftGroupIds, [channel]);
    expect(pending.single.leftChannelIds, {
      '6f1c2d3e-4a5b-4c6d-8e7f-001122334455',
    });

    await carol.acceptChangedIdentity('bob', bobsKey);
    expect(await carol.pendingIdentityChanges(), isEmpty);
    await carol.joinByExternalCommit(channel, info);
    expect(await carol.hasGroup(channel), isTrue);
  }, skip: library == null ? 'build RaindropCrypto first' : false);

  test(
    'an external join is for the channel asked, and merged at once',
    () async {
      final alice = await engine('alice3', 11);
      await alice.createIdentity(userId: 'alice', deviceId: 'a1');
      await alice.createGroup(channel);
      final carol = await engine('carol3', 12);
      await carol.createIdentity(userId: 'carol', deviceId: 'c1');
      final info = await alice.groupInfo(channel);

      // A group info for another channel is refused and nothing is stored.
      final other = groupIdForChannel('00112233-4455-6677-8899-aabbccddeeff');
      await expectLater(
        carol.joinByExternalCommit(other, info),
        throwsA(
          isA<CryptoException>().having(
            (e) => e.kind,
            'kind',
            CryptoErrorKind.verification,
          ),
        ),
      );
      expect(await carol.hasGroup(channel), isFalse);
      expect(await carol.hasGroup(other), isFalse);

      final join = await carol.joinByExternalCommit(channel, info);
      expect(join.groupId, channel);
      expect(join.commit.epochAfter, await carol.epoch(channel));

      // A group this device already holds is never replaced.
      await expectLater(
        carol.joinByExternalCommit(channel, info),
        throwsA(isA<CryptoException>()),
      );
      expect(await carol.epoch(channel), join.commit.epochAfter);

      alice.dispose();
      carol.dispose();
    },
    skip: library == null ? 'build RaindropCrypto first' : false,
  );

  test('a link approval opens only with the code secret', () async {
    final laptop = await engine('laptop', 8);
    await laptop.createIdentity(userId: 'alice', deviceId: 'a1');
    // The server's own identity for the same user; it has the phone's offer
    // but never the code secret.
    final server = await engine('server', 9);
    await server.createIdentity(userId: 'alice', deviceId: 'forged');
    final phone = await engine('phone', 10);

    final offer = await phone.beginDeviceLink(userId: 'alice', deviceId: 'a2');
    final code = DeviceLinkCode.tryParse(
      DeviceLinkCode(
        linkId: 'LINK',
        commitment: offer.commitment,
        codeSecret: offer.codeSecret,
      ).toString(),
    )!;

    final forged = await server.approveDeviceLink(
      offer.offer,
      offer.commitment,
      Uint8List(16),
    );
    await expectLater(
      phone.completeDeviceLink(forged),
      throwsA(
        isA<CryptoException>().having(
          (e) => e.kind,
          'kind',
          CryptoErrorKind.verification,
        ),
      ),
    );

    final approval = await laptop.approveDeviceLink(
      offer.offer,
      code.commitment,
      code.codeSecret,
    );
    final keys = await phone.completeDeviceLink(approval);
    expect(keys.userIdentityKey, (await laptop.device())!.userIdentityKey);

    laptop.dispose();
    server.dispose();
    phone.dispose();
  }, skip: library == null ? 'build RaindropCrypto first' : false);

  test('a pairing approval opens only with the code secret', () async {
    final begun = await IdentityCrypto.beginPairing(
      deviceName: 'Desk',
      platform: 'linux',
    );
    expect(begun.codeSecret, hasLength(16));

    // A relay holds the offer, so it can seal to it; not to the code secret.
    final forged = await IdentityCrypto.approvePairing(
      offer: begun.offer,
      commitment: begun.commitment,
      codeSecret: Uint8List(16),
      payload: _bytes('evil'),
    );
    await expectLater(
      IdentityCrypto.completePairing(
        approval: forged,
        offer: begun.offer,
        exchangeSecret: begun.exchangeSecret,
        codeSecret: begun.codeSecret,
      ),
      throwsA(
        isA<CryptoException>().having(
          (e) => e.kind,
          'kind',
          CryptoErrorKind.verification,
        ),
      ),
    );

    final approval = await IdentityCrypto.approvePairing(
      offer: begun.offer,
      commitment: begun.commitment,
      codeSecret: begun.codeSecret,
      payload: _bytes('the root'),
    );
    expect(
      await IdentityCrypto.completePairing(
        approval: approval,
        offer: begun.offer,
        exchangeSecret: begun.exchangeSecret,
        codeSecret: begun.codeSecret,
      ),
      _bytes('the root'),
    );
  }, skip: library == null ? 'build RaindropCrypto first' : false);

  test('an own commit this device discarded is resyncRequired', () async {
    final alice = await engine('alice3', 8);
    await alice.createIdentity(userId: 'alice', deviceId: 'a1');
    await alice.createGroup(channel);
    final before = await alice.epoch(channel);

    // The server kept the commit but answered with an error, so it was
    // discarded; its echo must not leave this device silently behind.
    final discarded = await alice.selfUpdate(channel);
    await alice.discardPendingCommit(channel);
    await expectLater(
      alice.process(discarded.commit),
      throwsA(
        isA<CryptoException>().having(
          (e) => e.kind,
          'kind',
          CryptoErrorKind.resyncRequired,
        ),
      ),
    );
    expect(await alice.epoch(channel), before);

    // The echo of the commit still pending merges as before.
    final pending = await alice.selfUpdate(channel);
    expect(
      await alice.process(pending.commit),
      isA<GroupMembershipChanged>().having(
        (e) => e.epoch,
        'epoch',
        pending.epochAfter,
      ),
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

  test('a group id names its channel again, and only a channel\'s', () {
    const channel = '00112233-4455-6677-8899-aabbccddeeff';
    expect(channelIdForGroup(groupIdForChannel(channel)), channel);
    expect(channelIdForGroup(Uint8List.fromList([1, 2, 3])), isNull);
  });

  test('a later generation of a channel\'s group has an id of its own', () {
    const id = '00112233-4455-6677-8899-aabbccddeeff';
    final first = groupIdForChannel(id);
    // Generation 0 is the id every group always had: the server's
    // MlsFraming.GroupIdFor(channel, 0).
    expect(groupIdForChannel(id, 0), first);
    final third = groupIdForChannel(id, 3);
    expect(third.length, 24);
    expect(third.sublist(0, 16), first);
    expect(third.sublist(16), [0, 0, 0, 0, 0, 0, 0, 3]);
    expect(groupIdForChannel(id, 0x0102030405).sublist(16), [
      0,
      0,
      0,
      1,
      2,
      3,
      4,
      5,
    ]);
    expect(channelIdForGroup(third), id);
    expect(() => groupIdForChannel(id, -1), throwsArgumentError);
  });

  test(
    'a later generation is a group of its own through the real core: '
    'joined by external commit, its predecessor reset with its history '
    'kept, and a commit nobody can decrypt leaves the group as it was',
    () async {
      final alice = await engine('alice-gen', 7);
      final bob = await engine('bob-gen', 8);
      await alice.createIdentity(userId: 'alice', deviceId: 'a1');
      await bob.createIdentity(userId: 'bob', deviceId: 'b1');
      final next = groupIdForChannel('6f1c2d3e-4a5b-4c6d-8e7f-001122334455', 1);

      // Generation 0, with a message bob has read.
      await alice.createGroup(channel);
      final add = await alice.addMembers(
        channel,
        await bob.generateKeyPackages(1),
      );
      await alice.mergePendingCommit(channel);
      await bob.joinFromWelcome(add.welcome!);
      final old = await alice.encrypt(channel, _bytes('from generation 0'));
      await bob.receiveMessage(
        messageId: 'm0',
        sentAt: DateTime.utc(2026),
        message: old,
      );

      // Generation 1: a new group, which bob joins by himself.
      await alice.createGroup(next);
      final join = await bob.joinByExternalCommit(
        next,
        await alice.groupInfo(next),
      );
      expect(join.groupId, next);
      await bob.mergePendingCommit(next);
      await alice.process(join.commit.commit);
      final fresh = await alice.encrypt(next, _bytes('from generation 1'));
      final received = await bob.receiveMessage(
        messageId: 'm1',
        sentAt: DateTime.utc(2026),
        message: fresh,
      );
      expect(utf8.decode(received!.payload), 'from generation 1');

      // Leaving generation 0 behind keeps what was read in it.
      await bob.resetGroup(channel);
      expect(await bob.hasGroup(channel), isFalse);
      expect((await bob.cachedMessages(channel)).single.messageId, 'm0');
      expect(
        utf8.decode(
          (await bob.receiveMessage(
            messageId: 'm0',
            sentAt: DateTime.utc(2026),
            message: old,
          ))!.payload,
        ),
        'from generation 0',
      );

      // A commit whose framing is right and whose contents are not: refused,
      // and the group is still there at the same epoch — which is why a client
      // that meets one is stuck until the group is replaced.
      final epoch = await bob.epoch(next);
      final commit = await alice.selfUpdate(next);
      final garbage = Uint8List.fromList(commit.commit);
      for (var i = garbage.length - 16; i < garbage.length; i++) {
        garbage[i] ^= 0xff;
      }
      await expectLater(
        bob.process(garbage),
        throwsA(
          isA<CryptoException>().having(
            (e) => e.kind,
            'kind',
            isNot(
              anyOf(
                CryptoErrorKind.identityChanged,
                CryptoErrorKind.resyncRequired,
              ),
            ),
          ),
        ),
      );
      expect(await bob.hasGroup(next), isTrue);
      expect(await bob.epoch(next), epoch);

      alice.dispose();
      bob.dispose();
    },
    skip: library == null ? 'build RaindropCrypto first' : false,
  );
}
