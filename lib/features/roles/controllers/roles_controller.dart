import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/event_stream.dart';
import '../../../core/network/roles_api.dart';
import '../../servers/controllers/live_sync.dart';
import '../../servers/controllers/session_controller.dart';

/// Whether [event] can change a role, or who holds one.
bool isRoleEvent(ServerEvent event) => switch (event.type) {
  ServerEventTypes.roleCreated ||
  ServerEventTypes.roleUpdated ||
  ServerEventTypes.roleDeleted ||
  ServerEventTypes.memberRoles => true,
  _ => false,
};

/// Follows the event stream for a role read: any role event, and every
/// reconnect, reads it again. Role changes are rare, so re-reading is simpler
/// and safer than merging, and a stale role is a wrong button.
void _rereadOnRoleEvents(Ref ref, String serverId) {
  LiveSync(
    ref,
    serverId: serverId,
    onEvent: (event) {
      if (isRoleEvent(event)) ref.invalidateSelf();
    },
    resync: () async => ref.invalidateSelf(),
  );
}

/// The permissions one server's build understands, in the order its role
/// editor lists them — `RoleService.ListPermissions`. **The only list a role
/// editor draws from**: an older server offers fewer permissions, a newer one
/// offers permissions this client was never built with, and each server shows
/// exactly what it has. Null when it cannot be read (signed out, or a server
/// without role management), which hides the editor.
final permissionCatalogueProvider = FutureProvider.autoDispose
    .family<List<PermissionInfo>?, String>((ref, serverId) async {
      final session = await ref.watch(serverSessionProvider(serverId).future);
      if (session == null) return null;
      try {
        return await session.rolesApi.permissions(session.token);
      } on ApiException {
        return null;
      }
    });

/// One role and who holds it, kept current by the event stream. Null when it
/// cannot be read — deleted, or the server has no role management.
typedef RoleRef = ({String serverId, String roleId});

final roleDetailProvider = FutureProvider.autoDispose
    .family<RoleDetail?, RoleRef>((ref, which) async {
      final session = await ref.watch(
        serverSessionProvider(which.serverId).future,
      );
      if (session == null) return null;
      _rereadOnRoleEvents(ref, which.serverId);
      try {
        return await session.rolesApi.get(session.token, which.roleId);
      } on ApiException {
        return null;
      }
    });

/// Which roles one member holds, and what they add up to.
typedef MemberRef = ({String serverId, String userId});

final memberRolesProvider = FutureProvider.autoDispose
    .family<MyRoles?, MemberRef>((ref, who) async {
      final session = await ref.watch(
        serverSessionProvider(who.serverId).future,
      );
      if (session == null) return null;
      _rereadOnRoleEvents(ref, who.serverId);
      try {
        return await session.rolesApi.ofMember(session.token, who.userId);
      } on ApiException {
        return null;
      }
    });

/// Every role on a server, highest position first, kept current by the event
/// stream, and the writes that change them. Null when the server cannot list
/// roles — signed out, or a build without role management — which hides the
/// Roles page rather than offering something the server would refuse.
final rolesProvider = AsyncNotifierProvider.autoDispose
    .family<RolesController, List<Role>?, String>(RolesController.new);

class RolesController
    extends AutoDisposeFamilyAsyncNotifier<List<Role>?, String> {
  ServerSession? _session;

  @override
  Future<List<Role>?> build(String serverId) async {
    final session = await ref.watch(serverSessionProvider(serverId).future);
    _session = session;
    if (session == null) return null;

    _rereadOnRoleEvents(ref, serverId);

    try {
      return await session.rolesApi.list(session.token);
    } on ApiException {
      return null;
    }
  }

  // ── Changing roles ───────────────────────────────────────────────────────
  //
  // Each throws the server's [ApiException] for the caller to show
  // (`role_name_taken`, `missing_permission`, …). The list is not patched by
  // hand: the server's `role.*` event re-reads it, here and on every other
  // client.

  /// Creates a role and returns it as the server made it.
  Future<Role> create(String name, List<String> permissions) {
    final session = _requireSession();
    return session.rolesApi.create(
      session.token,
      name: name,
      permissions: permissions,
    );
  }

  /// Renames a role or replaces its permissions; a null field is left alone.
  Future<Role> save(String roleId, {String? name, List<String>? permissions}) {
    final session = _requireSession();
    return session.rolesApi.update(
      session.token,
      roleId,
      name: name,
      permissions: permissions,
    );
  }

  Future<void> delete(String roleId) {
    final session = _requireSession();
    return session.rolesApi.delete(session.token, roleId);
  }

  Future<bool> assign(String userId, String roleId) {
    final session = _requireSession();
    return session.rolesApi.assign(session.token, userId, roleId);
  }

  Future<bool> unassign(String userId, String roleId) {
    final session = _requireSession();
    return session.rolesApi.unassign(session.token, userId, roleId);
  }

  ServerSession _requireSession() =>
      _session ?? (throw StateError('Not signed in to this server.'));
}

/// What the server would say to a role write, said before it is sent: the
/// caller needs `manage_roles`, and may only hand out, take away or change a
/// role granting permissions they hold themselves. [callerPermissions] is the
/// caller's own expanded set (`GetMyRoles`), so an administrator holds
/// everything. The server checks again; this only keeps the UI from offering
/// what it would refuse.
bool canManage(Iterable<String>? callerPermissions) =>
    callerPermissions?.contains('manage_roles') ?? false;

/// Whether the caller may give or change a role that grants [permissions].
bool canGrantAll(
  Iterable<String>? callerPermissions,
  Iterable<String> permissions,
) {
  final held = callerPermissions?.toSet() ?? const <String>{};
  if (!held.contains('manage_roles')) return false;
  return permissions.every(held.contains);
}

/// The roles a role list shows first: everyone, then the rest by position,
/// highest first, then by name.
List<Role> sortRoles(Iterable<Role> roles) {
  final sorted = roles.toList()
    ..sort((a, b) {
      if (a.isEveryone != b.isEveryone) return a.isEveryone ? -1 : 1;
      final byPosition = b.position.compareTo(a.position);
      if (byPosition != 0) return byPosition;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  return sorted;
}

/// [permissions] grouped for an editor: in [PermissionCategories.titles]'
/// order, each group in the order the server listed it, empty groups left out.
List<({String category, String title, List<PermissionInfo> permissions})>
groupPermissions(Iterable<PermissionInfo> permissions) => [
  for (final entry in PermissionCategories.titles.entries)
    if (permissions.where((p) => p.category == entry.key).toList()
        case final group when group.isNotEmpty)
      (category: entry.key, title: entry.value, permissions: group),
];
