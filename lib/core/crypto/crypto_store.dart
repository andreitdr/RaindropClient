import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../storage/secure_store.dart';
import 'bridge/frb_generated.dart';
import 'crypto_engine.dart';
import 'mls_crypto_engine.dart';

/// Where each server's encrypted crypto store lives, and the key that opens
/// it.
///
/// One SQLCipher file per server profile, under the app's support directory
/// (not Documents: it must not be user-visible or synced as a document). Its
/// 32-byte key is random, created on first open, and kept only in
/// [SecureStore] — Keychain, Credential Manager, libsecret or Keystore — so a
/// copy of the app's files alone opens nothing.
class CryptoStores {
  const CryptoStores({SecureStore secureStore = const SecureStore()})
    : _secure = secureStore;

  final SecureStore _secure;

  /// Loads the native library. Call once before any [open], before `runApp`.
  static Future<void> initialize() => RustLib.init();

  /// Opens (creating on first use) the crypto store for [serverId].
  ///
  /// A store its key cannot open is unrecoverable — the key exists nowhere
  /// else — so it is discarded and a fresh one created, rather than leaving
  /// the server stuck on [CryptoErrorKind.storeLocked] forever. That happens
  /// when the keystore loses the key but the file survives: an Android backup
  /// restored onto a new install (the Keystore is never backed up, and
  /// `flutter_secure_storage` wipes what it can no longer decrypt), or a
  /// keychain reset. The device then has no keys and goes through setup
  /// again (link or recovery words), as a new device would.
  Future<MlsCryptoEngine> open(String serverId) async {
    final path = await _path(serverId);
    var key = await _secure.cryptoStoreKey(serverId);
    if (key == null) {
      // Whatever file is here was made under a key that is gone.
      await _deleteFiles(path);
      key = await _createKey(serverId);
    }
    try {
      return await MlsCryptoEngine.open(path: path, key: key);
    } on CryptoException catch (e) {
      if (e.kind != CryptoErrorKind.storeLocked) rethrow;
      await _deleteFiles(path);
      return MlsCryptoEngine.open(path: path, key: key);
    }
  }

  /// Deletes [serverId]'s store and its key: every private key, group and
  /// decrypted message this device held for that server. Irreversible.
  Future<void> delete(String serverId) async {
    await _deleteFiles(await _path(serverId));
    await _secure.deleteCryptoStoreKey(serverId);
  }

  Future<void> _deleteFiles(String path) async {
    for (final suffix in const ['', '-wal', '-shm']) {
      final file = File('$path$suffix');
      if (await file.exists()) await file.delete();
    }
  }

  Future<Uint8List> _createKey(String serverId) async {
    final random = Random.secure();
    final key = Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    await _secure.saveCryptoStoreKey(serverId, key);
    return key;
  }

  Future<String> _path(String serverId) async {
    // serverId is this client's own UUID for the server, so it is safe in a
    // file name; checked anyway, since it becomes part of a path.
    groupIdForChannel(serverId);
    final directory = Directory(
      '${(await getApplicationSupportDirectory()).path}/crypto',
    );
    await directory.create(recursive: true);
    return '${directory.path}/raindrop-$serverId.db';
  }
}
