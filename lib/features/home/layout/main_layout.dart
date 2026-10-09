import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/layout_config.dart';
import '../../../core/layout/layout_controller.dart';
import '../../../core/layout/layout_scope.dart';
import '../../../core/widgets/rail_button.dart';
import '../../voice/widgets/voice_controls.dart';
import 'main_layout_ids.dart';

/// The main view as it ships — and as it looked before it could be changed.
const mainDefaultLayout = LayoutConfig(
  panes: [
    PaneLayout(id: MainPanes.servers, width: 76),
    PaneLayout(id: MainPanes.channels, width: 240),
    PaneLayout(id: MainPanes.content),
    PaneLayout(id: MainPanes.members, width: 240),
  ],
  slots: {
    MainSlots.railFooter: [MainButtons.addServer, MainButtons.settings],
    MainSlots.userPanel: [
      MainButtons.mute,
      MainButtons.deafen,
      MainButtons.camera,
      MainButtons.settings,
    ],
    MainSlots.topBar: [MainButtons.members],
  },
);

/// What the main view's layout may and may not do.
///
/// - The rail, the channel list and the chat can move but not be hidden: they
///   are how servers, channels and messages are reached. Only the member list
///   can go.
/// - A button dropped anywhere on a pane joins that pane's toolbar; the
///   member list has none, so it takes no buttons.
/// - The rail keeps its width (its server icons are a fixed size); the two
///   side panes resize between 180 and 400; the chat takes what is left.
/// - Settings must stay in at least one slot: the layout editor is behind it.
const mainLayoutRules = LayoutRules(
  defaults: mainDefaultLayout,
  panes: {
    MainPanes.servers: PaneRule(required: true, slot: MainSlots.railFooter),
    MainPanes.channels: PaneRule(
      required: true,
      slot: MainSlots.userPanel,
      minWidth: 180,
      maxWidth: 400,
    ),
    MainPanes.content: PaneRule(
      required: true,
      fill: true,
      slot: MainSlots.topBar,
    ),
    MainPanes.members: PaneRule(minWidth: 180, maxWidth: 400),
  },
  requiredButtons: {MainButtons.settings},
);

/// The narrowest the chat is let get before the member list folds away
/// behind its button (at the default widths: a 1000px window, as before).
const kMinContentWidth = 440.0;

/// What the layout editor calls each pane.
const mainPaneLabels = {
  MainPanes.servers: 'Servers',
  MainPanes.channels: 'Channels',
  MainPanes.content: 'Chat',
  MainPanes.members: 'Members',
};

/// Every button the main view's slots can hold.
final mainLayoutButtons = <String, LayoutButtonSpec>{
  MainButtons.addServer: LayoutButtonSpec(
    id: MainButtons.addServer,
    label: 'Add a server',
    icon: Icons.add,
    build: (context, style) => _NavButton(
      style: style,
      icon: Icons.add,
      tooltip: 'Add a server',
      outlined: true,
      route: '/connect',
    ),
  ),
  MainButtons.settings: LayoutButtonSpec(
    id: MainButtons.settings,
    label: 'Settings',
    icon: Icons.settings_outlined,
    build: (context, style) => _NavButton(
      style: style,
      icon: Icons.settings_outlined,
      tooltip: 'Settings',
      route: '/settings',
    ),
  ),
  MainButtons.mute: LayoutButtonSpec(
    id: MainButtons.mute,
    label: 'Mute',
    icon: Icons.mic,
    build: (context, style) => VoiceMuteButton(style: style),
  ),
  MainButtons.deafen: LayoutButtonSpec(
    id: MainButtons.deafen,
    label: 'Deafen',
    icon: Icons.headset,
    build: (context, style) => VoiceDeafenButton(style: style),
  ),
  MainButtons.camera: LayoutButtonSpec(
    id: MainButtons.camera,
    label: 'Camera',
    icon: Icons.videocam,
    build: (context, style) => VoiceCameraButton(style: style),
  ),
  MainButtons.screenShare: LayoutButtonSpec(
    id: MainButtons.screenShare,
    label: 'Share screen',
    icon: Icons.screen_share,
    build: (context, style) => VoiceScreenShareButton(style: style),
  ),
  MainButtons.members: LayoutButtonSpec(
    id: MainButtons.members,
    label: 'Show members',
    icon: Icons.people_outline,
    build: (context, style) => _MembersToggleButton(style: style),
  ),
};

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.style,
    required this.icon,
    required this.tooltip,
    required this.route,
    this.outlined = false,
  });

  final SlotStyle style;
  final IconData icon;
  final String tooltip;
  final String route;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return switch (style) {
      SlotStyle.rail => RailButton(
        icon: icon,
        tooltip: tooltip,
        outlined: outlined,
        onTap: () => context.push(route),
      ),
      SlotStyle.compact => IconButton(
        icon: Icon(icon, size: 20),
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        onPressed: () => context.push(route),
      ),
    };
  }
}

/// Shows or hides the member list — only while the window is too narrow to
/// show it on its own; otherwise it draws nothing.
class _MembersToggleButton extends ConsumerWidget {
  const _MembersToggleButton({required this.style});

  final SlotStyle style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collapsed =
        LayoutScope.maybeOf(context)?.collapsedPanes ?? const <String>{};
    if (!collapsed.contains(MainPanes.members)) return const SizedBox.shrink();
    final shown = ref.watch(
      revealedPanesProvider.select((s) => s.contains(MainPanes.members)),
    );
    void toggle() =>
        ref.read(revealedPanesProvider.notifier).toggle(MainPanes.members);
    final icon = shown ? Icons.people : Icons.people_outline;
    return switch (style) {
      SlotStyle.rail => RailButton(
        icon: icon,
        tooltip: 'Members',
        onTap: toggle,
      ),
      SlotStyle.compact => IconButton(
        icon: Icon(icon),
        tooltip: 'Members',
        onPressed: toggle,
      ),
    };
  }
}
