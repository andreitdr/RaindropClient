/// The app's view of `raindrop.v1.RoleService` (RaindropProto's `roles.proto`):
/// what the signed-in account may do server-wide, and managing roles.
///
/// A role is a named set of permissions; a member may do the union of every
/// role they hold. Roles and permissions belong to one server and never carry
/// over to another. Most permissions arrive per channel in
/// `ChannelSummary.yourPermissions`; what is not about one channel
/// (`create_channels`, `manage_roles`, …) is read here.
///
/// **Permissions are whatever the server's build offers.** A role editor draws
/// only from [RolesApi.permissions] — the catalogue the server sends — never
/// from a list in this client, so a server running an older build shows fewer
/// permissions and a newer one shows permissions this client was never built
/// with, titled and grouped by the server.
library;

import 'grpc/protocol.dart' as pb;
import 'grpc/wire.dart';
import 'raindrop_channel.dart';

/// The wire names of a role's kind.
abstract final class RoleKindNames {
  static const custom = 'custom';

  /// Every member holds it without being given it. Its permissions can be
  /// edited; its name cannot, and it cannot be deleted or handed out.
  static const everyone = 'everyone';

  /// Holds `administrator`. Neither editable nor deletable.
  static const owner = 'owner';
}

/// A role on one server.
class Role {
  const Role({
    required this.roleId,
    required this.name,
    required this.kind,
    required this.position,
    required this.permissions,
    required this.createdAtUtc,
  });

  final String roleId;
  final String name;

  /// [RoleKindNames.custom], [RoleKindNames.everyone] or [RoleKindNames.owner].
  final String kind;

  /// Presentation order, highest first. Nothing outranks anything else.
  final int position;

  /// Permission names, only those the server's build knows.
  final List<String> permissions;
  final DateTime createdAtUtc;

  bool get isOwner => kind == RoleKindNames.owner;
  bool get isEveryone => kind == RoleKindNames.everyone;
  bool get isCustom => !isOwner && !isEveryone;

  factory Role.fromProto(pb.Role m) => Role(
    roleId: m.roleId,
    name: m.name,
    kind: Wire.roleKind(m.kind),
    position: m.position,
    permissions: List.unmodifiable(m.permissions),
    createdAtUtc: Wire.time(m.createdAt),
  );
}

/// A role and the UUIDs of the members holding it, in the order they were
/// given it. Empty for the everyone role, which nobody is given.
class RoleDetail {
  const RoleDetail({required this.role, required this.memberIds});

  final Role role;
  final List<String> memberIds;

  factory RoleDetail.fromProto(pb.GetRoleResponse m) => RoleDetail(
    role: Role.fromProto(m.role),
    memberIds: List.unmodifiable(m.memberIds),
  );
}

/// The groups a role editor files permissions under. An open set: a server may
/// send a category this client does not know, which it files under [other].
abstract final class PermissionCategories {
  static const general = 'general';
  static const text = 'text';
  static const voice = 'voice';
  static const channels = 'channels';
  static const moderation = 'moderation';
  static const administration = 'administration';
  static const other = 'other';

  /// Display order, and each group's heading.
  static const titles = <String, String>{
    general: 'General',
    text: 'Text',
    voice: 'Voice',
    channels: 'Channels',
    moderation: 'Moderation',
    administration: 'Administration',
    other: 'Other',
  };
}

/// One permission a server's build understands, as its role editor shows it.
class PermissionInfo {
  const PermissionInfo({
    required this.name,
    required this.title,
    required this.summary,
    required this.category,
  });

  /// The wire name, e.g. `manage_roles`.
  final String name;
  final String title;
  final String summary;

  /// One of [PermissionCategories], [PermissionCategories.other] for a group
  /// this client does not know or a server too old to send one.
  final String category;

  /// A server older than titles sends none: `manage_roles` becomes
  /// "Manage roles".
  static String titleFromName(String name) {
    final words = name.split('_').where((w) => w.isNotEmpty).join(' ');
    return words.isEmpty ? name : words[0].toUpperCase() + words.substring(1);
  }

  factory PermissionInfo.fromProto(pb.PermissionDescription m) =>
      PermissionInfo(
        name: m.name,
        title: m.hasTitle() && m.title.trim().isNotEmpty
            ? m.title
            : titleFromName(m.name),
        summary: m.summary,
        category: PermissionCategories.titles.containsKey(m.category)
            ? m.category
            : PermissionCategories.other,
      );
}

