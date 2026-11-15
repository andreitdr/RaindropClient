import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/crypto/crypto_engine.dart';
import '../../../core/crypto/identity_crypto.dart';
import '../../../core/storage/identity_store.dart';

/// How this device proves that whoever is holding it is its owner.
enum UnlockMethod {
  /// Face ID, Touch ID, a fingerprint, Windows Hello — or the device's own
  /// passcode, which the system offers when biometrics fail or are absent.
  system,

  /// An app PIN, for a device the system cannot unlock for us: Linux, or a
  /// phone with no screen lock at all.
  pin,

  /// Neither yet: the person has to choose a PIN before going further.
  none,
}

/// Whether the app is unlocked. An identity is enough to sign in to every
/// server the person is on, so the app does not show anything, or do
/// anything in their name, until the device has been unlocked — once per
/// launch, and again before each thing that cannot be taken back.
///
/// What this is and is not: the system keystore is what guards the root
/// secret at rest; this is the check that the person at the device is the
/// one it belongs to. On [UnlockMethod.pin] devices that check is the app's
/// own, made against a PIN stretched with Argon2id.
final appLockProvider = NotifierProvider<AppLock, bool>(AppLock.new);

class AppLock extends Notifier<bool> {
  static const _store = IdentityStore();
  static final _auth = LocalAuthentication();

  @override
  bool build() => false;

  /// Which way this device unlocks.
  Future<UnlockMethod> method() async {
    if (await _systemAvailable()) return UnlockMethod.system;
    return await _store.pinLock() == null
        ? UnlockMethod.none
        : UnlockMethod.pin;
  }

  static Future<bool> _systemAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } on MissingPluginException {
      return false; // Linux, and tests.
    } on PlatformException {
      return false;
    }
  }

  /// Asks the system to verify the person. False when they cancel or fail.
  Future<bool> unlockWithSystem(String reason) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
      if (ok) state = true;
      return ok;
    } on LocalAuthException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Checks [pin] against the stored lock. Deliberately slow (Argon2id), so
  /// that a copy of the lock cannot be run through every PIN in a moment.
  Future<bool> unlockWithPin(String pin) async {
    final lock = await _store.pinLock();
    if (lock == null) return false;
    try {
      await IdentityCrypto.openWithPin(lock, pin);
      state = true;
      return true;
    } on CryptoException {
      return false;
    }
  }

  /// Sets (or replaces) the app PIN, and unlocks.
  Future<void> setPin(String pin) async {
    final random = Random.secure();
    final token = Uint8List.fromList(
      List.generate(32, (_) => random.nextInt(256)),
    );
    await _store.savePinLock(await IdentityCrypto.sealWithPin(token, pin));
    state = true;
  }

  void lock() => state = false;
}

/// A PIN worth having: six digits or more, or anything longer with letters.
String? validatePin(String pin) {
  if (pin.length < 6) return 'Use at least 6 characters.';
  if (RegExp(r'^(\d)\1+$').hasMatch(pin)) return 'Not the same digit repeated.';
  return null;
}
