import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:raindrop_client/core/network/grpc/protocol.dart' as pb;
import 'package:raindrop_client/core/network/roles_api.dart';
import 'package:raindrop_client/core/widgets/adaptive.dart';
import 'package:raindrop_client/features/roles/controllers/roles_controller.dart';
import 'package:raindrop_client/features/roles/screens/role_editor_screen.dart';
import 'package:raindrop_client/features/roles/screens/roles_screen.dart';
import 'package:raindrop_client/features/servers/controllers/server_permissions.dart';

const serverId = 'server-1';

Role role(
  String id,
  String name, {
  String kind = RoleKindNames.custom,
  int position = 1,
  List<String> permissions = const [],
}) => Role(
  roleId: id,
  name: name,
  kind: kind,
  position: position,
  permissions: permissions,
  createdAtUtc: DateTime.utc(2026),
);

PermissionInfo permission(String name, String category) => PermissionInfo(
  name: name,
  title: PermissionInfo.titleFromName(name),
  summary: 'Lets them $name.',
  category: category,
);

/// A server whose build knows only these permissions — an older one, say.
final olderCatalogue = [
  permission('view_channel', PermissionCategories.general),
  permission('send_messages', PermissionCategories.text),
  permission('manage_messages', PermissionCategories.moderation),
  permission('manage_roles', PermissionCategories.administration),
];

class FakeRoles extends RolesController {
  FakeRoles(this.roles);

  final List<Role> roles;

  @override
  Future<List<Role>?> build(String serverId) async => roles;
}

class FakePermissions extends ServerPermissionsController {
  FakePermissions(this.permissions);

  final List<String> permissions;

  @override
  Future<MyRoles?> build(String serverId) async =>
      MyRoles(userId: 'me', permissions: permissions);
}

Future<void> pumpEditor(
  WidgetTester tester, {
  required Role editing,
  required List<String> mine,
  List<PermissionInfo>? catalogue,
}) async {
  // Tall enough that the whole editor is built, Save button included.
  tester.view.physicalSize = const Size(1000, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        permissionCatalogueProvider.overrideWith(
          (ref, id) async => catalogue ?? olderCatalogue,
        ),
        serverPermissionsProvider.overrideWith(() => FakePermissions(mine)),
        rolesProvider.overrideWith(() => FakeRoles([editing])),
        roleDetailProvider.overrideWith(
          (ref, which) async => RoleDetail(role: editing, memberIds: const []),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) =>
                  RoleEditorScreen(serverId: serverId, roleId: editing.roleId),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

bool switchEnabled(WidgetTester tester, String title) {
  final tile = find.ancestor(
    of: find.text(title),
    matching: find.byType(ListTile),
  );
  final adaptive = tester.widget<AdaptiveSwitch>(
    find.descendant(of: tile, matching: find.byType(AdaptiveSwitch)),
  );
  return adaptive.onChanged != null;
}

void main() {
  group('PermissionInfo', () {
    test('a server too old to send a title or a category still reads', () {
      final info = PermissionInfo.fromProto(
        pb.PermissionDescription(name: 'manage_roles', summary: 'Roles.'),
      );
      expect(info.title, 'Manage roles');
      expect(info.category, PermissionCategories.other);
    });

    test('a category this client does not know is filed under other', () {
      final info = PermissionInfo.fromProto(
        pb.PermissionDescription(
          name: 'stream_music',
          title: 'Stream music',
          category: 'jukebox',
        ),
      );
      expect(info.title, 'Stream music');
      expect(info.category, PermissionCategories.other);
    });
  });

  test(
    'permissions group in the editor\'s order, leaving empty groups out',
    () {
      final groups = groupPermissions([
        permission('manage_roles', PermissionCategories.administration),
        permission('view_channel', PermissionCategories.general),
        permission('stream_music', PermissionCategories.other),
      ]);
      expect(groups.map((g) => g.category), [
        PermissionCategories.general,
        PermissionCategories.administration,
        PermissionCategories.other,
      ]);
    },
  );

  test('nobody may hand out what they do not hold', () {
    expect(
      canGrantAll(['manage_roles', 'send_messages'], ['send_messages']),
      isTrue,
    );
    expect(canGrantAll(['manage_roles'], ['send_messages']), isFalse);
    expect(canGrantAll(['send_messages'], ['send_messages']), isFalse);
    expect(canGrantAll(null, const []), isFalse);
  });

  test('everyone sorts first, then by position, highest first', () {
    final sorted = sortRoles([
      role('a', 'Helpers', position: 1),
      role('o', 'owner', kind: RoleKindNames.owner, position: 1000),
      role('e', 'everyone', kind: RoleKindNames.everyone, position: 0),
      role('b', 'Moderators', position: 2),
    ]);
    expect(sorted.map((r) => r.name), [
      'everyone',
      'owner',
      'Moderators',
      'Helpers',
    ]);
  });

  test('a role list line says what a role grants', () {
    expect(
      describeRole(
        role(
          'o',
          'owner',
          kind: RoleKindNames.owner,
          permissions: ['administrator'],
        ),
        14,
      ),
      'Built in · Administrator: every permission',
    );
    expect(
      describeRole(role('a', 'Helpers', permissions: ['send_messages']), 4),
      '1 of 4 permissions',
    );
    expect(describeRole(role('a', 'Empty'), 4), 'No permissions');
  });

  testWidgets('the editor offers only what the server knows, and greys out '
      'what the caller does not hold', (tester) async {
    await pumpEditor(
      tester,
      editing: role('r', 'Helpers', permissions: ['send_messages']),
      mine: ['manage_roles', 'send_messages', 'view_channel'],
    );

    // An older server's catalogue: nothing about voice, because it has none.
    expect(find.text('Speak'), findsNothing);
    expect(find.text('Send messages'), findsOneWidget);

    expect(switchEnabled(tester, 'Send messages'), isTrue);
    expect(switchEnabled(tester, 'View channel'), isTrue);
    expect(switchEnabled(tester, 'Manage messages'), isFalse);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('a permission from a newer server is shown, titled by it', (
    tester,
  ) async {
    await pumpEditor(
      tester,
      editing: role('r', 'Helpers'),
      mine: ['manage_roles'],
      catalogue: [
        ...olderCatalogue,
        const PermissionInfo(
          name: 'stream_music',
          title: 'Stream music',
          summary: 'Play music into voice channels.',
          category: PermissionCategories.other,
        ),
      ],
    );
    expect(find.text('Stream music'), findsOneWidget);
    expect(find.text('OTHER'), findsOneWidget);
  });

  testWidgets('the owner role is read-only, even to an administrator', (
    tester,
  ) async {
    await pumpEditor(
      tester,
      editing: role(
        'o',
        'owner',
        kind: RoleKindNames.owner,
        permissions: ['administrator'],
      ),
      mine: [
        'manage_roles',
        'send_messages',
        'view_channel',
        'manage_messages',
        'administrator',
      ],
    );

    expect(switchEnabled(tester, 'Send messages'), isFalse);
    expect(find.text('Save'), findsNothing);
    expect(find.text('Delete role'), findsNothing);
  });

  testWidgets('without manage_roles everything is read-only', (tester) async {
    await pumpEditor(
      tester,
      editing: role('r', 'Helpers', permissions: ['send_messages']),
      mine: ['send_messages', 'view_channel'],
    );
    expect(switchEnabled(tester, 'Send messages'), isFalse);
    expect(find.text('Save'), findsNothing);
  });
}
