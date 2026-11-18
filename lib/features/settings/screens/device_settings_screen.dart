import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/layout_controller.dart';
import '../../../core/storage/app_prefs.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/theme/theme_definition.dart';
import '../../../core/widgets/adaptive.dart';
import '../../../core/models/server_profile.dart';
import '../../identity/controllers/identity_controller.dart';
import '../../identity/controllers/vault_sync.dart';
import '../../servers/controllers/servers_controller.dart';
import '../../servers/widgets/server_actions.dart';
import '../../voice/widgets/voice_settings_section.dart';
import '../widgets/settings_section_label.dart';
import 'layout_editor_screen.dart';

/// Settings for this device (`/settings`), opened from the button beside
/// the person's name: the theme, the main view's layout, voice and video,
/// the way to Identity & devices, and the servers this device is in.
///
/// What belongs to one server — its encryption, and leaving it — is that
/// server's own settings page (`ServerSettingsScreen`).
class DeviceSettingsScreen extends ConsumerWidget {
  const DeviceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeId = ref.watch(activeThemeIdProvider);
    final catalog = ref.watch(themeCatalogProvider);
    final servers = ref.watch(serversControllerProvider);
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
          const SettingsSectionLabel('Theme'),
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
          const SettingsSectionLabel('Layout'),
          const _LayoutSection(),
          const SizedBox(height: 16),
          const SettingsSectionLabel('Voice & video'),
          const VoiceSettingsSection(),
          const SizedBox(height: 16),
          const SettingsSectionLabel('Identity & devices'),
          const _IdentityLink(),
          const SizedBox(height: 16),
          const SettingsSectionLabel('Servers on this device'),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (final server in servers) _ServerRow(server: server),
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

/// The way into Identity & devices, which has a page of its own: it belongs
/// to the person, not to this device or to a server.
class _IdentityLink extends ConsumerWidget {
  const _IdentityLink();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final installId = ref.watch(installIdProvider).valueOrNull;
    final others = ref
        .watch(vaultProvider)
        .devices
        .values
        .where((d) => d.installId != installId)
        .length;
    final name = deviceName(ref.watch(appPrefsProvider));
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.devices_outlined),
        title: const Text('Identity & devices'),
        subtitle: Text(
          others > 0
              ? '$name and $others other ${others == 1 ? 'device' : 'devices'}'
              : name,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/settings/identity'),
      ),
    );
  }
}

/// One server this device is in: opens its settings, and its menu leaves
/// it or removes it from this device.
class _ServerRow extends ConsumerWidget {
  const _ServerRow({required this.server});

  final ServerProfile server;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(server.displayName),
      subtitle: Text('${server.host}:${server.port}'),
      onTap: () => context.push(serverSettingsRoute(server.id)),
      trailing: PopupMenuButton<ServerAction>(
        tooltip: 'Leave or remove',
        icon: const Icon(Icons.more_vert, size: 20),
        itemBuilder: (context) =>
            serverActionItems(context, includeSettings: false),
        onSelected: (action) => runServerAction(context, ref, server, action),
      ),
    );
  }
}
