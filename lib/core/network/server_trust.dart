import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import '../storage/secure_store.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'tls_pinning.dart';
import 'users_api.dart';

/// Pins a server's long-lived identity key alongside its certificate, and
/// uses it to follow a certificate change the owner made on purpose.
///
/// A pinned certificate on its own leaves an owner no way to renew or replace
/// it without every client refusing to connect. So the server also keeps a
/// P-256 identity key and signs the fingerprint of whatever certificate it
/// presents (`RaindropServer/Security/ServerIdentityKey.cs`). Once that key is
/// pinned, a new certificate is accepted only when the pinned key vouches for
/// the exact certificate the TLS handshake presented. Anything else is still a
/// [ApiException.certificateMismatch].
class ServerTrust {
  const ServerTrust._();

  /// Prefixed to what the server signs; must match
  /// `ServerIdentityKey.TlsBindingContext`.
  static const bindingContext = 'raindrop/tls-binding/v1\n';

  /// Whether [publicKey] (an uncompressed P-256 point) signed [fingerprint]
  /// with [signature] (64 bytes, `r‖s`, ECDSA-SHA256).
  static bool verifyTlsBinding({
    required Uint8List publicKey,
    required String fingerprint,
    required Uint8List signature,
  }) {
    if (publicKey.length != 65 || publicKey[0] != 0x04) return false;
    if (signature.length != 64) return false;

    try {
      final domain = ECCurve_secp256r1();
      final point = domain.curve.decodePoint(publicKey);
      final verifier = ECDSASigner(SHA256Digest())
        ..init(false, PublicKeyParameter(ECPublicKey(point, domain)));

      final message = Uint8List.fromList(
        utf8.encode(bindingContext + CertificatePinner.normalize(fingerprint)),
      );
      return verifier.verifySignature(
        message,
        ECSignature(
          _unsigned(signature.sublist(0, 32)),
          _unsigned(signature.sublist(32)),
        ),
      );
    } catch (_) {
      // A point off the curve or any other malformed input is a failed
      // check, never a crash in the middle of connecting.
      return false;
    }
  }

  /// Checks what a server said about itself against the certificate the
  /// handshake actually presented: the advertised fingerprint must be that
  /// certificate's, and the advertised identity key must have signed it.
  /// A server that predates identity keys passes as long as the fingerprint
  /// matches.
  static bool isConsistent(ServerInfo info, String presentedFingerprint) {
    final advertised = info.tlsFingerprint;
    if (advertised == null ||
        CertificatePinner.normalize(advertised) !=
            CertificatePinner.normalize(presentedFingerprint)) {
      return false;
    }

    final key = info.identityKey;
    final signature = info.tlsBindingSignature;
    if (key == null || signature == null) return true;

    return verifyTlsBinding(
      publicKey: key,
      fingerprint: presentedFingerprint,
      signature: signature,
    );
  }

  /// Called after a pinned connection failed its certificate check. Asks the
  /// server who it is over a connection that accepts any certificate, sends
  /// nothing but that one unauthenticated request, and trusts the new
  /// certificate only if the identity key pinned for [serverId] signed it.
  ///
  /// Returns the new fingerprint (already pinned in [store]) or throws
  /// [ApiException.certificateMismatch].
  static Future<String> followCertificateChange({
    required String serverId,
    required String host,
    required int port,
    SecureStore store = const SecureStore(),
  }) async {
    final pinnedKey = await store.pinnedIdentityKey(serverId);

    // Nothing to vouch for a new certificate: this is exactly the case pinning
    // exists to refuse.
    if (pinnedKey == null) throw ApiException.certificateMismatch();

    final probe = ApiClient.forServer(host: host, port: port);
    try {
      final info = await UsersApi(probe).serverInfo();
      final presented = probe.pinner.observedFingerprint;

      // The platform accepted the certificate on its own (a CA-issued one), so
      // the pinner never ran; there is nothing to re-pin.
      if (presented == null) throw ApiException.certificateMismatch();

      final key = info.identityKey;
      if (key == null ||
          !_equal(key, pinnedKey) ||
          info.tlsBindingSignature == null ||
          !isConsistent(info, presented)) {
        throw ApiException.certificateMismatch();
      }

      await store.pinFingerprint(serverId, presented);
      return presented;
    } finally {
      probe.close();
    }
  }

  /// Pins [info]'s identity key for a server whose certificate is already
  /// pinned, when nothing was pinned for it before — a client upgrading from a
  /// version that did not know about identity keys, or a first connection.
  /// [presentedFingerprint] is the certificate the (pinned) connection saw.
  static Future<void> pinIdentityIfMissing({
    required String serverId,
    required ServerInfo info,
    required String presentedFingerprint,
    SecureStore store = const SecureStore(),
  }) async {
    final key = info.identityKey;
    if (key == null) return;
    if (await store.pinnedIdentityKey(serverId) != null) return;
    if (info.tlsBindingSignature == null ||
        !isConsistent(info, presentedFingerprint)) {
      return;
    }
    await store.pinIdentityKey(serverId, key);
  }

  static BigInt _unsigned(Uint8List bytes) {
    var result = BigInt.zero;
    for (final b in bytes) {
      result = (result << 8) | BigInt.from(b);
    }
    return result;
  }

  static bool _equal(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
