import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/crypto/crypto_engine.dart';
import '../../../core/crypto/crypto_store.dart';
import '../../../core/crypto/mls_crypto_engine.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/crypto/totp.dart';
import '../../../core/network/e2ee_api.dart';
import '../../../core/storage/identity_store.dart';
import '../../../core/storage/secure_store.dart';
import '../../identity/controllers/vault_sync.dart';
import '../../servers/controllers/session_controller.dart';

/// The crypto engine for one server: its encrypted store, opened once and
/// kept open while the app runs. Invalidating it closes the store; do that
/// before deleting the store's files.
final cryptoEngineProvider = FutureProvider.family<MlsCryptoEngine, String>((
  ref,
  serverId,
) async {
  final engine = await const CryptoStores().open(serverId);
  ref.onDispose(engine.dispose);
  return engine;
});

/// Where this device stands with end-to-end encryption on one server.
sealed class DeviceSetupState {
  const DeviceSetupState();
}

/// The server does not offer end-to-end encryption (`e2ee.devices.v1`).
class DeviceSetupUnsupported extends DeviceSetupState {
  const DeviceSetupUnsupported();
}

/// This device has its keys, is registered, and the session is bound to it.
class DeviceSetupReady extends DeviceSetupState {
  const DeviceSetupReady(this.device);

  final DeviceKeys device;
}

/// This device's keys no longer belong to the account: it was removed from
/// another of the person's devices, or the account's devices were reset. It
/// has to make new keys and sign in again.
class DeviceSetupReplaced extends DeviceSetupState {
  const DeviceSetupReplaced({required this.revoked});

  final bool revoked;
}

final deviceSetupProvider =
    AsyncNotifierProvider.family<
      DeviceSetupController,
      DeviceSetupState,
      String
    >(DeviceSetupController.new);

