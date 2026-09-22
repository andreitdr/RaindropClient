import 'dart:convert';
import 'dart:typed_data';

import 'api_client.dart';

/// Dart mirrors of the C# records in `RaindropServer/Users/Contracts.cs` and
/// `ServerIdentity.cs`. JSON is camelCased by ASP.NET's default serializer,
/// so `UserId` on the wire is `userId` here.
class ServerInfo {
  const ServerInfo({
    required this.protocolVersion,
    this.tlsFingerprint,
    required this.payloadFormats,
    this.identityKey,
    this.tlsBindingSignature,
    this.capabilities = const [],
  });

  final String protocolVersion;
  final String? tlsFingerprint;
  final List<String> payloadFormats;

  /// The server's long-lived P-256 identity key (uncompressed point), pinned
  /// alongside the fingerprint. See `ServerTrust`.
  final Uint8List? identityKey;

  /// [identityKey]'s signature over [tlsFingerprint].
  final Uint8List? tlsBindingSignature;

  /// Optional features the server offers, e.g. `tls.identity-binding.v1`.
  final List<String> capabilities;

  factory ServerInfo.fromJson(Map<String, dynamic> j) => ServerInfo(
    protocolVersion: j['protocolVersion'] as String,
    tlsFingerprint: j['tlsFingerprint'] as String?,
    payloadFormats: List<String>.from(j['payloadFormats'] as List? ?? const []),
    identityKey: _bytes(j['identityKey']),
    tlsBindingSignature: _bytes(j['tlsBindingSignature']),
    capabilities: List<String>.from(j['capabilities'] as List? ?? const []),
  );

  static Uint8List? _bytes(Object? value) =>
      value is String ? base64.decode(value) : null;
}

/// One of `active`, `left_preserved`, `erased` (an authenticated user's own state).
class UserProfile {
  const UserProfile({
    required this.userId,
    required this.username,
    required this.state,
    required this.createdAtUtc,
    this.lastLoginAtUtc,
  });

  final String userId;
  final String username;
  final String state;
  final DateTime createdAtUtc;
  final DateTime? lastLoginAtUtc;

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    userId: j['userId'] as String,
    username: j['username'] as String,
    state: j['state'] as String,
    createdAtUtc: DateTime.parse(j['createdAtUtc'] as String),
    lastLoginAtUtc: j['lastLoginAtUtc'] == null
        ? null
        : DateTime.parse(j['lastLoginAtUtc'] as String),
  );
}

/// What another member is allowed to see about a UUID (e.g. a message author).
class PublicUserProfile {
  const PublicUserProfile({
    required this.userId,
    this.username,
    required this.state,
  });

  final String userId;
  final String? username;
  final String state;

  factory PublicUserProfile.fromJson(Map<String, dynamic> j) =>
      PublicUserProfile(
        userId: j['userId'] as String,
        username: j['username'] as String?,
        state: j['state'] as String,
      );
}

class SessionResult {
  const SessionResult({
    required this.user,
    required this.token,
    required this.expiresAtUtc,
  });

  final UserProfile user;
  final String token;
  final DateTime expiresAtUtc;

  factory SessionResult.fromJson(Map<String, dynamic> j) => SessionResult(
    user: UserProfile.fromJson(Map<String, dynamic>.from(j['user'] as Map)),
    token: j['token'] as String,
    expiresAtUtc: DateTime.parse(j['expiresAtUtc'] as String),
  );
}

/// Which flow to show for a UUID before it has any credentials to offer:
/// `unregistered`/`erased` → registration, `active` → password, `left_preserved` → rejoin offer.
class UserStateResult {
  const UserStateResult({
    required this.userId,
    required this.state,
    this.username,
    this.dataExpiresAtUtc,
  });

  final String userId;
  final String state;
  final String? username;
  final DateTime? dataExpiresAtUtc;

