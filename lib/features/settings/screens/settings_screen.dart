import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/layout_controller.dart';
import '../../../core/storage/app_prefs.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/theme/theme_definition.dart';
import '../../../core/widgets/adaptive.dart';
import '../../servers/controllers/servers_controller.dart';
import '../../security/widgets/encryption_settings_section.dart';
import '../../servers/controllers/session_controller.dart';
import '../../voice/widgets/voice_settings_section.dart';
import 'layout_editor_screen.dart';

/// Theme selection, the main view's layout, voice and audio, and
/// connected-server management.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeId = ref.watch(activeThemeIdProvider);
    final catalog = ref.watch(themeCatalogProvider);
    final servers = ref.watch(serversControllerProvider);
    final activeServerId = ref.watch(activeServerIdProvider);
    final activeServer = servers
        .where((s) => s.id == (activeServerId ?? servers.firstOrNull?.id))
        .firstOrNull;
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final activeTheme = resolveActiveTheme(
      activeId: activeId,
      catalog: catalog,
      platformBrightness: platformBrightness,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionLabel('Theme'),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                _ThemeOptionTile(
                  name: 'Match system',
                  subtitle: 'Follows your OS light/dark setting',
                  swatch: null,
                  selected: activeId == kSystemThemeId,
                  onTap: () => ref
                      .read(activeThemeIdProvider.notifier)
                      .select(kSystemThemeId),
                ),
                for (final theme in catalog) ...[
                  const Divider(height: 1),
                  _ThemeOptionTile(
                    name: theme.name,
                    subtitle: theme.isBuiltIn ? null : 'Custom',
                    swatch: theme.seedColor,
                    selected: activeId == theme.id,
                    onTap: () => ref
                        .read(activeThemeIdProvider.notifier)
                        .select(theme.id),
                    onEdit: theme.isBuiltIn
                        ? null
                        : () => context.push(
                            '/settings/theme-editor',
                            extra: (starting: theme, editing: theme),
                          ),
                    onDelete: theme.isBuiltIn
                        ? null
                        : () => _deleteTheme(context, ref, theme, activeId),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => context.push(
                '/settings/theme-editor',
                extra: (starting: activeTheme, editing: null),
              ),
              icon: const Icon(Icons.add),
              label: const Text('New theme'),
            ),
          ),
          const SizedBox(height: 16),
          _SectionLabel('Layout'),
          const _LayoutSection(),
          const SizedBox(height: 16),
          _SectionLabel('Voice & video'),
          const VoiceSettingsSection(),
          const SizedBox(height: 16),
          if (activeServer != null) ...[
            _SectionLabel('Encryption'),
            EncryptionSettingsSection(
              serverId: activeServer.id,
              serverName: activeServer.displayName,
            ),
            const SizedBox(height: 16),
          ],
          _SectionLabel('Connected servers'),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (final server in servers)
                  _ServerRow(
                    serverId: server.id,
                    name: server.displayName,
                    host: '${server.host}:${server.port}',
                  ),
                if (servers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No servers connected yet.'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTheme(
    BuildContext context,
    WidgetRef ref,
    AppThemeDefinition theme,
    String activeId,
  ) async {
    final confirmed = await showAdaptiveConfirm(
      context,
      title: 'Delete "${theme.name}"?',
      message:
          'This removes the theme from every device that shares this install.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;
    ref.read(themeCatalogProvider.notifier).remove(theme.id);
    if (activeId == theme.id) {
      ref.read(activeThemeIdProvider.notifier).select(kSystemThemeId);
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.6),
      ),
    );
  }
}

/// The way into the layout editor — offered on windows wide enough for the
/// layout it edits.
class _LayoutSection extends ConsumerWidget {
  const _LayoutSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = MediaQuery.sizeOf(context).width >= kLayoutEditorMinWidth;
    final rules = ref.watch(layoutRulesProvider);
    final custom =
        ref.watch(layoutConfigProvider) != rules.defaults.normalize(rules);
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        enabled: wide,
        leading: const Icon(Icons.dashboard_customize_outlined),
        title: const Text('Customize layout'),
        subtitle: Text(
          !wide
              ? 'Widen the window to edit the layout.'
              : custom
              ? 'Using your own layout on every server.'
              : 'Move, resize and hide panes and buttons in the main view.',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/settings/layout'),
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.name,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.swatch,
    this.onEdit,
    this.onDelete,
  });

  final String name;
  final String? subtitle;
  final Color? swatch;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: swatch == null
          ? const Icon(Icons.brightness_auto)
          : Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(color: swatch, shape: BoxShape.circle),
            ),
      title: Text(name),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: 'Edit',
              onPressed: onEdit,
            ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
          if (selected) Icon(Icons.check, color: scheme.primary),
        ],
      ),
    );
  }
}

class _ServerRow extends ConsumerWidget {
  const _ServerRow({
    required this.serverId,
    required this.name,
    required this.host,
  });

  final String serverId;
  final String name;
  final String host;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(name),
      subtitle: Text(host),
      trailing: IconButton(
        icon: const Icon(Icons.logout, size: 20),
        tooltip: 'Remove server',
        onPressed: () async {
          final confirmed = await showAdaptiveConfirm(
            context,
            title: 'Remove $name?',
            message:
                'This forgets the server locally, including its saved session and pinned '
                "certificate. It doesn't delete your account on the server — you can log "
                'back in later with your username and password.',
            confirmLabel: 'Remove',
            destructive: true,
          );
          if (!confirmed) return;
          await ref.read(serverSessionProvider(serverId).notifier).logout();
          await ref.read(serversControllerProvider.notifier).remove(serverId);
        },
      ),
    );
  }
}
