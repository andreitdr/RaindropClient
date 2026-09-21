import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../channels/controllers/channels_controller.dart';
import '../../servers/controllers/servers_controller.dart';
import '../controllers/voice_call_controller.dart';
import '../controllers/voice_settings_controller.dart';

/// The microphone and headset buttons. They work whether or not a call is in
/// progress: the state carries into the next call, like a headset's own
/// mute switch.
class VoiceSelfControls extends ConsumerWidget {
  const VoiceSelfControls({super.key, this.iconSize = 20});

  final double iconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(voiceSettingsProvider);
    final call = ref.watch(voiceCallProvider);
    final controller = ref.read(voiceSettingsProvider.notifier);
    final error = Theme.of(context).colorScheme.error;

    // A moderator's mute (or no `speak` here) outranks the button: it shows
    // as muted either way, and says why.
    final forcedMute = call.inCall && (call.serverMuted || call.suppressed);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          iconSize: iconSize,
          visualDensity: VisualDensity.compact,
          tooltip: forcedMute
              ? (call.serverMuted
                    ? 'Muted for everyone by a moderator'
                    : 'You cannot speak in this channel')
              : settings.micOn
              ? 'Mute'
              : 'Unmute',
          icon: Icon(
            settings.micOn && !forcedMute ? Icons.mic : Icons.mic_off,
            color: settings.micOn && !forcedMute ? null : error,
          ),
          onPressed: controller.toggleMute,
        ),
        IconButton(
          iconSize: iconSize,
          visualDensity: VisualDensity.compact,
          tooltip: settings.selfDeaf ? 'Undeafen' : 'Deafen',
          icon: Icon(
            settings.selfDeaf ? Icons.headset_off : Icons.headset,
            color: settings.selfDeaf ? error : null,
          ),
          onPressed: controller.toggleDeafen,
        ),
      ],
    );
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
              children: [status, where],
            ),
          ),
          hangUp,
        ],
      ),
    );
  }
}
