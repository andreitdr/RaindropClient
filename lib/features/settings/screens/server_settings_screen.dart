import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/server_profile.dart';
import '../../security/widgets/encryption_settings_section.dart';
import '../../servers/controllers/servers_controller.dart';
import '../../servers/widgets/server_actions.dart';
import '../widgets/settings_app_bar.dart';
import '../widgets/settings_section_label.dart';

/// Server settings (`/servers/:serverId/settings`): what belongs to one
/// server on this device — its end-to-end encryption, and the ways out of it.
/// Opened from the server's name above its channel list and from the rail's
/// menu.
///
/// It needs no session, so it opens for a server that is down or signed out
/// too: the encryption section says what it can, and removing the server
/// from this device never waits on it.
class ServerSettingsScreen extends ConsumerWidget {
  const ServerSettingsScreen({super.key, required this.serverId});

  final String serverId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final server = ref
        .watch(serversControllerProvider)
        .where((s) => s.id == serverId)
        .firstOrNull;

    if (server == null) {
      // Left or removed — from here or anywhere else. Nothing is left to
      // show, so go back to where the person came from.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      });
      return const Scaffold();
    }

    return Scaffold(
      appBar: settingsAppBar(context, title: Text(server.displayName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.dns_outlined),
              title: Text(server.displayName),
              subtitle: Text('${server.host}:${server.port}'),
            ),
          ),
          const SizedBox(height: 16),
          const SettingsSectionLabel('Encryption'),
          EncryptionSettingsSection(
            serverId: server.id,
            serverName: server.displayName,
          ),
          const SizedBox(height: 16),
          const SettingsSectionLabel('Leave this server'),
          _ExitCard(server: server),
        ],
      ),
    );
  }
}

class _ExitCard extends ConsumerWidget {
  const _ExitCard({required this.server});

  final ServerProfile server;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.logout, color: scheme.error),
            title: Text('Leave server', style: TextStyle(color: scheme.error)),
            subtitle: const Text(
              'Leave for good, keeping or erasing your account there.',
            ),
            onTap: () =>
                runServerAction(context, ref, server, ServerAction.leave),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.remove_circle_outline),
            title: const Text('Remove from this device'),
            subtitle: const Text(
              'Only this device forgets it. Your account stays on the server.',
            ),
            onTap: () =>
                runServerAction(context, ref, server, ServerAction.remove),
          ),
        ],
      ),
    );
  }
}
