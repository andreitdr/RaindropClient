import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../platform/platform_info.dart';

/// Where the platform keeps a small secret for the person and brings it to
/// their next phone or computer, end-to-end encrypted: iCloud Keychain on
/// Apple devices, Google's Block Store on Android. Null on Windows and
/// Linux, which have neither.
///
/// One entry, written whole. Turning the backup off deletes it, which also
/// takes it out of the cloud.
abstract class CloudBackupStore {
  /// Where the backup lives, for the person: "iCloud Keychain".
  String get name;

  /// Whether a backup written now would be end-to-end encrypted. False on an
  /// Android phone with no screen lock, where Block Store would keep it in
  /// the clear — so nothing is written there.
  Future<bool> isEncrypted();

  Future<Uint8List?> read();

  Future<void> write(Uint8List bytes);

  Future<void> delete();

  static CloudBackupStore? forThisDevice() => switch (cloudBackupPlatform) {
    CloudBackupPlatform.keychain => const KeychainCloudBackup(),
    CloudBackupPlatform.blockStore => const BlockStoreCloudBackup(),
    null => null,
  };
}

/// A synchronizable keychain item: iCloud Keychain copies it to the
/// person's other Apple devices and to a new one signed in to the same
/// Apple Account, end-to-end encrypted. It is kept apart from the
/// device-only items the identity lives in (`IdentityStore`): the keychain
/// keys synchronizable and local items separately.
class KeychainCloudBackup implements CloudBackupStore {
  const KeychainCloudBackup();

  static const _key = 'raindrop.identity_backup';

  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.unlocked,
      synchronizable: true,
    ),
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.unlocked,
      synchronizable: true,
    ),
  );

  @override
  String get name => 'iCloud Keychain';

  @override
  Future<bool> isEncrypted() async => true;

  @override
  Future<Uint8List?> read() async {
    final value = await _storage.read(key: _key);
    return value == null ? null : base64.decode(value);
  }

  @override
  Future<void> write(Uint8List bytes) =>
      _storage.write(key: _key, value: base64.encode(bytes));

  @override
  Future<void> delete() => _storage.delete(key: _key);
}

/// Google's Block Store, through `MainActivity`'s `raindrop/block_store`
/// channel: backed up to the Google Account with the phone's other data and
/// restored when a new phone is set up from it.
class BlockStoreCloudBackup implements CloudBackupStore {
  const BlockStoreCloudBackup();

  static const _channel = MethodChannel('raindrop/block_store');

  @override
  String get name => 'your Google Account';

  @override
  Future<bool> isEncrypted() async =>
      await _channel.invokeMethod<bool>('isEncrypted') ?? false;

  @override
  Future<Uint8List?> read() => _channel.invokeMethod<Uint8List>('read');

  @override
  Future<void> write(Uint8List bytes) =>
      _channel.invokeMethod<void>('write', {'bytes': bytes});

  @override
  Future<void> delete() => _channel.invokeMethod<void>('delete');
}
