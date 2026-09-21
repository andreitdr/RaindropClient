import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import 'api_exception.dart';
import 'tls_pinning.dart';

/// A thin HTTP client bound to one Raindrop server. It knows nothing about
/// users, sessions, or channels — that lives in per-domain API wrappers
/// (see `users_api.dart`) built on top of this. Kept generic so future
/// domains (messages, voice signaling) reuse the same pinning and error
/// handling instead of re-deriving it.
class ApiClient {
  ApiClient._(this._dio, this.pinner, this._host, this._port);

  final Dio _dio;
  final CertificatePinner pinner;
  final String _host;
  final int _port;

  /// [pinnedFingerprint] is the previously-trusted fingerprint for this
  /// server, or null to accept-and-record on first connection (TOFU).
  factory ApiClient.forServer({
    required String host,
    required int port,
    String? pinnedFingerprint,
  }) {
    final pinner = CertificatePinner(pinnedFingerprint: pinnedFingerprint);
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://$host:$port',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        // We parse the {error, message} body ourselves for any non-2xx.
        validateStatus: (_) => true,
      ),
    );
    final adapter = dio.httpClientAdapter;
    if (adapter is IOHttpClientAdapter) {
      adapter.createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = pinner.call;
        return client;
      };
    }
    return ApiClient._(dio, pinner, host, port);
  }

  Future<Map<String, dynamic>> get(String path, {String? token}) =>
      _send('GET', path, token: token);

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) => _send('POST', path, body: body, token: token);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    Response<dynamic> response;
    try {
      response = await _dio.request<dynamic>(
        path,
        data: body,
        options: Options(
          method: method,
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );
    } on DioException catch (e) {
      final inner = e.error;
      if (inner is HandshakeException) {
        throw ApiException.certificateMismatch();
      }
      throw ApiException.network(e.message ?? e.toString());
    }

    final status = response.statusCode ?? 0;
    final data = response.data;
    if (status >= 200 && status < 300) {
      return data is Map
          ? Map<String, dynamic>.from(data)
          : <String, dynamic>{};
    }
    throw ApiException.fromResponseBody(status, data);
  }

  /// Opens a WebSocket to [path] on this server — the event stream — through
  /// the same certificate pin and the same `Authorization: Bearer` header as
  /// every other call. The token never goes in the URL, same rule as the rest
  /// of the API.
  ///
  /// The upgrade is done by hand over an [HttpClient] rather than with
  /// `WebSocket.connect`, because that reports every refused upgrade the same
  /// way; doing it here keeps the status code and the server's
  /// `{error, message}` body, so a `401` surfaces as `invalid_session` just as
  /// it would from [get].
  Future<WebSocket> openWebSocket(String path, {String? token}) async {
    final http = HttpClient()
      ..badCertificateCallback = pinner.call
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final key = base64.encode(
        List<int>.generate(16, (_) => Random.secure().nextInt(256)),
      );
      final request = await http.getUrl(Uri.https('$_host:$_port', path));
      request.headers
        ..set(HttpHeaders.connectionHeader, 'Upgrade')
        ..set(HttpHeaders.upgradeHeader, 'websocket')
        ..set('Sec-WebSocket-Version', '13')
        ..set('Sec-WebSocket-Key', key)
        ..set(HttpHeaders.acceptHeader, 'application/json');
      if (token != null) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }

      final response = await request.close();
      if (response.statusCode != HttpStatus.switchingProtocols) {
        final text = await utf8.decodeStream(response);
        Object? body;
        try {
          body = text.isEmpty ? null : jsonDecode(text);
        } on FormatException {
          body = null;
        }
        throw ApiException.fromResponseBody(response.statusCode, body);
      }

      // RFC 6455: the server proves it understood the upgrade by hashing our
      // key with a fixed GUID. Anything else is not a WebSocket server.
      final expected = base64.encode(
        sha1
            .convert(utf8.encode('${key}258EAFA5-E914-47DA-95CA-C5AB0DC85B11'))
            .bytes,
      );
      if (response.headers.value('sec-websocket-accept') != expected) {
        throw ApiException.network('the server did not accept the upgrade');
      }

      final socket = await response.detachSocket();
      return WebSocket.fromUpgradedSocket(socket, serverSide: false);
    } on HandshakeException {
      throw ApiException.certificateMismatch();
    } on SocketException catch (e) {
      throw ApiException.network(e.message);
    } on HttpException catch (e) {
      throw ApiException.network(e.message);
    } finally {
      // Detaching hands the socket over, so closing the client does not
      // touch the connection that was just upgraded.
      http.close();
    }
  }

  void close() => _dio.close(force: true);
}
