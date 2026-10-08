import 'package:grpc/grpc.dart';

/// Thrown for every failure that reaches API-calling code: a refusal from the
/// server, a transport failure, or a client-side TLS pin mismatch. UI code
/// branches on [code] — the server's error code (`username_taken`,
/// `invalid_credentials`, …, every one listed in RaindropProto's
/// `docs/errors.md`), or one of this client's own (`certificate_mismatch`,
/// `network_error`) — and shows [message], which the server writes for people.
class ApiException implements Exception {
  const ApiException(this.statusCode, this.code, this.message);

  /// The gRPC status code ([StatusCode]), or 0 for a failure that never
  /// reached the server. For logs and the odd generic decision only: [code]
  /// is the contract.
  final int statusCode;
  final String code;
  final String message;

  /// The `ErrorInfo.domain` every Raindrop refusal carries.
  static const errorDomain = 'raindrop';

  /// The Raindrop error code in [error]'s `grpc-status-details-bin` trailer —
  /// the `reason` of a `google.rpc.ErrorInfo` from [errorDomain] — or null
  /// when the failure carries none.
  ///
  /// Read by type name and field number rather than through `ErrorInfo`
  /// itself: package:grpc decodes the trailer with its own copy of
  /// `error_details.proto`, which it does not export.
  static String? reasonOf(GrpcError error) {
    for (final detail in error.details ?? const []) {
      if (detail.info_.qualifiedMessageName != 'google.rpc.ErrorInfo') continue;
      final reason = detail.getFieldOrNull(1); // reason
      final domain = detail.getFieldOrNull(2); // domain
      if (domain == errorDomain && reason is String && reason.isNotEmpty) {
        return reason;
      }
    }
    return null;
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
