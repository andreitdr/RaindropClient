import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/crypto/crypto_engine.dart';
import '../../../core/crypto/crypto_store.dart';
import '../../../core/crypto/mls_crypto_engine.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/e2ee_api.dart';
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
  const DeviceSetupReady(this.device, {this.recoveryWords});

  final DeviceKeys device;

  /// A fresh recovery key's 24 words, set once, right after they were made.
  /// The UI shows them and then calls
  /// [DeviceSetupController.acknowledgeRecoveryWords].
  final String? recoveryWords;
}

/// The account already has encryption set up on another device, and this
/// one has no keys: link it from that device, or restore the backup.
class DeviceSetupNeedsKeys extends DeviceSetupState {
  const DeviceSetupNeedsKeys();
}

/// Waiting for an existing device to approve [code].
class DeviceSetupLinking extends DeviceSetupState {
  const DeviceSetupLinking(this.code);

  final DeviceLinkCode code;
}

/// This device's keys no longer belong to the account: its identity was
/// reset elsewhere, or this device was revoked. It has to start over.
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

/// Sets this device up for end-to-end encryption on one server and keeps the
/// server session bound to it. Rebuilds whenever the session does, because
/// the server forgets bindings with its sessions.
///
/// - **First device of an account:** creates the identity key, registers the
///   device, binds the session, and seals a backup under a new recovery key
///   whose words the UI shows once.
/// - **Another device, no keys yet:** [DeviceSetupNeedsKeys]; the user links
///   it ([startLink]) or restores the backup ([restoreWithRecoveryWords]).
/// - **A device with keys:** re-registers (idempotent) and binds.
class DeviceSetupController
    extends FamilyAsyncNotifier<DeviceSetupState, String> {
  static const _uuid = Uuid();
  static const _pollInterval = Duration(seconds: 2);
  static const _linkLifetime = Duration(minutes: 5);

  Timer? _poll;

  @override
  Future<DeviceSetupState> build(String serverId) async {
    _poll?.cancel();
    ref.onDispose(() => _poll?.cancel());

    final session = await ref.watch(serverSessionProvider(serverId).future);
    if (session == null) return const DeviceSetupUnsupported();

    final info = await session.usersApi.serverInfo();
    if (!info.capabilities.contains(e2eeDevicesCapability)) {
      return const DeviceSetupUnsupported();
    }

    final engine = await ref.watch(cryptoEngineProvider(serverId).future);
    final device = await engine.device();
    // Keys in the store while a first-device setup is still running mean that
    // setup made them a moment ago and has yet to seal the backup: join it
    // below rather than activating on its heels.
    if (device != null && !_firstDeviceSetups.containsKey(serverId)) {
      final ready = await _activate(session, engine, device);
      if (ready is! DeviceSetupReady) return ready;
      await _ensureBackup(session, engine);
      return DeviceSetupReady(
        device,
        recoveryWords: _unshownRecoveryWords[serverId],
      );
    }

    // build() reruns whenever the session does, and this path awaits the
    // network before creating keys, so two runs can overlap. Share one
    // first-device setup per server: a second createIdentity on the same
    // store fails ("already holds a device identity"), and a superseded run
    // would carry off the only copy of the recovery words.
    final joined = _firstDeviceSetups.containsKey(serverId);
    final result = await (_firstDeviceSetups[serverId] ??= _setUpFirstDevice(
      session,
      engine,
    ).whenComplete(() => _firstDeviceSetups.remove(serverId)));
    if (result is! DeviceSetupReady) return result;

    final words = _unshownRecoveryWords[serverId];
    if (!joined) return DeviceSetupReady(result.device, recoveryWords: words);

    // Another run made the keys with its session; bind this one too.
    final ready = await _activate(session, engine, result.device);
    if (ready is! DeviceSetupReady) return ready;
    return DeviceSetupReady(result.device, recoveryWords: words);
  }

  /// In-flight first-device setups, by server id.
  static final _firstDeviceSetups = <String, Future<DeviceSetupState>>{};

  /// Recovery words made by a first-device setup and not yet acknowledged, by
  /// server id — so whichever run ends up live still shows them.
  static final _unshownRecoveryWords = <String, String>{};

  Future<DeviceSetupState> _setUpFirstDevice(
    ServerSession session,
    MlsCryptoEngine engine,
  ) async {
    final own = await session.e2eeApi.listDevices(session.token, [
      session.currentUser.userId,
    ]);
    // Another run may have finished while we waited.
    final existing = await engine.device();
    if (existing != null) return _activate(session, engine, existing);
    if (own.isNotEmpty && own.first.identityKey != null) {
      return const DeviceSetupNeedsKeys();
    }

    // The account's first device: it establishes the identity.
    final created = await engine.createIdentity(
      userId: session.currentUser.userId,
      deviceId: _uuid.v4(),
    );
    final ready = await _activate(session, engine, created);
    if (ready is! DeviceSetupReady) return ready;

    final backup = await engine.sealBackupWithRecoveryKey();
    await session.e2eeApi.putBackup(session.token, backup.blob);
    _unshownRecoveryWords[arg] = backup.recoveryWords!;
    return DeviceSetupReady(created);
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

  /// In-flight backup checks, by server id.
  static final _backupChecks = <String, Future<void>>{};

  /// Seals a backup under a new recovery key if the account has none — when
  /// the first-device setup that should have made one stopped after creating
  /// the keys. Its words go to [_unshownRecoveryWords] to be shown.
  /// Best-effort: on failure the next build tries again.
  Future<void> _ensureBackup(ServerSession session, CryptoEngine engine) {
    final serverId = arg;
    return _backupChecks[serverId] ??= _sealMissingBackup(
      serverId,
      session,
      engine,
    ).whenComplete(() => _backupChecks.remove(serverId));
  }

  Future<void> _sealMissingBackup(
    String serverId,
    ServerSession session,
    CryptoEngine engine,
  ) async {
    try {
      if (await session.e2eeApi.getBackup(session.token) != null) return;
      final backup = await engine.sealBackupWithRecoveryKey();
      await session.e2eeApi.putBackup(session.token, backup.blob);
      _unshownRecoveryWords[serverId] = backup.recoveryWords!;
    } on ApiException catch (e) {
      debugPrint('device setup: could not check the key backup: $e');
    } on CryptoException catch (e) {
      debugPrint('device setup: could not seal a key backup: $e');
    }
  }

  ServerSession _session() {
    final session = ref.read(serverSessionProvider(arg)).valueOrNull;
    if (session == null) {
      throw const ApiException(0, 'invalid_session', 'Not signed in.');
    }
    return session;
  }

  Future<MlsCryptoEngine> _engine() =>
      ref.read(cryptoEngineProvider(arg).future);

  /// The recovery words have been shown; stop offering them.
  void acknowledgeRecoveryWords() {
    _unshownRecoveryWords.remove(arg);
    final current = state.valueOrNull;
    if (current is DeviceSetupReady) {
      state = AsyncData(DeviceSetupReady(current.device));
    }
  }

  // ── A device without keys ──

  /// Opens a link for an existing device to approve, and waits for it.
  Future<void> startLink() async {
    final session = _session();
    final engine = await _engine();

    final link = await engine.beginDeviceLink(
      userId: session.currentUser.userId,
      deviceId: _uuid.v4(),
    );
    final linkId = await session.e2eeApi.startLink(session.token, link.offer);
    final code = DeviceLinkCode(linkId: linkId, commitment: link.commitment);
    state = AsyncData(DeviceSetupLinking(code));

    final deadline = DateTime.now().add(_linkLifetime);
    _poll?.cancel();
    _poll = Timer.periodic(_pollInterval, (timer) async {
      if (DateTime.now().isAfter(deadline)) {
        timer.cancel();
        state = const AsyncData(DeviceSetupNeedsKeys());
        return;
      }
      try {
        final approval = await session.e2eeApi.takeLinkApproval(
          session.token,
          linkId,
        );
        if (approval == null) return;
        timer.cancel();
        state = const AsyncLoading();
        state = await AsyncValue.guard(() async {
          final device = await engine.completeDeviceLink(approval);
          return _activate(session, engine, device);
        });
      } on ApiException {
        // A dropped connection: try again on the next tick.
      }
    });
  }

  /// Stops waiting for a link approval.
  void cancelLink() {
    _poll?.cancel();
    state = const AsyncData(DeviceSetupNeedsKeys());
  }

  /// Restores the account's keys from its backup with the 24 recovery words.
  /// Throws [CryptoException] ([CryptoErrorKind.backupLocked] for wrong
  /// words) or [ApiException].
  Future<void> restoreWithRecoveryWords(String words) async {
    final session = _session();
    final engine = await _engine();

    final backup = await session.e2eeApi.getBackup(session.token);
    if (backup == null) {
      throw const CryptoException(
        CryptoErrorKind.notFound,
        'This account has no key backup on the server.',
      );
    }
    final device = await engine.restoreWithRecoveryWords(
      backup: backup,
      words: words,
      deviceId: _uuid.v4(),
    );
    state = AsyncData(await _activate(session, engine, device));
  }

  /// Gives up on the old identity: revokes every device, forgets the backup,
  /// wipes this device's keys and sets up a new identity. Everyone the user
  /// talks to sees their safety number change.
  Future<void> resetIdentity(String password) async {
    final session = _session();
    await session.e2eeApi.resetIdentity(session.token, password);
    await _wipeLocalKeys();
  }

  /// Deletes this device's keys and starts over — for a device that was
  /// revoked or whose identity was replaced elsewhere.
  Future<void> startOver() => _wipeLocalKeys();

  Future<void> _wipeLocalKeys() async {
    _poll?.cancel();
    _unshownRecoveryWords.remove(arg);
    // Close the store before its files go (Windows refuses to delete an open
    // file); invalidating alone would only close it at Riverpod's leisure.
    (await _engine()).dispose();
    ref.invalidate(cryptoEngineProvider(arg));
    await const CryptoStores().delete(arg);
    ref.invalidateSelf();
  }

  // ── A device with keys ──

  /// Approves a new device from the code it shows. Throws [CryptoException]
  /// ([CryptoErrorKind.verification]) when the server's offer does not match
  /// the code.
  Future<void> approveLink(String codeText) async {
    final code = DeviceLinkCode.tryParse(codeText);
    if (code == null) {
      throw const CryptoException(
        CryptoErrorKind.malformed,
        'That is not a device link code.',
      );
    }
    final session = _session();
    final engine = await _engine();
    final offer = await session.e2eeApi.linkOffer(session.token, code.linkId);
    final approval = await engine.approveDeviceLink(offer, code.commitment);
    await session.e2eeApi.approveLink(session.token, code.linkId, approval);
  }

  /// Seals a new backup under a new recovery key, replacing the old one on
  /// the server, and returns the words to show.
  Future<String> newRecoveryKey() async {
    final session = _session();
    final engine = await _engine();
    final backup = await engine.sealBackupWithRecoveryKey();
    await session.e2eeApi.putBackup(session.token, backup.blob);
    return backup.recoveryWords!;
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
