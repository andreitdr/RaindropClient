/// The part of `raindrop.v1.RoleService` (RaindropProto's `roles.proto`) this
/// client reads: what the signed-in account may do server-wide.
///
/// Most permissions arrive per channel in `ChannelSummary.yourPermissions`.
/// `create_channels` is the exception — it is not about any one channel, and
/// a server with no channels has nowhere to report it — so it is read here.
library;

import 'grpc/protocol.dart' as pb;
import 'raindrop_channel.dart';

/// What `RoleService.GetMyRoles` says about the caller: the union of their roles,
/// with `administrator` already expanded into every permission.
class MyRoles {
  const MyRoles({required this.userId, required this.permissions});

  final String userId;
  final List<String> permissions;

  bool can(String permission) => permissions.contains(permission);

  factory MyRoles.fromProto(pb.GetMyRolesResponse m) =>
      MyRoles(userId: m.userId, permissions: List.unmodifiable(m.permissions));
}

/// `raindrop.v1.RoleService`. Only the read this client needs so far;
/// managing roles is not part of it.
class RolesApi {
  RolesApi(this._channel) : _roles = pb.RoleServiceClient(_channel.channel);

  final RaindropChannel _channel;
  final pb.RoleServiceClient _roles;

  /// The caller's own roles and what they add up to, server-wide.
  Future<MyRoles> me(String token) async => MyRoles.fromProto(
    await _channel.call(
      (o) => _roles.getMyRoles(pb.GetMyRolesRequest(), options: o),
      token: token,
    ),
  );
}
