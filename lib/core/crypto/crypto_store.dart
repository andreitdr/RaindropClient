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
  Future<MlsCryptoEngine> open(String serverId) async {
    final key =
        await _secure.cryptoStoreKey(serverId) ?? await _createKey(serverId);
    return MlsCryptoEngine.open(path: await _path(serverId), key: key);
  }

  /// Deletes [serverId]'s store and its key: every private key, group and
  /// decrypted message this device held for that server. Irreversible.
  Future<void> delete(String serverId) async {
    final path = await _path(serverId);
    for (final suffix in const ['', '-wal', '-shm']) {
      final file = File('$path$suffix');
      if (await file.exists()) await file.delete();
    }
    await _secure.deleteCryptoStoreKey(serverId);
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
