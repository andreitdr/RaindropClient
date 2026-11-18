import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/server_profile.dart';
import 'leave_server_dialog.dart';
import 'remove_server.dart';

/// What can be done to one server from a menu: open its settings, leave it,
/// or just remove it from this device.
enum ServerAction { settings, leave, remove }

/// The route of [serverId]'s Server settings page.
String serverSettingsRoute(String serverId) => '/servers/$serverId/settings';

/// The entries of a server's menu, the same wherever it is shown — the rail's
/// right-click menu and each row of Settings' server list. [includeSettings]
/// is false where the row itself already opens the server's settings.
List<PopupMenuEntry<ServerAction>> serverActionItems(
  BuildContext context, {
  bool includeSettings = true,
}) {
  final scheme = Theme.of(context).colorScheme;
  return [
    if (includeSettings)
      const PopupMenuItem(
        value: ServerAction.settings,
        child: ListTile(
          leading: Icon(Icons.settings_outlined),
          title: Text('Server settings'),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
      ),
    PopupMenuItem(
      value: ServerAction.leave,
      child: ListTile(
        leading: Icon(Icons.logout, color: scheme.error),
        title: Text('Leave server', style: TextStyle(color: scheme.error)),
        contentPadding: EdgeInsets.zero,
        dense: true,
      ),
    ),
    const PopupMenuItem(
      value: ServerAction.remove,
      child: ListTile(
        leading: Icon(Icons.remove_circle_outline),
        title: Text('Remove from this device'),
        contentPadding: EdgeInsets.zero,
        dense: true,
      ),
    ),
  ];
}

/// Does [action] to [server].
Future<void> runServerAction(
  BuildContext context,
  WidgetRef ref,
  ServerProfile server,
  ServerAction action,
) async {
  switch (action) {
    case ServerAction.settings:
      await context.push(serverSettingsRoute(server.id));
    case ServerAction.leave:
      await showLeaveServerDialog(context, server);
    case ServerAction.remove:
      await confirmRemoveServer(context, ref, server);
  }
}
