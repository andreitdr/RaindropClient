import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Everything that must never leak into plain-text prefs, logs, or crash
/// reports: pinned TLS fingerprints, pinned server identity keys and session
/// tokens. Backed by Keychain
/// (macOS/iOS), Credential Manager (Windows), libsecret (Linux), and
/// Keystore (Android) via `flutter_secure_storage`.
///
/// A server's per-client GUID is *not* stored here — it isn't a secret
/// (the server hands out `PublicUserProfile.userId` to anyone who asks), so
/// it lives as `ServerProfile.id` in plain prefs and doubles as that
/// server's storage namespace key.
class SecureStore {
  const SecureStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  String _fingerprintKey(String serverId) => 'server.$serverId.fingerprint';
  String _tokenKey(String serverId) => 'server.$serverId.token';
  String _identityKey(String serverId) => 'server.$serverId.identity';
  String _cryptoStoreKey(String serverId) => 'server.$serverId.dbkey';

  Future<String?> pinnedFingerprint(String serverId) =>
      _storage.read(key: _fingerprintKey(serverId));

  Future<void> pinFingerprint(String serverId, String fingerprint) =>
      _storage.write(key: _fingerprintKey(serverId), value: fingerprint);

  /// The server's pinned identity key, which may vouch for a new certificate.
  Future<Uint8List?> pinnedIdentityKey(String serverId) async {
    final value = await _storage.read(key: _identityKey(serverId));
    return value == null ? null : base64.decode(value);
  }

  Future<void> pinIdentityKey(String serverId, Uint8List key) =>
      _storage.write(key: _identityKey(serverId), value: base64.encode(key));

  /// The key that opens this server's encrypted crypto store (see
  /// `CryptoStores`). Losing it loses every private key and decrypted message
  /// for the server; it never leaves this keystore.
  Future<Uint8List?> cryptoStoreKey(String serverId) async {
    final value = await _storage.read(key: _cryptoStoreKey(serverId));
    return value == null ? null : base64.decode(value);
  }

  Future<void> saveCryptoStoreKey(String serverId, Uint8List key) =>
      _storage.write(key: _cryptoStoreKey(serverId), value: base64.encode(key));

  Future<void> deleteCryptoStoreKey(String serverId) =>
      _storage.delete(key: _cryptoStoreKey(serverId));

  Future<String?> sessionToken(String serverId) =>
      _storage.read(key: _tokenKey(serverId));

  Future<void> saveSessionToken(String serverId, String token) =>
      _storage.write(key: _tokenKey(serverId), value: token);

  Future<void> clearSessionToken(String serverId) =>
      _storage.delete(key: _tokenKey(serverId));

  /// Removes every secret associated with a server (its pinned fingerprint,
  /// identity key, session token and crypto store key). Call alongside
  /// removing its `ServerProfile`, and delete the store itself through
  /// `CryptoStores.delete` — without its key it is unreadable anyway.
  Future<void> forgetServer(String serverId) async {
    await _storage.delete(key: _cryptoStoreKey(serverId));
    await _storage.delete(key: _fingerprintKey(serverId));
    await _storage.delete(key: _identityKey(serverId));
    await _storage.delete(key: _tokenKey(serverId));
  }
}
