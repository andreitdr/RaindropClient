// The opt-in copy of the identity in iCloud Keychain or Google's Block
// Store: what it holds, when it is written, and what a fresh install offers.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/storage/app_prefs.dart';
import 'package:raindrop_client/core/storage/cloud_backup_store.dart';
import 'package:raindrop_client/core/storage/identity_store.dart';
import 'package:raindrop_client/core/theme/theme_controller.dart';
import 'package:raindrop_client/features/identity/controllers/cloud_backup.dart';
import 'package:raindrop_client/features/identity/controllers/identity_controller.dart';
import 'package:raindrop_client/features/identity/models/identity_backup.dart';
import 'package:raindrop_client/features/identity/models/vault.dart';
import 'package:raindrop_client/features/identity/screens/welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeStore implements CloudBackupStore {
  Uint8List? bytes;
  bool encrypted = true;
  int writes = 0;

  @override
  String get name => 'the test cloud';

  @override
  Future<bool> isEncrypted() async => encrypted;

  @override
  Future<Uint8List?> read() async => bytes;

  @override
  Future<void> write(Uint8List value) async {
    writes++;
    bytes = value;
  }

  @override
  Future<void> delete() async => bytes = null;
}

Uint8List _filled(int value, [int length = 32]) =>
    Uint8List(length)..fillRange(0, length, value);

VaultServer _server(int i) => VaultServer(
  host: 'server$i.example',
  port: 5001,
  displayName: 'Server $i',
  fingerprint: 'AB' * 32,
  identityKey: _filled(i, 65),
  updatedAtMs: i,
);

void main() {
  group('IdentityBackup', () {
    test('round-trips the identity and its servers', () {
      final backup = IdentityBackup(
        root: _filled(1),
        recoverySeed: _filled(2),
        servers: [_server(1), _server(2)],
      );
      final read = IdentityBackup.tryFromBytes(backup.toBytes())!;
      expect(read.root, backup.root);
      expect(read.recoverySeed, backup.recoverySeed);
      expect(read.vault.servers.keys, {'server1.example:5001', 'server2.example:5001'});
    });

    test('fits Block Store by keeping the most recently changed servers', () {
      final backup = IdentityBackup(
        root: _filled(1),
        recoverySeed: _filled(2),
        servers: [for (var i = 1; i <= 60; i++) _server(i)],
      );
      final bytes = backup.toBytes();
      expect(bytes.length, lessThanOrEqualTo(IdentityBackup.maximumBytes));
      final kept = IdentityBackup.tryFromBytes(bytes)!.servers;
      expect(kept, isNotEmpty);
      expect(kept.length, lessThan(60));
      expect(kept.first.host, 'server60.example');
    });

    test('anything else is not a backup', () {
      expect(IdentityBackup.tryFromBytes(Uint8List.fromList([9, 1, 2])), isNull);
      expect(IdentityBackup.tryFromBytes(Uint8List(0)), isNull);
    });
  });

  group('the cloud backup', () {
    late _FakeStore store;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      await const IdentityStore().write(
        ClientIdentity(root: _filled(1), recoverySeed: _filled(2)),
      );
      store = _FakeStore();
      container = ProviderContainer(
        overrides: [
          appPrefsProvider.overrideWithValue(
            AppPrefs(await SharedPreferences.getInstance()),
          ),
          cloudBackupStoreProvider.overrideWithValue(store),
        ],
      );
    });
    tearDown(() => container.dispose());

    Future<CloudBackupStatus> status() async =>
        (await container.read(cloudBackupProvider.future)).status;

    test('is off until the person turns it on, and then holds this identity', () async {
      expect(await status(), CloudBackupStatus.off);

      await container.read(cloudBackupProvider.notifier).enable();
      expect(await status(), CloudBackupStatus.on);
      final kept = IdentityBackup.tryFromBytes(store.bytes!)!;
      expect(kept.root, _filled(1));
      expect(kept.recoverySeed, _filled(2));

      await container.read(cloudBackupProvider.notifier).disable();
      expect(store.bytes, isNull);
      expect(await status(), CloudBackupStatus.off);
    });

    test('says when it holds somebody else', () async {
      store.bytes = IdentityBackup(root: _filled(7), recoverySeed: _filled(8)).toBytes();
      expect(await status(), CloudBackupStatus.otherIdentity);
    });

    test('writes nothing a phone without a screen lock would upload in the clear', () async {
      store.encrypted = false;
      await container.read(cloudBackupProvider.notifier).enable();
      expect(store.bytes, isNull);
      expect(await status(), CloudBackupStatus.needsScreenLock);
    });

    test('follows new recovery words, and only writes what changed', () async {
      await container.read(cloudBackupProvider.notifier).enable();
      await container.read(cloudBackupProvider.notifier).refresh();
      expect(store.writes, 1);

      await const IdentityStore().write(
        ClientIdentity(root: _filled(1), recoverySeed: _filled(3)),
      );
      // As IdentityController.newRecoveryKey leaves it.
      container.invalidate(identityProvider);
      await container.read(cloudBackupProvider.notifier).refresh();
      expect(store.writes, 2);
      expect(IdentityBackup.tryFromBytes(store.bytes!)!.recoverySeed, _filled(3));
    });

    test('is taken back when the screen lock goes', () async {
      await container.read(cloudBackupProvider.notifier).enable();
      store.encrypted = false;
      await container.read(cloudBackupProvider.notifier).refresh();
      expect(store.bytes, isNull);
      expect(await status(), CloudBackupStatus.needsScreenLock);
    });
  });

  testWidgets('a fresh install with a backup offers to restore it first', (tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final store = _FakeStore()
      ..bytes = IdentityBackup(root: _filled(1), recoverySeed: _filled(2)).toBytes();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPrefsProvider.overrideWithValue(
            AppPrefs(await SharedPreferences.getInstance()),
          ),
          cloudBackupStoreProvider.overrideWithValue(store),
        ],
        child: const MaterialApp(home: WelcomeScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Restore from the test cloud'), findsOneWidget);
    expect(find.text("I'm new to Raindrop"), findsOneWidget);
  });
}
