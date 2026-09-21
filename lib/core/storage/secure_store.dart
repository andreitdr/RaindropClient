import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Everything that must never leak into plain-text prefs, logs, or crash
/// reports: pinned TLS fingerprints and session tokens. Backed by Keychain
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

  Future<String?> pinnedFingerprint(String serverId) =>
      _storage.read(key: _fingerprintKey(serverId));

  Future<void> pinFingerprint(String serverId, String fingerprint) =>
      _storage.write(key: _fingerprintKey(serverId), value: fingerprint);

  Future<String?> sessionToken(String serverId) =>
      _storage.read(key: _tokenKey(serverId));

  Future<void> saveSessionToken(String serverId, String token) =>
      _storage.write(key: _tokenKey(serverId), value: token);

  Future<void> clearSessionToken(String serverId) =>
      _storage.delete(key: _tokenKey(serverId));

  /// Removes every secret associated with a server (its pinned fingerprint
  /// and session token). Call alongside removing its `ServerProfile`.
  Future<void> forgetServer(String serverId) async {
    await _storage.delete(key: _fingerprintKey(serverId));
    await _storage.delete(key: _tokenKey(serverId));
  }
}