/// Confirms this device's place in end-to-end encryption on one server.
///
/// There is little left to set up: a session only exists because this device
/// signed in with its key (`signInWithDevice`), which made the key, certified
/// it with the identity derived from the person's root, and registered it.
/// What remains is to make sure the server agrees — re-registering is a no-op
/// that also catches a device that was removed — and to bring the person's
/// vault on this server up to date.
class DeviceSetupController
    extends FamilyAsyncNotifier<DeviceSetupState, String> {
  @override
  Future<DeviceSetupState> build(String serverId) async {
    final session = await ref.watch(serverSessionProvider(serverId).future);
    if (session == null) return const DeviceSetupUnsupported();

    final info = await session.usersApi.serverInfo();
    if (!info.capabilities.contains(e2eeDevicesCapability)) {
      return const DeviceSetupUnsupported();
    }

    final engine = await ref.watch(cryptoEngineProvider(serverId).future);
    final device = await engine.device();
    // No keys with a session open cannot come from signing in, which makes
    // them; it means the store was lost underneath a stored session. Signing
    // in again is what puts it right.
    if (device == null) return const DeviceSetupReplaced(revoked: true);

    final ready = await _activate(session, engine, device);
    if (ready is DeviceSetupReady) {
      // Not awaited: the vault is housekeeping, and nothing waits on it.
      // The vault first: it may say the authenticator this device holds has
      // been replaced, which the enrolment below must not undo.
      unawaited(
        ref
            .read(vaultProvider.notifier)
            .sync(session)
            .then((_) => _enrolAuthenticator(session)),
      );
    }
    return ready;
  }

  /// A server joined after the person set up their authenticator does not
  /// have it yet. This device holds the secret, so it can add it there with
  /// a code of its own making. Best-effort.
  Future<void> _enrolAuthenticator(ServerSession session) async {
    try {
      final secret = (await const IdentityStore().read())?.authenticatorSecret;
      if (secret == null) return;
      if ((await session.e2eeApi.authenticatorStatus(session.token)).enabled) {
        return;
      }
      await session.e2eeApi.enrollAuthenticator(
        session.token,
        secret: secret,
        code: Totp.code(secret),
      );
    } on ApiException catch (e) {
      debugPrint('device setup: could not enrol the authenticator: $e');
    }
  }

  /// In-flight activations, by session token: each one waits for the one
  /// before it.
  static final _activations = <String, Future<void>>{};

  /// Registers [device] (a no-op when it already is) and binds the session.
  ///
  /// One at a time per session token. The server keeps a single outstanding
  /// challenge per session, so a second activation asking for one while the
  /// first is still signing replaces the first's nonce: the first bind then
  /// fails (`invalid_signature`), and having used the challenge up, so does
  /// the second (`no_challenge`).
  Future<DeviceSetupState> _activate(
    ServerSession session,
    CryptoEngine engine,
    DeviceKeys device,
  ) {
    final token = session.token;
    final run = (_activations[token] ?? Future<void>.value()).then(
      (_) => _registerAndBind(session, engine, device),
    );
    final tail = run.then<void>((_) {}, onError: (Object _) {});
    _activations[token] = tail;
    unawaited(
      tail.whenComplete(() {
        if (identical(_activations[token], tail)) _activations.remove(token);
      }),
    );
    return run;
  }

  Future<DeviceSetupState> _registerAndBind(
    ServerSession session,
    CryptoEngine engine,
    DeviceKeys device,
  ) async {
    try {
      await session.e2eeApi.registerDevice(session.token, device.certificate);
    } on ApiException catch (e) {
      if (e.code == 'identity_mismatch') {
        return const DeviceSetupReplaced(revoked: false);
      }
      // The id is taken by a revoked device: this one.
      if (e.code == 'device_exists') {
        return const DeviceSetupReplaced(revoked: true);
      }
      rethrow;
    }

    final nonce = await session.e2eeApi.sessionChallenge(session.token);
    await session.e2eeApi.bindSession(
      session.token,
      deviceId: device.deviceId,
      signature: await engine.signSessionChallenge(nonce),
    );
    return DeviceSetupReady(device);
  }

  Future<MlsCryptoEngine> _engine() =>
      ref.read(cryptoEngineProvider(arg).future);

  /// Deletes this device's keys and starts over — for a device that was
  /// revoked or whose identity was replaced elsewhere.
  Future<void> startOver() => _wipeLocalKeys();

  Future<void> _wipeLocalKeys() async {
    // Close the store before its files go (Windows refuses to delete an open
    // file); invalidating alone would only close it at Riverpod's leisure.
    (await _engine()).dispose();
    ref.invalidate(cryptoEngineProvider(arg));
    await const CryptoStores().delete(arg);
    // The session belonged to the keys just deleted. Without its token the
    // session provider signs in again, which makes and registers new ones.
    await const SecureStore().clearSessionToken(arg);
    ref.invalidate(serverSessionProvider(arg));
  }
}

/// This user's active devices on one server, for the Encryption settings.
final ownDevicesProvider = FutureProvider.autoDispose
    .family<List<DeviceSummary>, String>((ref, serverId) async {
      final session = await ref.watch(serverSessionProvider(serverId).future);
      if (session == null) return const [];
      final users = await session.e2eeApi.listDevices(session.token, [
        session.currentUser.userId,
      ]);
      return users.isEmpty ? const [] : users.first.devices;
    });

/// Revokes one of this user's devices, then refreshes [ownDevicesProvider].
Future<void> revokeDevice(
  WidgetRef ref,
  String serverId,
  String deviceId,
) async {
  final session = ref.read(serverSessionProvider(serverId)).valueOrNull;
  if (session == null) return;
  await session.e2eeApi.revokeDevice(session.token, deviceId);
  ref.invalidate(ownDevicesProvider(serverId));
}

/// A short, readable fingerprint of an identity key, for the settings page.
String identityFingerprint(Uint8List key) {
  final hex = key
      .take(16)
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join()
      .toUpperCase();
  return [for (var i = 0; i < hex.length; i += 4) hex.substring(i, i + 4)]
      .join(' ');
}
