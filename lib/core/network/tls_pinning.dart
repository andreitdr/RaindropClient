import 'dart:io';

import 'package:crypto/crypto.dart';

/// Implements the same trust-on-first-use model the server documents for
/// SSH-style pinning: the first connection to a server accepts whatever
/// certificate it presents and records its fingerprint; every connection
/// after that requires an exact match, matching how the server computes it
/// (`Convert.ToHexString(SHA256.HashData(certificate.RawData))` — uppercase
/// hex of the SHA-256 over the DER-encoded certificate, no separators).
///
/// This is wired in as [HttpClient.badCertificateCallback], which only fires
/// when the platform's normal certificate validation *fails* — exactly the
/// case for the self-signed certificate a Raindrop server generates by
/// default. A CA-issued certificate validates normally and this callback
/// never runs for it, which matches the server's own documented trust model.
class CertificatePinner {
  CertificatePinner({required this.pinnedFingerprint});

  /// The fingerprint previously pinned for this server, or null on a first
  /// connection where nothing has been pinned yet.
  final String? pinnedFingerprint;

  /// The fingerprint of whatever certificate was actually presented, set as
  /// a side effect of the TLS handshake. The caller pins this after a
  /// successful first connection.
  String? observedFingerprint;

  bool call(X509Certificate cert, String host, int port) {
    final fingerprint = sha256.convert(cert.der).toString();
    observedFingerprint = fingerprint;
    if (pinnedFingerprint == null) return true;
    return normalize(fingerprint) == normalize(pinnedFingerprint!);
  }

  /// Lower-case hex with no separators, so a fingerprint copied from the
  /// server's console (colon-separated, upper case) compares equal.
  static String normalize(String fingerprint) =>
      fingerprint.toLowerCase().replaceAll(RegExp('[^0-9a-f]'), '');
}
