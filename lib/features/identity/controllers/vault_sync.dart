import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/crypto/crypto_engine.dart';
import '../../../core/crypto/identity_crypto.dart';
import '../../../core/models/server_profile.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/platform/platform_info.dart';
import '../../../core/storage/identity_store.dart';
import '../../../core/storage/secure_store.dart';
import '../../../core/theme/theme_controller.dart';
import '../../servers/controllers/servers_controller.dart';
import '../../servers/controllers/session_controller.dart';
import '../models/vault.dart';
import 'identity_controller.dart';

/// The person's vault as this device last merged it.
final vaultProvider = NotifierProvider<VaultController, Vault>(
  VaultController.new,
);

/// Keeps the person's vault — their servers and their devices — the same on
/// this device and on every server they are on.
///
/// Each server holds a copy sealed under the root. Whenever a session opens,
/// this device reads that server's copy, merges it with its own, takes on
/// any server it had not heard of, and writes the merged vault back if that
/// server's copy was behind. So a server joined on the phone shows up on the
/// laptop the next time the laptop reaches any server the two share.
class VaultController extends Notifier<Vault> {
  static const _secure = SecureStore();

  @override
  Vault build() {
    final stored = ref.read(appPrefsProvider).identityVaultJson;
    if (stored.isEmpty) return const Vault();
    try {
      return Vault.fromJson(stored);
    } on Object {
      return const Vault();
    }
  }

  void _save(Vault vault) {
    state = vault;
    ref.read(appPrefsProvider).setIdentityVaultJson(vault.toJson());
  }

  /// Everything this device knows first-hand: the servers in its list, with
  /// the pins it holds for them, and itself.
  Future<Vault> _local() async {
    var vault = state;
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final server in ref.read(serversControllerProvider)) {
      final known = vault.servers['${server.host}:${server.port}'];
      if (known != null && known.displayName == server.displayName) continue;
      final fingerprint = await _secure.pinnedFingerprint(server.id);
      final identityKey = await _secure.pinnedIdentityKey(server.id);
      if (fingerprint == null || identityKey == null) continue;
      vault = vault.withServer(
        VaultServer(
          host: server.host,
          port: server.port,
          displayName: server.displayName,
          fingerprint: fingerprint,
          identityKey: identityKey,
          updatedAtMs: now,
        ),
      );
    }

    final installId = await ref.read(installIdProvider.future);
    final name = deviceName(ref.read(appPrefsProvider));
    final me = vault.devices[installId];
    if (me == null || me.name != name) {
      vault = vault.withDevice(
        VaultDevice(
          installId: installId,
          name: name,
          platform: currentPlatform.name,
          updatedAtMs: now,
        ),
      );
    }
    return vault;
  }

  /// The vault to hand a device being paired: this device's own view,
  /// brought up to date first.
  Future<Vault> current() async {
    final vault = await _local();
    _save(vault);
    return vault;
  }

  /// Merges this device's vault with the copy [session]'s server holds, and
  /// brings both up to date. Best-effort: a failure is logged and the next
  /// session tries again.
  Future<void> sync(ServerSession session) async {
    try {
      final identity = await const IdentityStore().read();
      final serverKey = await _secure.pinnedIdentityKey(session.profile.id);
      if (identity == null || serverKey == null) return;

      final lookupId = await IdentityCrypto.lookupId(
        identity.recoverySeed,
        serverKey,
      );
      final stored = await session.e2eeApi.getVault(session.token);
      Vault? remote;
      if (stored != null) {
        try {
          remote = Vault.tryFromBytes(
            await IdentityCrypto.openVault(
              root: identity.root,
              serverKey: serverKey,
              blob: stored.vault,
            ),
          );
        } on CryptoException {
          // Sealed under a root this device does not hold; it is replaced.
        }
      }

      final merged = (await _local()).merge(remote ?? const Vault());
      _save(merged);
      await adoptServers(merged, identity);

      // The authenticator was replaced or removed on another device: the
      // secret held here is no longer the account's, and using it would only
      // put the old one back.
      if (identity.authenticatorSecret != null &&
          merged.authenticatorUpdatedAtMs > 0 &&
          merged.authenticatorId !=
              authenticatorIdOf(identity.authenticatorSecret)) {
        await ref.read(identityProvider.notifier).setAuthenticator(null);
      }

      if (remote != null &&
          remote.sameAs(merged) &&
          stored!.lookupId == lookupId) {
        return;
      }
      await session.e2eeApi.putVault(
        session.token,
        lookupId: lookupId,
        sealedRoot: await IdentityCrypto.sealRoot(
          seed: identity.recoverySeed,
          serverKey: serverKey,
          root: identity.root,
        ),
        vault: await IdentityCrypto.sealVault(
          root: identity.root,
          serverKey: serverKey,
          plaintext: merged.toBytes(),
        ),
      );
    } on ApiException catch (e) {
      debugPrint('vault: could not sync with ${session.profile.host}: $e');
    } on CryptoException catch (e) {
      debugPrint('vault: could not seal for ${session.profile.host}: $e');
    }
  }

  /// Records which authenticator the person now has (null for none), so
  /// their other devices learn of the change.
  void markAuthenticator(Uint8List? secret) => _save(
    state.withAuthenticator(
      authenticatorIdOf(secret),
      DateTime.now().millisecondsSinceEpoch,
    ),
  );

  /// Adds every server in [vault] this device does not list yet — unless it
  /// was removed from this device on purpose. Each arrives with the pins the
  /// person's first device made, and its session then opens by itself.
  Future<void> adoptServers(Vault vault, ClientIdentity identity) async {
    _save(state.merge(vault));
    final hidden = ref.read(appPrefsProvider).hiddenServers;
    final listed = {
      for (final s in ref.read(serversControllerProvider))
        '${s.host}:${s.port}',
    };

    for (final server in vault.servers.values) {
      if (listed.contains(server.key) || hidden.contains(server.key)) continue;
      final id = await IdentityCrypto.accountId(
        identity.root,
        server.identityKey,
      );
      if (await _secure.pinnedFingerprint(id) == null) {
        await _secure.pinFingerprint(id, server.fingerprint);
      }
      if (await _secure.pinnedIdentityKey(id) == null) {
        await _secure.pinIdentityKey(id, server.identityKey);
      }
      ref
          .read(serversControllerProvider.notifier)
          .add(
            ServerProfile(
              id: id,
              host: server.host,
              port: server.port,
              displayName: server.displayName,
            ),
          );
    }
  }
}
