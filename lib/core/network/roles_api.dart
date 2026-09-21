/// Dart mirror of the part of `RaindropServer/Roles/RoleContracts.cs` this
/// client reads: what the signed-in account may do server-wide.
///
/// Most permissions arrive per channel in `ChannelSummary.yourPermissions`.
/// `create_channels` is the exception — it is not about any one channel, and
/// a server with no channels has nowhere to report it — so it is read here.
library;

import 'api_client.dart';

/// What `GET /api/roles/me` says about the caller: the union of their roles,
/// with `administrator` already expanded into every permission.
class MyRoles {
  const MyRoles({required this.userId, required this.permissions});

  final String userId;
  final List<String> permissions;

  bool can(String permission) => permissions.contains(permission);

  factory MyRoles.fromJson(Map<String, dynamic> j) => MyRoles(
    userId: j['userId'] as String,
    permissions: List<String>.from(j['permissions'] as List? ?? const []),
  );
}

/// Typed wrapper over the `/api/roles` surface. Only the read this client
/// needs so far; managing roles is not part of it.
class RolesApi {
  RolesApi(this._client);

  final ApiClient _client;

  /// The caller's own roles and what they add up to, server-wide.
  Future<MyRoles> me(String token) async =>
      MyRoles.fromJson(await _client.get('/api/roles/me', token: token));
}
