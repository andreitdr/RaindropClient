import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/server_profile.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/layout/layout_scope.dart';
import '../../../core/layout/layout_slot.dart';
import '../../../core/widgets/adaptive.dart';
import '../../../core/widgets/panel.dart';
import '../../home/layout/main_layout_ids.dart';
import '../controllers/servers_controller.dart';
import '../controllers/session_controller.dart';
import 'leave_server_dialog.dart';

/// The leftmost rail of the Discord-style shell: one circular avatar per
/// connected server, and below them the rail's layout slot — by default an
/// "add server" button and the settings button. Server switching stays a
/// single tap regardless of how deep the user is in a channel or DM, matching
/// the pattern this layout is known for. The rail is on screen for every
/// server, signed in or not, which is why settings live here by default
/// rather than in a server's own sidebar.
///
/// Right-click (long-press on touch) on a server opens its menu: leave it,
/// or just remove it from this device.
class ServerRail extends ConsumerWidget {
  const ServerRail({super.key, required this.activeServerId});

  final String? activeServerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servers = ref.watch(serversControllerProvider);

    return SizedBox(
      width: 76,
      child: Panel(
        color: context.surfaces.rail,
        child: SafeArea(
          right: false,
          left: false,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  children: [
                    for (final server in servers)
                      _ServerAvatar(
                        server: server,
                        selected: server.id == activeServerId,
                        onTap: () => ref
                            .read(activeServerIdProvider.notifier)
                            .select(server.id),
                      ),
                  ],
                ),
              ),
              // "Add a server" and Settings by default; the layout decides.
              const LayoutSlot(
                MainSlots.railFooter,
                style: SlotStyle.rail,
                axis: Axis.vertical,
                spacing: 12,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ServerAction { leave, remove }

class _ServerAvatar extends ConsumerWidget {
  const _ServerAvatar({
    required this.server,
    required this.selected,
    required this.onTap,
  });

  final ServerProfile server;
  final bool selected;
  final VoidCallback onTap;

  Future<void> _openMenu(
    BuildContext context,
    WidgetRef ref,
    Offset globalPosition,
  ) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final scheme = Theme.of(context).colorScheme;

    final action = await showMenu<_ServerAction>(
      context: context,
      position: RelativeRect.fromRect(
        globalPosition & Size.zero,
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          value: _ServerAction.leave,
          child: ListTile(
            leading: Icon(Icons.logout, color: scheme.error),
            title: Text('Leave server', style: TextStyle(color: scheme.error)),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        const PopupMenuItem(
          value: _ServerAction.remove,
          child: ListTile(
            leading: Icon(Icons.remove_circle_outline),
            title: Text('Remove from this device'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
      ],
    );
    if (action == null || !context.mounted) return;

    switch (action) {
      case _ServerAction.leave:
        await showLeaveServerDialog(context, server);
      case _ServerAction.remove:
        final confirmed = await showAdaptiveConfirm(
          context,
          title: 'Remove ${server.displayName}?',
          message:
              'This forgets the server locally, including its saved session and pinned '
              "certificate. You stay a member of the server; to give that up, "
              'leave it instead.',
          confirmLabel: 'Remove',
          destructive: true,
        );
        if (!confirmed) return;
        await ref.read(serverSessionProvider(server.id).notifier).logout();
        await ref.read(serversControllerProvider.notifier).remove(server.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final initials = server.displayName.trim().isEmpty
        ? '?'
        : server.displayName.trim().substring(0, 1).toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Tooltip(
        message: server.displayName,
        child: GestureDetector(
          onSecondaryTapDown: (d) => _openMenu(context, ref, d.globalPosition),
          onLongPressStart: (d) => _openMenu(context, ref, d.globalPosition),
          child: InkWell(
            borderRadius: BorderRadius.circular(selected ? 18 : 26),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: selected ? scheme.primary : context.surfaces.raised,
                borderRadius: BorderRadius.circular(selected ? 18 : 26),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: TextStyle(
                  color: selected ? scheme.onPrimary : scheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
