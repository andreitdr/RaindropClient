import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../../core/crypto/mls_crypto_engine.dart';
import '../../core/crypto/totp.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/users_api.dart';
import '../../core/storage/identity_store.dart';

/// Signs this device in to one server with its device key. There is no
/// password anywhere in this: the credential is a key the account's identity
/// has certified, and the identity is derived from the person's root.
///
/// The first time, [engine]'s store is empty: the device makes its key,
/// certifies itself with the identity derived for this server, and presents
/// that certificate — which registers the device, and the account too when
/// [username] is given and the server has none for it. After that the
/// signature alone is enough, and the certificate is ignored.
///
/// [serverKey] is the server's pinned identity key. It is part of what is
/// signed, so a challenge relayed from somewhere else is useless, and part
/// of every derivation, so this account is unrelated to the person's account
/// anywhere else.
///
/// A device new to an account that has an authenticator needs a code. This
/// device computes one when it holds the secret (it was paired); otherwise
/// the call fails with `authenticator_required` and the caller asks the
/// person for [typedCode].
Future<SessionResult> signInWithDevice({
  required UsersApi api,
  required MlsCryptoEngine engine,
  required ClientIdentity identity,
  required Uint8List serverKey,
  String? username,
  String? typedCode,
}) async {
  final device =
      await engine.device() ??
      await engine.createIdentityFromRoot(
        root: identity.root,
        serverKey: serverKey,
        deviceId: const Uuid().v4(),
      );

  final secret = identity.authenticatorSecret;
  Future<SessionResult> attempt() async {
    final nonce = await api.beginAuth(device.userId);
    final signature = await engine.signAuthChallenge(
      serverKey: serverKey,
      nonce: nonce,
    );
    return api.completeAuth(
      userId: device.userId,
      deviceId: device.deviceId,
      nonce: nonce,
      signature: signature,
      certificate: device.certificate,
      username: username,
      authenticatorCode:
          typedCode ?? (secret == null ? null : Totp.code(secret)),
    );
  }

  try {
    return await attempt();
  } on ApiException catch (e) {
    // A code is good once per 30 seconds. One this device computed can have
    // been spent a moment ago — by enrolling the authenticator, or by an
    // earlier attempt — and the next one is right: wait for it rather than
    // put a question to the person that they cannot answer any better.
    if (e.code != 'invalid_authenticator_code' ||
        typedCode != null ||
        secret == null) {
      rethrow;
    }
    await Future<void>.delayed(
      Totp.untilNextStep() + const Duration(seconds: 1),
    );
    return attempt();
  }
}

/// Asks the server to let this device in without an authenticator code once
/// a wait is over (see `UsersApi.requestRecovery`). The device's keys are
/// the ones [signInWithDevice] made, or made here the same way. Returns when
/// the wait ends.
Future<DateTime> requestRecoveryWithDevice({
  required UsersApi api,
  required MlsCryptoEngine engine,
  required ClientIdentity identity,
  required Uint8List serverKey,
}) async {
  final device =
      await engine.device() ??
      await engine.createIdentityFromRoot(
        root: identity.root,
        serverKey: serverKey,
        deviceId: const Uuid().v4(),
      );
  final nonce = await api.beginAuth(device.userId);
  final wait = await api.requestRecovery(
    userId: device.userId,
    deviceId: device.deviceId,
    nonce: nonce,
    signature: await engine.signAuthChallenge(
      serverKey: serverKey,
      nonce: nonce,
    ),
    certificate: device.certificate,
  );
  return wait.eligibleAt;
}

/// The failures of [signInWithDevice] that are about the authenticator, and
/// so are answered by asking the person for a code.
bool needsAuthenticatorCode(String code) =>
    code == 'authenticator_required' || code == 'invalid_authenticator_code';
