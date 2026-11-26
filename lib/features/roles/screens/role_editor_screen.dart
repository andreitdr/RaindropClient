import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/roles_api.dart';
import '../../../core/widgets/adaptive.dart';
import '../../members/controllers/members_controller.dart';
import '../../servers/controllers/server_permissions.dart';
import '../../servers/controllers/user_lookup.dart';
import '../../settings/widgets/settings_app_bar.dart';
import '../../settings/widgets/settings_section_label.dart';
import '../controllers/roles_controller.dart';

/// The longest role name the server accepts (`RoleNamePolicy`).
const maximumRoleNameLength = 64;

/// Builds, edits or deletes one role (`/servers/:serverId/roles/:roleId`,
/// `/servers/:serverId/roles/new`), and hands it to members.
///
/// The permissions offered are the server's own catalogue
/// (`permissionCatalogueProvider`), grouped by the category the server gives
/// each — never a list built into this client. A server running an older
/// build simply offers fewer.
///
/// What the server would refuse is greyed out rather than tried: without
/// `manage_roles` everything is read-only, a permission the caller does not
/// hold cannot be switched on, and a role granting something the caller does
/// not hold cannot be changed or handed out at all. The owner role is never
/// editable, and the everyone role keeps its name and is not handed out.
class RoleEditorScreen extends ConsumerStatefulWidget {
  const RoleEditorScreen({super.key, required this.serverId, this.roleId});

  final String serverId;

  /// Null for a new role.
  final String? roleId;

  @override
  ConsumerState<RoleEditorScreen> createState() => _RoleEditorScreenState();
}

class _RoleEditorScreenState extends ConsumerState<RoleEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();

  /// The permissions switched on, or null until the role has been read.
  Set<String>? _selected;

  /// The permissions the role had when it was read, to tell what changed.
  Set<String> _original = const {};
  String _originalName = '';

  bool _busy = false;
  String? _error;

  bool get _creating => widget.roleId == null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Takes the role as read, once — later re-reads (another client's edit)
  /// do not overwrite what is being typed.
  void _adopt(Role? role) {
    if (_selected != null) return;
    _original = {...?role?.permissions};
    _selected = {..._original};
    _originalName = role?.name ?? '';
    _name.text = _originalName;
  }

  @override
  Widget build(BuildContext context) {
    final serverId = widget.serverId;
    final catalogue = ref.watch(permissionCatalogueProvider(serverId));
    final mine = ref.watch(serverPermissionsProvider(serverId)).valueOrNull;
    // Kept alive while this page is open: the writes go through its notifier,
    // which needs its session read before it can send anything.
    ref.watch(rolesProvider(serverId));
    final detail = _creating
        ? const AsyncData<RoleDetail?>(null)
        : ref.watch(
            roleDetailProvider((serverId: serverId, roleId: widget.roleId!)),
          );

    final loading =
        catalogue.isLoading && !catalogue.hasValue ||
        detail.isLoading && !detail.hasValue;
    if (loading) {
      return Scaffold(
        appBar: settingsAppBar(context, title: const Text('Role')),
        body: const Center(child: AdaptiveActivityIndicator()),
      );
    }

    final permissions = catalogue.valueOrNull;
    final role = detail.valueOrNull?.role;
    if (permissions == null || (!_creating && role == null)) {
      return Scaffold(
        appBar: settingsAppBar(context, title: const Text('Role')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'This role could not be read. It may have been deleted, or the '
              'server does not offer role management.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    _adopt(role);
    final selected = _selected!;
    final held = mine?.permissions;
    final mayManage = canManage(held);
    // Editing a role is checked against what it grants now and what it will
    // grant, so a role granting anything the caller lacks is read-only.
    final editable =
        mayManage &&
        !(role?.isOwner ?? false) &&
        canGrantAll(held, role?.permissions ?? const []);
    final renamable = editable && (role?.isCustom ?? true);

    return Scaffold(
      appBar: settingsAppBar(
        context,
        title: Text(_creating ? 'New role' : role!.name),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_readOnlyReason(role, mayManage, editable) case final reason?)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  reason,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            const SettingsSectionLabel('Name'),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: TextFormField(
                  controller: _name,
                  enabled: renamable,
                  maxLength: maximumRoleNameLength,
                  decoration: const InputDecoration(labelText: 'Role name'),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'A role needs a name.'
                      : null,
                ),
              ),
            ),
            for (final group in groupPermissions(permissions)) ...[
              const SizedBox(height: 16),
              SettingsSectionLabel(group.title),
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final (i, p) in group.permissions.indexed) ...[
                      if (i > 0) const Divider(height: 1),
                      _PermissionTile(
                        permission: p,
                        value: selected.contains(p.name),
                        // A permission the caller lacks may still be switched
                        // off if this role already grants it — but then the
                        // whole role is read-only, so that never comes up.
                        onChanged: editable && (held?.contains(p.name) ?? false)
                            ? (on) => setState(() {
                                if (on) {
                                  selected.add(p.name);
                                } else {
                                  selected.remove(p.name);
                                }
                              })
                            : null,
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (editable)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    if (!_creating && role!.isCustom)
                      TextButton.icon(
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete role'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: _busy ? null : () => _delete(role),
                      ),
                    const Spacer(),
                    FilledButton(
                      onPressed: _busy ? null : () => _save(permissions),
                      child: Text(_creating ? 'Create role' : 'Save'),
                    ),
                  ],
                ),
              ),
            if (!_creating && !role!.isEveryone) ...[
              const SizedBox(height: 24),
              const SettingsSectionLabel('Members with this role'),
              _RoleMembers(
                serverId: serverId,
                role: role,
                memberIds: detail.valueOrNull!.memberIds,
                // Handing a role out is checked like editing it.
                canChange: canGrantAll(held, role.permissions),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _readOnlyReason(Role? role, bool mayManage, bool editable) {
    if (role?.isOwner ?? false) {
      return 'The owner role holds administrator — every permission, '
          'including ones added later. It cannot be changed or deleted.';
    }
    if (!mayManage) {
      return 'You can see this role, but changing roles needs the Manage '
          'roles permission.';
    }
    if (!editable) {
      return 'This role grants permissions you do not hold yourself, so you '
          'cannot change it or hand it out.';
    }
    if (role?.isEveryone ?? false) {
      return 'Every member holds this role. Its permissions are what a member '
          'can do before anybody gives them a role.';
    }
    return null;
  }

  Future<void> _save(List<PermissionInfo> catalogue) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final selected = _selected!;
    // Sent in the catalogue's order, so the request reads like the screen.
    final permissions = [
      for (final p in catalogue)
        if (selected.contains(p.name)) p.name,
    ];
    final name = _name.text.trim();
    final roles = ref.read(rolesProvider(widget.serverId).notifier);

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_creating) {
        await roles.create(name, permissions);
        if (mounted) context.pop();
        return;
      }
      final role = await roles.save(
        widget.roleId!,
        name: name != _originalName && _name.text.isNotEmpty ? name : null,
        permissions:
            selected.length == _original.length &&
                selected.containsAll(_original)
            ? null
            : permissions,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _original = {...selected};
        _originalName = role.name;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Saved "${role.name}".')));
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    }
  }

  Future<void> _delete(Role role) async {
    final confirmed = await showAdaptiveConfirm(
      context,
      title: 'Delete "${role.name}"?',
      message:
          'Everyone holding it loses what it grants. This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(rolesProvider(widget.serverId).notifier)
          .delete(role.roleId);
      if (mounted) context.pop();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    }
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.permission,
    required this.value,
    required this.onChanged,
  });

  final PermissionInfo permission;
  final bool value;

  /// Null when it cannot be changed.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(permission.title),
    subtitle: permission.summary.isEmpty ? null : Text(permission.summary),
    enabled: onChanged != null,
    trailing: AdaptiveSwitch(value: value, onChanged: onChanged),
    onTap: onChanged == null ? null : () => onChanged!(!value),
  );
}

