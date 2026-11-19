import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/crypto/identity_crypto.dart';
import '../../../core/platform/platform_info.dart';
import '../../../core/storage/app_prefs.dart';
import '../../../core/storage/identity_store.dart';
import '../../../core/theme/theme_controller.dart';
import '../models/recovery_check.dart';

/// The person's identity on this device, or null before one was created,
/// paired or recovered — which is the first thing the app asks for.
///
/// One identity, however many servers: every account is derived from its
/// root, so signing in anywhere, adding a server, and coming back to a server
/// that was removed all need nothing more than this.
final identityProvider =
    AsyncNotifierProvider<IdentityController, ClientIdentity?>(
      IdentityController.new,
    );

class IdentityController extends AsyncNotifier<ClientIdentity?> {
  static const _store = IdentityStore();

  @override
  Future<ClientIdentity?> build() => _store.read();

  /// A brand-new person: makes the root and a recovery key. Returns the 24
  /// words, which exist nowhere once this returns but in what the caller
  /// shows.
  Future<String> create() async {
    final root = await IdentityCrypto.newRoot();
    final recovery = await IdentityCrypto.newRecoveryKey();
    await _install(ClientIdentity(root: root, recoverySeed: recovery.seed));
    return recovery.words;
  }

  /// Takes on an identity that came from another device (pairing) or from
  /// the recovery words.
  Future<void> adopt(ClientIdentity identity) => _install(identity);

  /// Replaces the recovery key. The old words stop working once every
  /// server's copy of the sealed root has been replaced, which the vault
  /// sync does as each server is next reached.
  Future<String> newRecoveryKey() async {
    final current = await _require();
    final recovery = await IdentityCrypto.newRecoveryKey();
    await _install(current.copyWith(recoverySeed: recovery.seed));
    return recovery.words;
  }

  /// Records the authenticator's secret (or that there is none any more).
  Future<void> setAuthenticator(Uint8List? secret) async {
    final current = await _require();
    await _install(
      secret == null
          ? current.copyWith(clearAuthenticator: true)
          : current.copyWith(authenticatorSecret: secret),
    );
  }

  Future<void> _install(ClientIdentity identity) async {
    await _store.write(identity);
    state = AsyncData(identity);
  }

  Future<ClientIdentity> _require() async {
    final current = await future;
    if (current == null) throw StateError('This device has no identity yet.');
    return current;
  }
}

/// Whether to ask the person to check they still have their recovery words
/// (see [recoveryCheckDue]), and the two things that reset it.
final recoveryCheckDueProvider = NotifierProvider<RecoveryCheckDue, bool>(
  RecoveryCheckDue.new,
);

class RecoveryCheckDue extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(appPrefsProvider);
    return recoveryCheckDue(
      now: DateTime.now(),
      setAt: prefs.recoveryWordsSetAt,
      checkedAt: prefs.recoveryCheckedAt,
    );
  }

  /// New words were shown and the person typed some of them back.
  Future<void> recordWordsSet() async {
    await ref.read(appPrefsProvider).recordRecoveryWordsSet(DateTime.now());
    ref.invalidateSelf();
  }

  /// The person typed in all their words and they were the current ones.
  Future<void> recordChecked() async {
    await ref.read(appPrefsProvider).recordRecoveryChecked(DateTime.now());
    ref.invalidateSelf();
  }
}

/// Whether [words] are the current recovery words: the seed they make is the
/// one this device keeps. Checked here, with nothing sent anywhere. Throws
/// a `CryptoException` when they are not valid recovery words at all.
Future<bool> recoveryWordsMatch(ClientIdentity identity, String words) async {
  final seed = await IdentityCrypto.seedFromWords(
    normalizeRecoveryWords(words),
  );
  return listEquals(seed, identity.recoverySeed);
}

/// This install's id in the person's device list, made on first use.
final installIdProvider = FutureProvider<String>((ref) async {
  const store = IdentityStore();
  final existing = await store.installId();
  if (existing != null) return existing;
  final id = const Uuid().v4();
  await store.saveInstallId(id);
  return id;
});

/// What this device calls itself to the person's other devices: the name
/// they gave it, or the machine's own.
String deviceName(AppPrefs prefs) => prefs.deviceName ?? defaultDeviceName();

String defaultDeviceName() {
  try {
    final host = Platform.localHostname.replaceAll(RegExp(r'\.local$'), '');
    if (host.isNotEmpty && host != 'localhost') return _clip(host);
  } on Object {
    // No hostname on this platform: fall through to its name.
  }
  return switch (currentPlatform) {
    RaindropPlatform.ios => 'iPhone',
    RaindropPlatform.android => 'Android phone',
    RaindropPlatform.macos => 'Mac',
    RaindropPlatform.windows => 'Windows PC',
    RaindropPlatform.linux => 'Linux PC',
    RaindropPlatform.web => 'Browser',
  };
}

/// Pairing offers carry at most 64 bytes of name.
String _clip(String name) {
  var clipped = name;
  while (clipped.length > 1 && clipped.codeUnits.length > 40) {
    clipped = clipped.substring(0, clipped.length - 1);
  }
  return clipped;
}
