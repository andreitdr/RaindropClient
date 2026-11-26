import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/roles_api.dart';
import '../../../core/widgets/adaptive.dart';
import '../../servers/controllers/server_permissions.dart';
import '../../settings/widgets/settings_app_bar.dart';
import '../../settings/widgets/settings_section_label.dart';
import '../controllers/roles_controller.dart';

/// The route of one server's role list.
String rolesRoute(String serverId) => '/servers/$serverId/roles';

/// The route of the editor for [roleId], or for a new role when it is null.
String roleEditorRoute(String serverId, [String? roleId]) =>
    '${rolesRoute(serverId)}/${roleId ?? 'new'}';

/// One server's roles (`/servers/:serverId/roles`). A role is a named set of
/// permissions; a member may do everything any of their roles allows. Roles
/// belong to this server alone.
///
/// Anybody may read the list. Creating and editing need `manage_roles`, and
/// the server lets nobody hand out a permission they do not hold themselves —
/// the editor greys those out.
class RolesScreen extends ConsumerWidget {
  const RolesScreen({super.key, required this.serverId});

  final String serverId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roles = ref.watch(rolesProvider(serverId));
    final catalogue = ref.watch(permissionCatalogueProvider(serverId));
    final mine = ref.watch(serverPermissionsProvider(serverId)).valueOrNull;

    return Scaffold(
      appBar: settingsAppBar(context, title: const Text('Roles')),
      body: roles.when(
        loading: () => const Center(child: AdaptiveActivityIndicator()),
        error: (error, _) => _Message('Could not load the roles: $error'),
        data: (roles) {
          if (roles == null) {
            return const _Message(
              'This server does not offer role management, or you are not '
              'signed in to it.',
            );
          }
          final total = catalogue.valueOrNull?.length;
          final sorted = sortRoles(roles);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Members can do everything any of their roles allows. Roles '
                'and their permissions belong to this server only.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              const SettingsSectionLabel('Roles'),
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final (i, role) in sorted.indexed) ...[
                      if (i > 0) const Divider(height: 1),
                      ListTile(
                        leading: Icon(_iconFor(role)),
                        title: Text(role.name),
                        subtitle: Text(describeRole(role, total)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(
                          roleEditorRoute(serverId, role.roleId),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (canManage(mine?.permissions))
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('New role'),
                      onPressed: () => context.push(roleEditorRoute(serverId)),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static IconData _iconFor(Role role) => role.isOwner
      ? Icons.workspace_premium_outlined
      : role.isEveryone
      ? Icons.groups_outlined
      : Icons.shield_outlined;
}

/// One line about what a role grants, for a list. [total] is how many
/// permissions the server knows, when the catalogue has been read.
String describeRole(Role role, int? total) {
  final kind = role.isOwner
      ? 'Built in · '
      : role.isEveryone
      ? 'Every member · '
      : '';
  if (role.permissions.contains('administrator')) {
    return '${kind}Administrator: every permission';
  }
  final count = role.permissions.length;
  if (count == 0) return '${kind}No permissions';
  final of = total == null ? '' : ' of $total';
  return '$kind$count$of permission${count == 1 && total == null ? '' : 's'}';
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(text, textAlign: TextAlign.center),
    ),
  );
}
