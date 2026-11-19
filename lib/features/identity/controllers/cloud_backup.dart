import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/cloud_backup_store.dart';
import '../../../core/storage/identity_store.dart';
import '../models/identity_backup.dart';
import 'identity_controller.dart';
import 'vault_sync.dart';

/// Where the person's platform-synced backup stands on this device.
enum CloudBackupStatus {
  /// Windows and Linux: there is nowhere to keep one.
  unsupported,

  /// None is kept.
  off,

  /// This identity is kept, and follows the person to a new device.
  on,

  /// A different identity is kept there — an older one, or somebody else's
  /// who uses the same account. Turning the backup on replaces it.
  otherIdentity,

  /// Android, with no screen lock: Block Store would not encrypt it end to
  /// end, so nothing is kept until there is one.
  needsScreenLock,

  /// The platform refused: iCloud Keychain off, or a build that is not
  /// allowed to sync keychain items.
  unavailable,
}

@immutable
class CloudBackupState {
  const CloudBackupState(this.status, {this.storeName = '', this.problem});

  final CloudBackupStatus status;

  /// "iCloud Keychain", "your Google Account".
  final String storeName;

  /// What the platform said, when it refused.
  final String? problem;
}

/// The platform's backup store, or null where there is none. A provider so
/// tests can put a fake in its place.
final cloudBackupStoreProvider = Provider<CloudBackupStore?>(
  (ref) => CloudBackupStore.forThisDevice(),
);

/// The opt-in copy of the identity in iCloud Keychain or Google's Block
/// Store (see [CloudBackupStore] and [IdentityBackup]). With it, a new phone
/// or computer signed in to the same Apple or Google account gets the
/// identity back with no recovery words — as safe as that account is, which
/// is why it is the person's choice and off until they make it.
final cloudBackupProvider =
    AsyncNotifierProvider<CloudBackupController, CloudBackupState>(
      CloudBackupController.new,
    );

class CloudBackupController extends AsyncNotifier<CloudBackupState> {
  CloudBackupStore? get _store => ref.read(cloudBackupStoreProvider);

  @override
  Future<CloudBackupState> build() async {
    final store = _store;
    if (store == null) {
      return const CloudBackupState(CloudBackupStatus.unsupported);
    }
    final identity = await ref.watch(identityProvider.future);
    try {
      final stored = await _read(store);
      if (stored == null) return _state(store, CloudBackupStatus.off);
      if (identity != null && listEquals(stored.root, identity.root)) {
        return _state(store, CloudBackupStatus.on);
      }
      return _state(store, CloudBackupStatus.otherIdentity);
    } on Exception catch (e) {
      return _state(store, CloudBackupStatus.unavailable, problem: _say(e));
    }
  }

  /// Keeps this identity in the platform's backup, replacing whatever was
  /// there. On Android without a screen lock nothing is written.
  Future<void> enable() async {
    final store = _store;
    if (store == null) return;
    try {
      if (!await store.isEncrypted()) {
        state = AsyncData(_state(store, CloudBackupStatus.needsScreenLock));
        return;
      }
      final payload = await _payload();
      if (payload == null) return;
      await store.write(payload.toBytes());
      state = AsyncData(_state(store, CloudBackupStatus.on));
    } on Exception catch (e) {
      state = AsyncData(
        _state(store, CloudBackupStatus.unavailable, problem: _say(e)),
      );
    }
  }

  /// Deletes the backup, here and — at the platform's next sync — from the
  /// cloud and the person's other devices.
  Future<void> disable() async {
    final store = _store;
    if (store == null) return;
    try {
      await store.delete();
      state = AsyncData(_state(store, CloudBackupStatus.off));
    } on Exception catch (e) {
      state = AsyncData(
        _state(store, CloudBackupStatus.unavailable, problem: _say(e)),
      );
    }
  }

  /// Brings a backup that is on up to date: new recovery words, servers
  /// joined since. Writes only when something changed. On an Android phone
  /// whose screen lock was removed, the backup is deleted rather than left to
  /// be uploaded unencrypted.
  Future<void> refresh() async {
    final current = await future;
    final store = _store;
    if (store == null || current.status != CloudBackupStatus.on) return;
    try {
      if (!await store.isEncrypted()) {
        await store.delete();
        state = AsyncData(_state(store, CloudBackupStatus.needsScreenLock));
        return;
      }
      final payload = await _payload();
      if (payload == null) return;
      final bytes = payload.toBytes();
      if (listEquals(await store.read(), bytes)) return;
      await store.write(bytes);
    } on Exception catch (e) {
      debugPrint('cloud backup: could not refresh: ${_say(e)}');
    }
  }

  Future<IdentityBackup?> _payload() async {
    final identity = await ref.read(identityProvider.future);
    if (identity == null) return null;
    return IdentityBackup(
      root: identity.root,
      recoverySeed: identity.recoverySeed,
      servers: (await ref.read(vaultProvider.notifier).current()).servers.values
          .toList(),
    );
  }

  static Future<IdentityBackup?> _read(CloudBackupStore store) async {
    final bytes = await store.read();
    return bytes == null ? null : IdentityBackup.tryFromBytes(bytes);
  }

  /// What the platform said: a [PlatformException]'s message, or a missing
  /// plugin (a test, or a build without the native half).
  static String? _say(Exception e) =>
      e is PlatformException ? e.message : e.toString();

  static CloudBackupState _state(
    CloudBackupStore store,
    CloudBackupStatus status, {
    String? problem,
  }) => CloudBackupState(status, storeName: store.name, problem: problem);
}

/// A backup a fresh install could restore the identity from: what the
/// welcome screen offers first when there is one. Null when there is none,
/// or the platform has nowhere to keep one.
final restorableBackupProvider =
    FutureProvider<({String storeName, IdentityBackup backup})?>((ref) async {
      final store = ref.watch(cloudBackupStoreProvider);
      if (store == null) return null;
      try {
        final backup = await CloudBackupController._read(store);
        return backup == null ? null : (storeName: store.name, backup: backup);
      } on Exception catch (e) {
        debugPrint(
          'cloud backup: could not look for one: ${CloudBackupController._say(e)}',
        );
        return null;
      }
    });

/// Makes [backup]'s identity this device's, and adds the servers it lists —
/// their vaults bring the rest. Like recovering with the words, it brings no
/// authenticator: a server that has one asks for a code, a backup code or
/// the wait.
Future<void> restoreFromBackup(WidgetRef ref, IdentityBackup backup) async {
  final identity = ClientIdentity(
    root: backup.root,
    recoverySeed: backup.recoverySeed,
  );
  await ref.read(identityProvider.notifier).adopt(identity);
  await ref.read(vaultProvider.notifier).adoptServers(backup.vault, identity);
}
