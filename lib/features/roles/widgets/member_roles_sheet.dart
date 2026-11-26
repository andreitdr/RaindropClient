import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/roles_api.dart';
import '../../../core/widgets/adaptive.dart';
import '../../servers/controllers/server_permissions.dart';
import '../controllers/roles_controller.dart';

/// Shows one member's roles from the member list, with a checkbox per role
/// for a caller who may hand it out. Everybody may look; changing needs
/// `manage_roles` and every permission the role grants.
Future<void> showMemberRolesSheet(
  BuildContext context, {
  required String serverId,
  required String userId,
  required String username,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) =>
      MemberRolesSheet(serverId: serverId, userId: userId, username: username),
);

class MemberRolesSheet extends ConsumerStatefulWidget {
  const MemberRolesSheet({
    super.key,
    required this.serverId,
    required this.userId,
    required this.username,
  });

  final String serverId;
  final String userId;
  final String username;

  @override
  ConsumerState<MemberRolesSheet> createState() => _MemberRolesSheetState();
}

class _MemberRolesSheetState extends ConsumerState<MemberRolesSheet> {
  /// The role being changed, so its checkbox waits for the server.
  String? _changing;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final serverId = widget.serverId;
    final roles = ref.watch(rolesProvider(serverId));
    final theirs = ref.watch(
      memberRolesProvider((serverId: serverId, userId: widget.userId)),
    );
    final held = ref
        .watch(serverPermissionsProvider(serverId))
        .valueOrNull
        ?.permissions;

    final body = switch ((roles, theirs)) {
      (AsyncData(value: final all?), AsyncData(value: final member?)) => _list(
        all,
        member,
        held,
      ),
      (AsyncError(), _) ||
      (_, AsyncError()) ||
      (AsyncData(value: null), _) ||
      (_, AsyncData(value: null)) => const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Their roles could not be read.'),
      ),
      _ => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: AdaptiveActivityIndicator()),
      ),
    };

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                '${widget.username}’s roles',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Flexible(child: body),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _list(List<Role> all, MyRoles member, List<String>? held) {
    final holds = {for (final r in member.roles) r.roleId};
    // Everyone is not handed out: every member holds it already.
    final roles = sortRoles(all.where((r) => !r.isEveryone));

    return ListView(
      shrinkWrap: true,
      children: [
        for (final role in roles)
          CheckboxListTile(
            title: Text(role.name),
            subtitle: role.isOwner
                ? const Text('Administers this server')
                : null,
            value: holds.contains(role.roleId),
            onChanged: _changing == null && canGrantAll(held, role.permissions)
                ? (on) => _set(role, on ?? false)
                : null,
          ),
        if (!canManage(held))
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text('Changing roles needs the Manage roles permission.'),
          ),
      ],
    );
  }

  Future<void> _set(Role role, bool give) async {
    setState(() {
      _changing = role.roleId;
      _error = null;
    });
    final roles = ref.read(rolesProvider(widget.serverId).notifier);
    try {
      if (give) {
        await roles.assign(widget.userId, role.roleId);
      } else {
        await roles.unassign(widget.userId, role.roleId);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _changing = null);
    }
  }
}
