import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The person's identity, as this device holds it.
class ClientIdentity {
  const ClientIdentity({
    required this.root,
    required this.recoverySeed,
    this.authenticatorSecret,
  });

  /// The root secret every server account is derived from. Held by the
  /// person's paired devices and nobody else.
  final Uint8List root;

  /// What this device keeps of the recovery key: enough to seal the root on
  /// a server joined later, not the 24 words themselves.
  final Uint8List recoverySeed;

  /// The authenticator's secret, when the person has set one up. Held here
  /// so this device can add itself to a server without a code being typed.
  /// It is never put in the vault — the vault opens with the recovery words,
  /// and the authenticator is what stands between leaked words and the
  /// account — and reaches a new device over the pairing channel only.
  final Uint8List? authenticatorSecret;

  ClientIdentity copyWith({
    Uint8List? recoverySeed,
    Uint8List? authenticatorSecret,
    bool clearAuthenticator = false,
  }) => ClientIdentity(
    root: root,
    recoverySeed: recoverySeed ?? this.recoverySeed,
    authenticatorSecret: clearAuthenticator
        ? null
        : authenticatorSecret ?? this.authenticatorSecret,
  );
}

/// Where the identity is kept: the platform keystore (Keychain, Keystore,
/// Credential Manager, libsecret), under keys that belong to the app and not
/// to any one server — removing a server never touches them.
class IdentityStore {
  const IdentityStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  static const _rootKey = 'client.root';
  static const _seedKey = 'client.recovery_seed';
  static const _authenticatorKey = 'client.authenticator';
  static const _installKey = 'client.install_id';
  static const _pinLockKey = 'client.pin_lock';

  Future<ClientIdentity?> read() async {
    final root = await _bytes(_rootKey);
    final seed = await _bytes(_seedKey);
    if (root == null || seed == null) return null;
    return ClientIdentity(
      root: root,
      recoverySeed: seed,
      authenticatorSecret: await _bytes(_authenticatorKey),
    );
  }

  Future<void> write(ClientIdentity identity) async {
    await _storage.write(key: _rootKey, value: base64.encode(identity.root));
    await _storage.write(
      key: _seedKey,
      value: base64.encode(identity.recoverySeed),
    );
    final secret = identity.authenticatorSecret;
    if (secret == null) {
      await _storage.delete(key: _authenticatorKey);
    } else {
      await _storage.write(
        key: _authenticatorKey,
        value: base64.encode(secret),
      );
    }
  }

  /// Forgets the identity on this device. The accounts stay on their
  /// servers; without a paired device or the recovery words they are out of
  /// reach for good.
  Future<void> clear() async {
    await _storage.delete(key: _rootKey);
    await _storage.delete(key: _seedKey);
    await _storage.delete(key: _authenticatorKey);
    await _storage.delete(key: _pinLockKey);
  }

  /// A random id for this install, so the device list in the vault can tell
  /// this device from the person's others. Not a secret, and not sent to any
  /// server.
  Future<String?> installId() => _storage.read(key: _installKey);

  Future<void> saveInstallId(String id) =>
      _storage.write(key: _installKey, value: id);

  /// The app-PIN lock: a small value sealed under the PIN (Argon2id, in the
  /// Rust core), present only on a device that has no biometric or system
  /// credential to unlock with. Opening it is what proves the PIN.
  Future<Uint8List?> pinLock() => _bytes(_pinLockKey);

  Future<void> savePinLock(Uint8List? blob) => blob == null
      ? _storage.delete(key: _pinLockKey)
      : _storage.write(key: _pinLockKey, value: base64.encode(blob));

  Future<Uint8List?> _bytes(String key) async {
    final value = await _storage.read(key: key);
    return value == null ? null : base64.decode(value);
  }
}
