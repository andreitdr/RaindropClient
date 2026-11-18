import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/server_profile.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/layout/layout_scope.dart';
import '../../../core/layout/layout_slot.dart';
import '../../../core/widgets/panel.dart';
import '../../home/layout/main_layout_ids.dart';
import '../controllers/servers_controller.dart';
import 'server_actions.dart';

/// The leftmost rail of the Discord-style shell: one circular avatar per
/// connected server, and below them the rail's layout slot — by default the
/// "add server" button. Server switching stays a single tap regardless of how
/// deep the user is in a channel or DM, matching the pattern this layout is
/// known for.
///
/// Right-click (long-press on touch) on a server opens its menu: its
/// settings, leave it, or just remove it from this device.
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
              // "Add a server" by default; the layout decides.
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
    final action = await showMenu<ServerAction>(
      context: context,
      position: RelativeRect.fromRect(
        globalPosition & Size.zero,
        Offset.zero & overlay.size,
      ),
      items: serverActionItems(context),
    );
    if (action == null || !context.mounted) return;
    await runServerAction(context, ref, server, action);
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