/// Who holds a role, and — for a caller allowed to — handing it out and
/// taking it away.
class _RoleMembers extends ConsumerStatefulWidget {
  const _RoleMembers({
    required this.serverId,
    required this.role,
    required this.memberIds,
    required this.canChange,
  });

  final String serverId;
  final Role role;
  final List<String> memberIds;
  final bool canChange;

  @override
  ConsumerState<_RoleMembers> createState() => _RoleMembersState();
}

class _RoleMembersState extends ConsumerState<_RoleMembers> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    final ids = widget.memberIds;
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (ids.isEmpty)
            const ListTile(title: Text('Nobody holds this role yet.')),
          for (final (i, userId) in ids.indexed) ...[
            if (i > 0) const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(_nameOf(userId)),
              trailing: widget.canChange
                  ? IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      tooltip: 'Take this role away',
                      onPressed: () => _change(
                        () => ref
                            .read(rolesProvider(widget.serverId).notifier)
                            .unassign(userId, widget.role.roleId),
                      ),
                    )
                  : null,
            ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (widget.canChange) ...[
            const Divider(height: 1),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: TextButton.icon(
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text('Give to a member'),
                  onPressed: _pickMember,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _nameOf(String userId) {
    final profile = ref
        .watch(userLookupProvider((serverId: widget.serverId, userId: userId)))
        .valueOrNull;
    return profile?.username ?? '${userId.substring(0, 8)}…';
  }

  Future<void> _change(Future<bool> Function() change) async {
    setState(() => _error = null);
    try {
      await change();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _pickMember() async {
    final members = await ref.read(membersProvider(widget.serverId).future);
    if (!mounted) return;
    final holders = widget.memberIds.toSet();
    final candidates = members.where((m) => !holders.contains(m.id)).toList()
      ..sort(
        (a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()),
      );

    final picked = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Give "${widget.role.name}" to'),
        children: [
          if (candidates.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text('Every member already holds it.'),
            ),
          for (final member in candidates)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, member.id),
              child: Text(member.username),
            ),
        ],
      ),
    );
    if (picked == null || !mounted) return;
    await _change(
      () => ref
          .read(rolesProvider(widget.serverId).notifier)
          .assign(picked, widget.role.roleId),
    );
  }
}
