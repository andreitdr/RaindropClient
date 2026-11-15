/// The person's one identity, as the Rust core computes it: the root secret,
/// the account it has on each server, the recovery key, the vault, the app
/// PIN and pairing a new device (`RaindropCrypto/docs/root-identity.md`).
///
/// Free functions over bytes — none of this belongs to one server's
/// [CryptoEngine]. The secrets themselves live in `IdentityStore`; nothing
/// here keeps them.
library;

import 'dart:typed_data';

import 'bridge/api/identity.dart' as rust;
import 'mls_crypto_engine.dart';

/// A new recovery key: [words] to show the person once, and the [seed] the
/// device keeps so it can seal the root on servers joined later.
class NewRecoveryKey {
  const NewRecoveryKey({required this.words, required this.seed});

  final String words;
  final Uint8List seed;
}

/// A new device's side of a pairing in progress.
class PairingStart {
  const PairingStart({
    required this.offer,
    required this.commitment,
    required this.exchangeSecret,
  });

  /// Handed to the relay.
  final Uint8List offer;

  /// Goes in the pairing code.
  final Uint8List commitment;

  /// Held in memory until the approval arrives, and nowhere longer.
  final Uint8List exchangeSecret;
}

abstract final class IdentityCrypto {
  static Future<Uint8List> newRoot() => guardCrypto(rust.newRootSecret);

  /// The account id [root] has on the server whose identity key is
  /// [serverKey]. The same on every paired device, and unrelated to the
  /// account on any other server.
  static Future<String> accountId(Uint8List root, Uint8List serverKey) =>
      guardCrypto(
        () async =>
            (await rust.deriveAccount(root: root, serverKey: serverKey)).userId,
      );

  static Future<NewRecoveryKey> newRecoveryKey() => guardCrypto(() async {
    final made = await rust.newRecoveryKey();
    return NewRecoveryKey(words: made.words, seed: made.seed);
  });

  /// Throws [CryptoErrorKind.malformed] for a typo: the words carry a checksum.
  static Future<Uint8List> seedFromWords(String words) =>
      guardCrypto(() => rust.recoverySeedFromWords(words: words));

  /// The name the sealed root is stored under on one server.
  static Future<String> lookupId(Uint8List seed, Uint8List serverKey) =>
      guardCrypto(
        () => rust.recoveryLookupId(seed: seed, serverKey: serverKey),
      );

  static Future<Uint8List> sealRoot({
    required Uint8List seed,
    required Uint8List serverKey,
    required Uint8List root,
  }) => guardCrypto(
    () => rust.sealRoot(seed: seed, serverKey: serverKey, root: root),
  );

  /// Throws [CryptoErrorKind.backupLocked] for the wrong words.
  static Future<Uint8List> openRoot({
    required Uint8List seed,
    required Uint8List serverKey,
    required Uint8List blob,
  }) => guardCrypto(
    () => rust.openRoot(seed: seed, serverKey: serverKey, blob: blob),
  );

  static Future<Uint8List> sealVault({
    required Uint8List root,
    required Uint8List serverKey,
    required Uint8List plaintext,
  }) => guardCrypto(
    () =>
        rust.sealVault(root: root, serverKey: serverKey, plaintext: plaintext),
  );

  static Future<Uint8List> openVault({
    required Uint8List root,
    required Uint8List serverKey,
    required Uint8List blob,
  }) => guardCrypto(
    () => rust.openVault(root: root, serverKey: serverKey, blob: blob),
  );

  static Future<Uint8List> sealWithPin(Uint8List plaintext, String pin) =>
      guardCrypto(() => rust.sealWithPin(plaintext: plaintext, pin: pin));

  /// Throws [CryptoErrorKind.backupLocked] for the wrong PIN.
  static Future<Uint8List> openWithPin(Uint8List blob, String pin) =>
      guardCrypto(() => rust.openWithPin(blob: blob, pin: pin));

  static Future<PairingStart> beginPairing({
    required String deviceName,
    required String platform,
  }) => guardCrypto(() async {
    final begun = await rust.beginPairing(
      deviceName: deviceName,
      platform: platform,
    );
    return PairingStart(
      offer: begun.offer,
      commitment: begun.commitment,
      exchangeSecret: begun.exchangeSecret,
    );
  });

  /// Who is asking to be paired, once [offer] has been checked against the
  /// pairing code's [commitment]. Throws [CryptoErrorKind.verification] when
  /// the relay handed over a different offer.
  static Future<({String deviceName, String platform})> readPairingOffer(
    Uint8List offer,
    Uint8List commitment,
  ) => guardCrypto(() async {
    final info = await rust.readPairingOffer(
      offer: offer,
      commitment: commitment,
    );
    return (deviceName: info.deviceName, platform: info.platform);
  });

  static Future<Uint8List> approvePairing({
    required Uint8List offer,
    required Uint8List commitment,
    required Uint8List payload,
  }) => guardCrypto(
    () => rust.approvePairing(
      offer: offer,
      commitment: commitment,
      payload: payload,
    ),
  );

  static Future<Uint8List> completePairing({
    required Uint8List approval,
    required Uint8List offer,
    required Uint8List exchangeSecret,
  }) => guardCrypto(
    () => rust.completePairing(
      approval: approval,
      offer: offer,
      exchangeSecret: exchangeSecret,
    ),
  );
}
