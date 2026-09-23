import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/layout_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/voice/voice_engine.dart';
import '../../../core/widgets/rail_button.dart';
import '../../channels/controllers/channels_controller.dart';
import '../../servers/controllers/servers_controller.dart';
import '../controllers/voice_call_controller.dart';
import '../controllers/voice_settings_controller.dart';

/// The microphone and headset buttons side by side, for the narrow layout's
/// call bar and the voice view's in-call controls. In the main view's
/// toolbars they are placed one by one, as layout slot buttons.
class VoiceSelfControls extends StatelessWidget {
  const VoiceSelfControls({super.key, this.iconSize = 20});

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        VoiceMuteButton(iconSize: iconSize),
        VoiceDeafenButton(iconSize: iconSize),
      ],
    );
  }
}

/// The microphone button. It works whether or not a call is in progress: the
/// state carries into the next call, like a headset's own mute switch.
class VoiceMuteButton extends ConsumerWidget {
  const VoiceMuteButton({
    super.key,
    this.style = SlotStyle.compact,
    this.iconSize = 20,
  });

  final SlotStyle style;
  final double iconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(voiceSettingsProvider);
    final call = ref.watch(voiceCallProvider);
    final controller = ref.read(voiceSettingsProvider.notifier);

    // A moderator's mute (or no `speak` here) outranks the button: it shows
    // as muted either way, and says why.
    final forcedMute = call.inCall && (call.serverMuted || call.suppressed);
    final on = settings.micOn && !forcedMute;

    return _SelfButton(
      style: style,
      iconSize: iconSize,
      icon: on ? Icons.mic : Icons.mic_off,
      alarmed: !on,
      tooltip: forcedMute
          ? (call.serverMuted
                ? 'Muted for everyone by a moderator'
                : 'You cannot speak in this channel')
          : settings.micOn
          ? 'Mute'
          : 'Unmute',
      onPressed: controller.toggleMute,
    );
  }
}

/// The headset button; like [VoiceMuteButton], a setting rather than call
/// state.
class VoiceDeafenButton extends ConsumerWidget {
  const VoiceDeafenButton({
    super.key,
    this.style = SlotStyle.compact,
    this.iconSize = 20,
  });

  final SlotStyle style;
  final double iconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deaf = ref.watch(voiceSettingsProvider.select((s) => s.selfDeaf));
    return _SelfButton(
      style: style,
      iconSize: iconSize,
      icon: deaf ? Icons.headset_off : Icons.headset,
      alarmed: deaf,
      tooltip: deaf ? 'Undeafen' : 'Deafen',
      onPressed: ref.read(voiceSettingsProvider.notifier).toggleDeafen,
    );
  }
}

class _SelfButton extends StatelessWidget {
  const _SelfButton({
    required this.style,
    required this.iconSize,
    required this.icon,
    required this.alarmed,
    required this.tooltip,
    required this.onPressed,
  });

  final SlotStyle style;
  final double iconSize;
  final IconData icon;

  /// Muted or deafened: drawn in the error colour.
  final bool alarmed;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = alarmed ? Theme.of(context).colorScheme.error : null;
    return switch (style) {
      SlotStyle.rail => RailButton(
        icon: icon,
        iconColor: color,
        tooltip: tooltip,
        onTap: onPressed,
      ),
      SlotStyle.compact => IconButton(
        iconSize: iconSize,
        visualDensity: VisualDensity.compact,
        tooltip: tooltip,
        icon: Icon(icon, color: color),
        onPressed: onPressed,
      ),
    };
  }
}

/// "Voice connected" and where, with a button to hang up — shown above the
/// signed-in user in the sidebar, and as a thin bar in the narrow layout,
/// whenever this client is in a call. The call can be on any server, not only
/// the one on screen.
class VoiceConnectionBar extends ConsumerWidget {
  const VoiceConnectionBar({super.key, this.compact = false});

  /// The narrow layout's version: one line, with the mute buttons in it too,
  /// since the sidebar that holds them lives in a drawer there.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final call = ref.watch(voiceCallProvider);
    if (!call.inCall) return const SizedBox.shrink();

    final serverId = call.serverId!;
    final channelId = call.channelId!;
    final theme = Theme.of(context);

    final channelName =
        ref
            .watch(channelsProvider(serverId))
            .valueOrNull
            ?.where((c) => c.id == channelId)
            .firstOrNull
            ?.name ??
        'voice';
    final serverName =
        ref
            .watch(serversControllerProvider)
            .where((s) => s.id == serverId)
            .firstOrNull
            ?.displayName ??
        '';

    final (label, color) = switch (call.status) {
      VoiceCallStatus.connected => (
        'Voice connected',
        context.surfaces.onlineIndicator,
      ),
      VoiceCallStatus.reconnecting => (
        'Reconnecting…',
        theme.colorScheme.tertiary,
      ),
      _ => ('Connecting…', theme.colorScheme.onSurfaceVariant),
    };

    // The call's encryption, always visible: a lock when the audio is end-to-
    // end encrypted, a warning while some of it is not decrypting (and so
    // kept silent), an open lock where the server does not offer it.
    final (lockIcon, lockColor, lockTip) = switch (call.encryption) {
      VoiceEncryption.active => (
        Icons.lock,
        context.surfaces.onlineIndicator,
        'End-to-end encrypted. Not even the server can hear this call.',
      ),
      VoiceEncryption.degraded => (
        Icons.lock_clock,
        theme.colorScheme.tertiary,
        'End-to-end encrypted. Somebody\'s audio is not decrypting right now, '
            'so they are silent until it does.',
      ),
      VoiceEncryption.none => (
        Icons.lock_open,
        theme.colorScheme.onSurfaceVariant,
        'Not end-to-end encrypted: this server does not offer it, so its media '
            'server can hear the call.',
      ),
    };
    final lock = Tooltip(
      message: lockTip,
      child: Icon(lockIcon, size: 14, color: lockColor),
    );

    final hangUp = IconButton(
      tooltip: 'Disconnect',
      visualDensity: VisualDensity.compact,
      icon: Icon(Icons.call_end, color: theme.colorScheme.error),
      onPressed: () => ref.read(voiceCallProvider.notifier).leave(),
    );

    final where = Text(
      serverName.isEmpty ? channelName : '$channelName / $serverName',
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );

    final status = Text(
      label,
      style: theme.textTheme.labelMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
      ),
    );

    if (compact) {
      return Material(
        color: context.surfaces.raised,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Row(
            children: [
              Icon(Icons.graphic_eq, size: 18, color: color),
              const SizedBox(width: 8),
              status,
              const SizedBox(width: 4),
              lock,
              const SizedBox(width: 8),
              Expanded(child: where),
              const VoiceSelfControls(iconSize: 18),
              hangUp,
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [status, const SizedBox(width: 4), lock]),
                where,
              ],
            ),
          ),
          hangUp,
        ],
      ),
    );
  }
}
