import 'dart:async';

import 'package:grpc/grpc.dart';

import 'api_exception.dart';
import 'tls_pinning.dart';

/// One gRPC connection to one Raindrop server: HTTP/2 inside TLS, the server's
/// certificate pinned the same way it always was. It knows nothing about
/// users, sessions or channels — the per-domain wrappers beside it
/// (`users_api.dart`, …) build their generated clients on [channel] and send
/// every call through [call], so pinning, the session token, deadlines and the
/// translation of a failure into an [ApiException] are done once, here.
class RaindropChannel {
  RaindropChannel._(this.channel, this.pinner, this.host, this.port);

  /// How long a unary call may take before it is given up as `network_error`.
  /// Streams have no deadline: they live as long as they are wanted.
  static const unaryTimeout = Duration(seconds: 20);

  /// [pinnedFingerprint] is the previously-trusted fingerprint for this
  /// server, or null to accept-and-record on first connection (TOFU).
  factory RaindropChannel.forServer({
    required String host,
    required int port,
    String? pinnedFingerprint,
  }) {
    final pinner = CertificatePinner(
      pinnedFingerprint: pinnedFingerprint,
      port: port,
    );
    final channel = ClientChannel(
      host,
      port: port,
      options: ChannelOptions(
        // Only consulted when the platform's own validation fails — the
        // self-signed certificate a Raindrop server generates. See
        // CertificatePinner.
        credentials: ChannelCredentials.secure(
          onBadCertificate: pinner.accepts,
        ),
        connectTimeout: const Duration(seconds: 10),
      ),
    );
    return RaindropChannel._(channel, pinner, host, port);
  }

  /// What the generated clients are built on.
  final ClientChannel channel;

  /// The pin this connection checks, and what the last handshake presented.
  final CertificatePinner pinner;

  final String host;
  final int port;

  /// Call options carrying the session [token] as `authorization` metadata —
  /// never anything else, never in a URL — and [timeout] as the deadline
  /// (none for streams).
  CallOptions options({String? token, Duration? timeout = unaryTimeout}) =>
      CallOptions(
        metadata: {'authorization': ?(token == null ? null : 'Bearer $token')},
        timeout: timeout,
      );

  /// Makes one unary call, turning any failure into an [ApiException].
  Future<T> call<T>(
    Future<T> Function(CallOptions options) send, {
    String? token,
    Duration? timeout = unaryTimeout,
  }) async {
    try {
      return await send(options(token: token, timeout: timeout));
    } on Object catch (error) {
      throw translate(error);
    }
  }

  /// [stream] with its failure, if any, turned into an [ApiException].
  Stream<T> stream<T>(Stream<T> stream) => stream.handleError(
    (Object error) => throw translate(error),
    test: (error) => error is! ApiException,
  );

  /// The [ApiException] a failed call amounts to.
  ///
  /// A refusal from the server carries its code as a `google.rpc.ErrorInfo`
  /// reason. A failure with no reason is the transport's: refused by the pin
  /// (`certificate_mismatch`), or the network or the server not answering
  /// (`network_error`).
  ApiException translate(Object error) {
    if (error is ApiException) return error;
    if (error is! GrpcError) return ApiException.network(error);

    final reason = ApiException.reasonOf(error);
    if (reason != null) {
      return ApiException(error.code, reason, error.message ?? reason);
    }

    // grpc reports a refused handshake as a failure to connect, with the
    // HandshakeException folded into the message; the pinner knows for sure.
    if (pinner.rejected) return ApiException.certificateMismatch();

    return switch (error.code) {
      StatusCode.unavailable ||
      StatusCode.deadlineExceeded ||
      StatusCode.cancelled => ApiException.network(error.message ?? error),
      _ => ApiException(
        error.code,
        error.code == StatusCode.unimplemented
            ? 'unimplemented'
            : 'unknown_error',
        error.message ?? 'Unexpected response (${error.codeName}).',
      ),
    };
  }

  Future<void> close() => channel.shutdown();
}
