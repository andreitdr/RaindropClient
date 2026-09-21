/// Process-wide certificate pinning for connections this client does not
/// open itself — LiveKit's signalling socket, which the voice library builds
/// with a plain `HttpClient` that [ApiClient]'s own pinning never reaches.
///
/// It is installed as [HttpOverrides.global] before `runApp`, so every
/// `HttpClient` the process creates falls back to it when the platform's own
/// certificate check fails — exactly the self-signed-certificate case, as with
/// [CertificatePinner]. A host that nothing has been pinned for is refused, so
/// the override never loosens trust for anything but a Raindrop server this
/// client has already pinned.
///
/// The voice library's own pinning option is deliberately not used: it
/// verifies the chain and the hostname before it ever looks at a pin, which a
/// self-signed certificate — and a server reached by an address its
/// certificate does not name — never passes.
library;

import 'dart:io';

import 'package:crypto/crypto.dart';

import 'tls_pinning.dart';

class PinRegistry {
  PinRegistry._();

  static final PinRegistry instance = PinRegistry._();

  final Map<String, String> _pins = {};

  /// Accepts [fingerprint] (as [CertificatePinner] records it) for
  /// [host]:[port] from now on.
  void pin(String host, int port, String fingerprint) =>
      _pins[_key(host, port)] = CertificatePinner.normalize(fingerprint);

  void unpin(String host, int port) => _pins.remove(_key(host, port));

  /// The [HttpClient.badCertificateCallback] every overridden client gets.
  bool accepts(X509Certificate cert, String host, int port) {
    final pinned = _pins[_key(host, port)];
    if (pinned == null) return false;
    return CertificatePinner.normalize(sha256.convert(cert.der).toString()) ==
        pinned;
  }

  static String _key(String host, int port) => '${host.toLowerCase()}:$port';
}

/// Gives every `HttpClient` in the process [PinRegistry]'s fallback. Clients
/// that set their own callback — [ApiClient] does — replace it, which is
/// fine: theirs pins the same fingerprint.
class PinnedHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      super.createHttpClient(context)
        ..badCertificateCallback = PinRegistry.instance.accepts;
}
