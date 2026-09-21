import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/server_profile.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/panel.dart';
import '../controllers/servers_controller.dart';

/// The leftmost rail of the Discord-style shell: one circular avatar per
/// connected server, an "add server" button, and nothing else — server
/// switching stays a single tap regardless of how deep the user is in a
/// channel or DM, matching the pattern this layout is known for.
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
              _AddServerButton(onTap: () => context.push('/connect')),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServerAvatar extends StatelessWidget {
  const _ServerAvatar({
    required this.server,
    required this.selected,
    required this.onTap,
  });

  final ServerProfile server;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initials = server.displayName.trim().isEmpty
        ? '?'
        : server.displayName.trim().substring(0, 1).toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Tooltip(
        message: server.displayName,
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
    );
  }
}

class _AddServerButton extends StatelessWidget {
  const _AddServerButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Tooltip(
        message: 'Add a server',
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: scheme.primary.withValues(alpha: 0.6)),
              borderRadius: BorderRadius.circular(26),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.add, color: scheme.primary),
          ),
        ),
      ),
    );
  }
}
