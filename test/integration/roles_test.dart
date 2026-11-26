// Roles against a live RaindropServer: the permission catalogue the editor is
// built from, creating, editing, handing out and deleting a role, and the rule
// that nobody hands out what they do not hold. Needs no Rust core, and a server
// with a fresh database — the first account to register owns it:
//
//   RAINDROP_TEST_SERVER=localhost:5001 flutter test test/integration/roles_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/network/api_exception.dart';
import 'package:raindrop_client/core/network/channels_api.dart';
import 'package:raindrop_client/core/network/raindrop_channel.dart';
import 'package:raindrop_client/core/network/roles_api.dart';
import 'package:raindrop_client/core/network/users_api.dart';
import 'package:uuid/uuid.dart';

final _server = Platform.environment['RAINDROP_TEST_SERVER'];
final _skip = _server == null ? 'set RAINDROP_TEST_SERVER' : null;

const _uuid = Uuid();

Matcher _apiError(String code) =>
    throwsA(isA<ApiException>().having((e) => e.code, 'code', code));

void main() {
  late RaindropChannel client;
  late UsersApi users;
  late RolesApi roles;

  setUpAll(() {
    if (_skip != null) return;
    final parts = _server!.split(':');
    client = RaindropChannel.forServer(
      host: parts[0],
      port: int.parse(parts[1]),
    );
    users = UsersApi(client);
    roles = RolesApi(client);
  });

  tearDownAll(() async {
    if (_skip == null) await client.close();
  });

  Future<SessionResult> register(String name) => users.register(
    userId: _uuid.v4(),
    username: '$name${DateTime.now().microsecondsSinceEpoch % 100000000}',
    password: 'correct horse battery',
  );

  test(
    'a role is built from the catalogue, handed out, edited and deleted',
    () async {
      final owner = await register('owner');
      final member = await register('member');
      expect(
        (await roles.me(owner.token)).can('manage_roles'),
        isTrue,
        reason: 'the first account on a fresh database owns the server',
      );

      final catalogue = await roles.permissions(owner.token);
      final manageMessages = catalogue.singleWhere(
        (p) => p.name == 'manage_messages',
      );
      expect(manageMessages.title, 'Manage messages');
      expect(manageMessages.category, PermissionCategories.moderation);

      // Creating a channel grants its creator nothing a role does not.
      final mine = await ChannelsApi(client).create(
        member.token,
        name: 'mine${DateTime.now().microsecondsSinceEpoch % 100000}',
        type: ChannelTypeNames.text,
      );
      expect(mine.can(ChannelPermissionNames.renameChannels), isFalse);
      await expectLater(
        ChannelsApi(client).rename(
          member.token,
          channelId: mine.channelId,
          name: 'ours${DateTime.now().microsecondsSinceEpoch % 100000}',
        ),
        _apiError('missing_permission'),
      );

      final moderators = await roles.create(
        owner.token,
        name: 'Moderators${DateTime.now().microsecondsSinceEpoch % 100000}',
        permissions: ['manage_messages', 'manage_roles'],
      );
      expect(
        await roles.assign(owner.token, member.user.userId, moderators.roleId),
        isTrue,
      );
      expect(
        await roles.assign(owner.token, member.user.userId, moderators.roleId),
        isFalse,
      );

      final theirs = await roles.ofMember(owner.token, member.user.userId);
      expect(theirs.can('manage_messages'), isTrue);
      expect(theirs.roles.where((r) => r.isEveryone), hasLength(1));

      // They may delegate what they hold, and nothing more.
      await expectLater(
        roles.create(
          member.token,
          name: 'Deleters',
          permissions: ['delete_channels'],
        ),
        _apiError('missing_permission'),
      );

      // An empty list clears the role's permissions; a null one leaves them.
      final renamed = await roles.update(
        owner.token,
        moderators.roleId,
        name: '${moderators.name}!',
      );
      expect(renamed.permissions, moderators.permissions);
      final cleared = await roles.update(
        owner.token,
        moderators.roleId,
        permissions: const [],
      );
      expect(cleared.permissions, isEmpty);
      expect((await roles.me(member.token)).can('manage_messages'), isFalse);

      final detail = await roles.get(owner.token, moderators.roleId);
      expect(detail.memberIds, [member.user.userId]);

      expect(
        await roles.unassign(
          owner.token,
          member.user.userId,
          moderators.roleId,
        ),
        isTrue,
      );
      await roles.delete(owner.token, moderators.roleId);
      await expectLater(
        roles.get(owner.token, moderators.roleId),
        _apiError('role_not_found'),
      );
    },
    skip: _skip,
  );
}