  factory UserStateResult.fromJson(Map<String, dynamic> j) => UserStateResult(
    userId: j['userId'] as String,
    state: j['state'] as String,
    username: j['username'] as String?,
    dataExpiresAtUtc: j['dataExpiresAtUtc'] == null
        ? null
        : DateTime.parse(j['dataExpiresAtUtc'] as String),
  );
}

class UsernameAvailability {
  const UsernameAvailability({
    required this.username,
    required this.available,
    this.reason,
  });

  final String username;
  final bool available;
  final String? reason;

  factory UsernameAvailability.fromJson(Map<String, dynamic> j) =>
      UsernameAvailability(
        username: j['username'] as String,
        available: j['available'] as bool,
        reason: j['reason'] as String?,
      );
}

class LeaveResult {
  const LeaveResult({
    required this.state,
    this.dataExpiresAtUtc,
    required this.message,
  });

  final String state;
  final DateTime? dataExpiresAtUtc;
  final String message;

  factory LeaveResult.fromJson(Map<String, dynamic> j) => LeaveResult(
    state: j['state'] as String,
    dataExpiresAtUtc: j['dataExpiresAtUtc'] == null
        ? null
        : DateTime.parse(j['dataExpiresAtUtc'] as String),
    message: j['message'] as String,
  );
}

/// Typed wrapper over the `/api/users` + `/api/server/info` surface
/// documented in the server's CLAUDE.md. One instance per connected server,
/// built from that server's [ApiClient].
class UsersApi {
  UsersApi(this._client);

  final ApiClient _client;

  Future<ServerInfo> serverInfo() async =>
      ServerInfo.fromJson(await _client.get('/api/server/info'));

  Future<UserStateResult> status(String userId) async =>
      UserStateResult.fromJson(
        await _client.post('/api/users/status', body: {'userId': userId}),
      );

  Future<UsernameAvailability> usernameAvailable(String username) async =>
      UsernameAvailability.fromJson(
        await _client.post(
          '/api/users/username-available',
          body: {'username': username},
        ),
      );

  Future<SessionResult> register({
    required String userId,
    required String username,
    required String password,
  }) async => SessionResult.fromJson(
    await _client.post(
      '/api/users/register',
      body: {'userId': userId, 'username': username, 'password': password},
    ),
  );

  Future<SessionResult> login({
    String? userId,
    String? username,
    required String password,
  }) async => SessionResult.fromJson(
    await _client.post(
      '/api/users/login',
      body: {'userId': userId, 'username': username, 'password': password},
    ),
  );

  Future<SessionResult> rejoin({
    required String userId,
    required String password,
  }) async => SessionResult.fromJson(
    await _client.post(
      '/api/users/rejoin',
      body: {'userId': userId, 'password': password},
    ),
  );

  Future<void> logout(String token) =>
      _client.post('/api/users/logout', token: token);

  Future<UserProfile> me(String token) async =>
      UserProfile.fromJson(await _client.get('/api/users/me', token: token));

  Future<PublicUserProfile> lookup(String token, String userId) async =>
      PublicUserProfile.fromJson(
        await _client.post(
          '/api/users/lookup',
          body: {'userId': userId},
          token: token,
        ),
      );

  Future<SessionResult> changePassword(
    String token, {
    required String currentPassword,
    required String newPassword,
  }) async => SessionResult.fromJson(
    await _client.post(
      '/api/users/me/password',
      token: token,
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
    ),
  );

  Future<UserProfile> changeUsername(String token, String username) async =>
      UserProfile.fromJson(
        await _client.post(
          '/api/users/me/username',
          token: token,
          body: {'username': username},
        ),
      );

  Future<LeaveResult> leave(
    String token, {
    required String password,
    required bool preserveData,
  }) async => LeaveResult.fromJson(
    await _client.post(
      '/api/users/me/leave',
      token: token,
      body: {'password': password, 'preserveData': preserveData},
    ),
  );
}
