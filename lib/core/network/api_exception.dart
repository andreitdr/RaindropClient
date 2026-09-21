/// Thrown for every failure that reaches API-calling code: a structured
/// `{ "error", "message" }` body from the server, a transport failure, or a
/// client-side TLS pin mismatch. UI code branches on [code] the same way the
/// server's own error codes are documented (`username_taken`,
/// `invalid_credentials`, `certificate_mismatch`, ...).
class ApiException implements Exception {
  const ApiException(this.statusCode, this.code, this.message);

  final int statusCode;
  final String code;
  final String message;

  factory ApiException.fromResponseBody(int statusCode, Object? data) {
    if (data is Map && data['error'] != null) {
      return ApiException(
        statusCode,
        data['error'].toString(),
        (data['message'] ?? data['error']).toString(),
      );
    }
    return ApiException(
      statusCode,
      'unknown_error',
      'Unexpected response ($statusCode).',
    );
  }

  factory ApiException.certificateMismatch() => const ApiException(
    0,
    'certificate_mismatch',
    "This server's TLS certificate does not match the one pinned for it. "
        'It may have changed legitimately (ask the owner), or this network '
        'connection may not be trustworthy.',
  );

  factory ApiException.network(Object error) =>
      ApiException(0, 'network_error', 'Could not reach the server: $error');

  bool get isCertificateMismatch => code == 'certificate_mismatch';

  @override
  String toString() => message;
}
