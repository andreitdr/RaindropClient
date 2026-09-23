import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The server rail's large round button ("Add a server", Settings) — and how
/// any button placed in the rail's slot is drawn.
class RailButton extends StatelessWidget {
  const RailButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.iconColor,
    this.outlined = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? iconColor;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: outlined ? Colors.transparent : context.surfaces.raised,
              border: outlined
                  ? Border.all(color: scheme.primary.withValues(alpha: 0.6))
                  : null,
              borderRadius: BorderRadius.circular(26),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              color:
                  iconColor ??
                  (outlined ? scheme.primary : scheme.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }
}
