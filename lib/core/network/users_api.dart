import 'dart:typed_data';

import 'grpc/protocol.dart' as pb;
import 'grpc/wire.dart';
import 'raindrop_channel.dart';

/// The app's view of `raindrop.v1.ServerService` and `UserService`
/// (RaindropProto's `server.proto` and `users.proto`): plain models the UI
/// works with, read from the protobuf messages by their `fromProto`
/// factories.
class ServerInfo {
  const ServerInfo({
    required this.protocolVersion,
    this.tlsFingerprint,
    this.identityKey,
    this.tlsBindingSignature,
    this.capabilities = const [],
  });

  final String protocolVersion;
  final String? tlsFingerprint;

  /// The server's long-lived P-256 identity key (uncompressed point), pinned
  /// alongside the fingerprint. See `ServerTrust`.
  final Uint8List? identityKey;

  /// [identityKey]'s signature over [tlsFingerprint].
  final Uint8List? tlsBindingSignature;

  /// Optional features the server offers, e.g. `tls.identity-binding.v1`.
  final List<String> capabilities;

  factory ServerInfo.fromProto(pb.GetServerInfoResponse m) => ServerInfo(
    protocolVersion: m.protocolVersion,
    tlsFingerprint: m.hasTlsFingerprint() ? m.tlsFingerprint : null,
    identityKey: Wire.optionalBytes(m.hasIdentityKey(), m.identityKey),
    tlsBindingSignature: Wire.optionalBytes(
      m.hasTlsBindingSignature(),
      m.tlsBindingSignature,
    ),
    capabilities: List.unmodifiable(m.capabilities),
  );
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

  factory UserProfile.fromProto(pb.UserProfile m) => UserProfile(
    userId: m.userId,
    username: m.username,
    state: Wire.userState(m.state),
    createdAtUtc: Wire.time(m.createdAt),
    lastLoginAtUtc: Wire.optionalTime(m.hasLastLoginAt(), m.lastLoginAt),
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

  factory PublicUserProfile.fromProto(pb.PublicUserProfile m) =>
      PublicUserProfile(
        userId: m.userId,
        username: m.hasUsername() ? m.username : null,
        state: Wire.userState(m.state),
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

  factory SessionResult.fromProto(pb.Session m) => SessionResult(
    user: UserProfile.fromProto(m.user),
    token: m.token,
    expiresAtUtc: Wire.time(m.expiresAt),
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

  factory UserStateResult.fromProto(pb.GetUserStatusResponse m) =>
      UserStateResult(
        userId: m.userId,
        state: Wire.userState(m.state),
        username: m.hasUsername() ? m.username : null,
        dataExpiresAtUtc: Wire.optionalTime(
          m.hasDataExpiresAt(),
          m.dataExpiresAt,
        ),
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

  factory UsernameAvailability.fromProto(pb.CheckUsernameResponse m) =>
      UsernameAvailability(
        username: m.username,
        available: m.available,
        reason: m.hasReason() ? m.reason : null,
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

  factory LeaveResult.fromProto(pb.LeaveServerResponse m) => LeaveResult(
    state: Wire.userState(m.state),
    dataExpiresAtUtc: Wire.optionalTime(m.hasDataExpiresAt(), m.dataExpiresAt),
    message: m.message,
  );
}

/// `raindrop.v1.UserService`, plus the handshake in `ServerService`. One
/// instance per connected server, built on that server's [RaindropChannel].
/// Every call either answers or throws an `ApiException`.
class UsersApi {
  UsersApi(this._channel)
    : _server = pb.ServerServiceClient(_channel.channel),
      _users = pb.UserServiceClient(_channel.channel);

  final RaindropChannel _channel;
  final pb.ServerServiceClient _server;
  final pb.UserServiceClient _users;

  /// The handshake: the one call made before anything is pinned or signed in.
  Future<ServerInfo> serverInfo() async => ServerInfo.fromProto(
    await _channel.call(
      (o) => _server.getServerInfo(pb.GetServerInfoRequest(), options: o),
    ),
  );

  Future<UserStateResult> status(String userId) async =>
      UserStateResult.fromProto(
        await _channel.call(
          (o) => _users.getUserStatus(
            pb.GetUserStatusRequest(userId: userId),
            options: o,
          ),
        ),
      );

  Future<UsernameAvailability> usernameAvailable(String username) async =>
      UsernameAvailability.fromProto(
        await _channel.call(
          (o) => _users.checkUsername(
            pb.CheckUsernameRequest(username: username),
            options: o,
          ),
        ),
      );

  Future<SessionResult> register({
    required String userId,
    required String username,
    required String password,
  }) async => SessionResult.fromProto(
    (await _channel.call(
      (o) => _users.register(
        pb.RegisterRequest(
          userId: userId,
          username: username,
          password: password,
        ),
        options: o,
      ),
    )).session,
  );

  Future<SessionResult> login({
    String? userId,
    String? username,
    required String password,
  }) async => SessionResult.fromProto(
    (await _channel.call(
      (o) => _users.login(
        pb.LoginRequest(userId: userId, username: username, password: password),
        options: o,
      ),
    )).session,
  );

  /// Restores a preserved account. Like [login], the username stands in for
  /// the UUID when the client no longer has it — it stays reserved for as
  /// long as the account is preserved.
  Future<SessionResult> rejoin({
    String? userId,
    String? username,
    required String password,
  }) async => SessionResult.fromProto(
    (await _channel.call(
      (o) => _users.rejoin(
        pb.RejoinRequest(
          userId: userId,
          username: username,
          password: password,
        ),
        options: o,
      ),
    )).session,
  );

  Future<void> logout(String token) => _channel.call(
    (o) => _users.logout(pb.LogoutRequest(), options: o),
    token: token,
  );

  Future<UserProfile> me(String token) async => UserProfile.fromProto(
    (await _channel.call(
      (o) => _users.getMe(pb.GetMeRequest(), options: o),
      token: token,
    )).user,
  );

  Future<PublicUserProfile> lookup(String token, String userId) async =>
      PublicUserProfile.fromProto(
        (await _channel.call(
          (o) => _users.lookupUser(
            pb.LookupUserRequest(userId: userId),
            options: o,
          ),
          token: token,
        )).user,
      );

  Future<SessionResult> changePassword(
    String token, {
    required String currentPassword,
    required String newPassword,
  }) async => SessionResult.fromProto(
    (await _channel.call(
      (o) => _users.changePassword(
        pb.ChangePasswordRequest(
          currentPassword: currentPassword,
          newPassword: newPassword,
        ),
        options: o,
      ),
      token: token,
    )).session,
  );

  Future<UserProfile> changeUsername(String token, String username) async =>
      UserProfile.fromProto(
        (await _channel.call(
          (o) => _users.changeUsername(
            pb.ChangeUsernameRequest(username: username),
            options: o,
          ),
          token: token,
        )).user,
      );

  Future<LeaveResult> leave(
    String token, {
    required String password,
    required bool preserveData,
  }) async => LeaveResult.fromProto(
    await _channel.call(
      (o) => _users.leaveServer(
        pb.LeaveServerRequest(password: password, preserveData: preserveData),
        options: o,
      ),
      token: token,
    ),
  );
}