/// What `RoleService.GetMyRoles` or `GetMemberRoles` says about one member:
/// their roles (the everyone role included) and the union of what they grant, with
/// `administrator` already expanded into every permission.
class MyRoles {
  const MyRoles({
    required this.userId,
    required this.permissions,
    this.roles = const [],
  });

  final String userId;
  final List<String> permissions;
  final List<Role> roles;

  bool can(String permission) => permissions.contains(permission);

  factory MyRoles.fromProto(pb.GetMyRolesResponse m) => MyRoles(
    userId: m.userId,
    permissions: List.unmodifiable(m.permissions),
    roles: List.unmodifiable(m.roles.map(Role.fromProto)),
  );

  factory MyRoles.fromMemberProto(pb.GetMemberRolesResponse m) => MyRoles(
    userId: m.userId,
    permissions: List.unmodifiable(m.permissions),
    roles: List.unmodifiable(m.roles.map(Role.fromProto)),
  );
}

/// `raindrop.v1.RoleService`. Reading is open to every member; writing needs
/// `manage_roles` and every permission involved, which the server checks.
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

  /// Every role on the server, highest position first.
  Future<List<Role>> list(String token) async {
    final response = await _channel.call(
      (o) => _roles.listRoles(pb.ListRolesRequest(), options: o),
      token: token,
    );
    return List.unmodifiable(response.roles.map(Role.fromProto));
  }

  /// The permissions this server's build understands, in the order an editor
  /// lists them.
  Future<List<PermissionInfo>> permissions(String token) async {
    final response = await _channel.call(
      (o) => _roles.listPermissions(pb.ListPermissionsRequest(), options: o),
      token: token,
    );
    return List.unmodifiable(
      response.permissions.map(PermissionInfo.fromProto),
    );
  }

  /// One role and who holds it.
  Future<RoleDetail> get(String token, String roleId) async =>
      RoleDetail.fromProto(
        await _channel.call(
          (o) => _roles.getRole(pb.GetRoleRequest(roleId: roleId), options: o),
          token: token,
        ),
      );

  Future<Role> create(
    String token, {
    required String name,
    required List<String> permissions,
  }) async {
    final response = await _channel.call(
      (o) => _roles.createRole(
        pb.CreateRoleRequest(name: name, permissions: permissions),
        options: o,
      ),
      token: token,
    );
    return Role.fromProto(response.role);
  }

  /// Edits a role. A null field is left alone; an empty [permissions] list
  /// clears them — the difference `PermissionSet` exists for.
  Future<Role> update(
    String token,
    String roleId, {
    String? name,
    List<String>? permissions,
  }) async {
    final request = pb.UpdateRoleRequest(roleId: roleId);
    if (name != null) request.name = name;
    if (permissions != null) {
      request.permissions = pb.PermissionSet(permissions: permissions);
    }
    final response = await _channel.call(
      (o) => _roles.updateRole(request, options: o),
      token: token,
    );
    return Role.fromProto(response.role);
  }

  Future<void> delete(String token, String roleId) async {
    await _channel.call(
      (o) =>
          _roles.deleteRole(pb.DeleteRoleRequest(roleId: roleId), options: o),
      token: token,
    );
  }

  /// One member's roles (the everyone role included) and what they add up to.
  Future<MyRoles> ofMember(String token, String userId) async =>
      MyRoles.fromMemberProto(
        await _channel.call(
          (o) => _roles.getMemberRoles(
            pb.GetMemberRolesRequest(userId: userId),
            options: o,
          ),
          token: token,
        ),
      );

  /// Gives [userId] the role. False when they already held it.
  Future<bool> assign(String token, String userId, String roleId) async {
    final response = await _channel.call(
      (o) => _roles.assignRole(
        pb.AssignRoleRequest(userId: userId, roleId: roleId),
        options: o,
      ),
      token: token,
    );
    return response.changed;
  }

  /// Takes the role from [userId]. False when they did not hold it.
  Future<bool> unassign(String token, String userId, String roleId) async {
    final response = await _channel.call(
      (o) => _roles.unassignRole(
        pb.UnassignRoleRequest(userId: userId, roleId: roleId),
        options: o,
      ),
      token: token,
    );
    return response.changed;
  }
}
