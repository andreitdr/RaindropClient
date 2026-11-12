import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/layout_scope.dart';
import '../../../core/platform/platform_info.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/voice/voice_engine.dart';
import '../../../core/widgets/adaptive.dart';
import '../../../core/widgets/rail_button.dart';
import '../../channels/controllers/channels_controller.dart';
import '../../servers/controllers/servers_controller.dart';
import '../controllers/voice_call_controller.dart';
import '../controllers/voice_roster_controller.dart';
import '../controllers/voice_settings_controller.dart';
import 'camera_effects_sheet.dart';
import 'screen_share_picker.dart';

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
        // Draws nothing off a phone; see [VoiceSpeakerphoneButton].
        VoiceSpeakerphoneButton(iconSize: iconSize),
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

    // A moderator's mute (or no `speak` here) outranks the button, and so
    // does a microphone that would not open: it shows as muted in every
    // case, and says which one it is. Only the last of those is worth
    // trying again, which un-muting does.
    final forcedMute = call.inCall && (call.serverMuted || call.suppressed);
    final broken = call.inCall && call.microphoneFailed;
    final on = settings.micOn && !forcedMute && !broken;

    return _SelfButton(
      style: style,
      iconSize: iconSize,
      icon: on ? Icons.mic : Icons.mic_off,
      alarmed: !on,
      tooltip: forcedMute
          ? (call.serverMuted
                ? 'Muted for everyone by a moderator'
                : 'You cannot speak in this channel')
          : broken
          ? 'Your microphone could not be opened — something else may be '
                'using it. Nobody can hear you; tap to try again.'
          : settings.micOn
          ? 'Mute'
          : 'Unmute',
      // While the microphone is the problem, the button retries it: muting
      // would change nothing anybody can hear.
      onPressed: broken
          ? ref.read(voiceCallProvider.notifier).retryMicrophone
          : controller.toggleMute,
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

/// Turns this client's camera on and off.
///
/// Unlike mute and deafen, the camera is **call state, not a persisted
/// setting**: you cannot pre-arm a camera for a call you have not joined, and
/// turning it on goes through the camera-and-effects sheet first, so the user
/// sees what they are about to send before anybody else does.
class VoiceCameraButton extends ConsumerWidget {
  const VoiceCameraButton({
    super.key,
    this.style = SlotStyle.compact,
    this.iconSize = 20,
  });

  final SlotStyle style;
  final double iconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final call = ref.watch(voiceCallProvider);

    final blocked = switch (call) {
      VoiceCallState(inCall: false) => 'Join a call to show your camera',
      VoiceCallState(videoAvailable: false) =>
        'This server does not carry camera video in calls',
      VoiceCallState(cameraSuppressed: true) when !call.cameraOn =>
        'You cannot turn your camera on in this call',
      _ => null,
    };

    return _SelfButton(
      style: style,
      iconSize: iconSize,
      icon: call.cameraOn ? Icons.videocam : Icons.videocam_off,
      // Not alarmed when off: a camera that is off is the ordinary state, where
      // a muted microphone is worth flagging.
      alarmed: false,
      busy: call.cameraBusy,
      tooltip:
          blocked ?? (call.cameraOn ? 'Turn camera off' : 'Turn camera on'),
      onPressed: blocked != null
          ? null
          : () => unawaited(_toggle(context, ref, on: !call.cameraOn)),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref, {
    required bool on,
  }) async {
    final controller = ref.read(voiceCallProvider.notifier);

    if (!on) {
      await controller.setCameraEnabled(false);
      return;
    }

    // The sheet comes first, so nothing is sent before the user has seen it.
    final settings = ref.read(voiceSettingsProvider);
    final chosen = await showCameraEffectsSheet(
      context,
      initial: settings.camera,
      confirmLabel: 'Turn camera on',
    );
    if (chosen == null) return;

    // Remembered, so the next time is one tap.
    ref
        .read(voiceSettingsProvider.notifier)
        .update((current) => current.withCamera(chosen));
    await controller.setCameraEnabled(true, options: chosen);
  }
}

/// Starts and stops sharing this client's screen or a window.
///
/// Call state, like the camera: there is nothing to pre-arm, and starting goes
/// through the share picker, where the user chooses what everybody will see —
/// and, for a window, whether they hear it too. Not shown at all where sharing
/// is not possible (`canShareScreen`): a phone can watch a share but not send
/// one.
class VoiceScreenShareButton extends ConsumerWidget {
  const VoiceScreenShareButton({
    super.key,
    this.style = SlotStyle.compact,
    this.iconSize = 20,
  });

  final SlotStyle style;
  final double iconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!canShareScreen) return const SizedBox.shrink();

    final call = ref.watch(voiceCallProvider);
    final sharing = call.screenShare.on;

    // Every sharing place taken by somebody else. Counted from the roster
    // here, since the server's suppression only covers the permission, and a
    // full call should say so before the server has to.
    var full = false;
    if (call case VoiceCallState(:final serverId?, :final channelId?)) {
      final roster = ref.watch(voiceRosterProvider(serverId)).valueOrNull;
      final cap = roster?.maximumScreenShares ?? 0;
      final others =
          roster?.inChannel(channelId).where((p) => p.screenShareOn).length ??
          0;
      full = !sharing && cap > 0 && others >= cap;
    }

    final blocked = switch (call) {
      VoiceCallState(inCall: false) => 'Join a call to share your screen',
      VoiceCallState(screenSharingAvailable: false) =>
        'This server does not carry screen sharing in calls',
      VoiceCallState(screenShareSuppressed: true) when !sharing =>
        'You cannot share your screen in this call',
      _ when full =>
        'Every sharing place in this call is taken. Wait for somebody to stop.',
      _ => null,
    };

    return _SelfButton(
      style: style,
      iconSize: iconSize,
      icon: sharing ? Icons.stop_screen_share : Icons.screen_share,
      alarmed: false,
      busy: call.screenShareBusy,
      tooltip: blocked ?? (sharing ? 'Stop sharing' : 'Share your screen'),
      onPressed: blocked != null
          ? null
          : () => unawaited(_toggle(context, ref, sharing: sharing)),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref, {
    required bool sharing,
  }) async {
    final controller = ref.read(voiceCallProvider.notifier);

    if (sharing) {
      await controller.stopScreenShare();
      return;
    }

    // The picker comes first, so nothing is captured before the user has
    // chosen — and agreed to any sound.
    final chosen = await showScreenSharePicker(context);
    if (chosen == null) return;
    await controller.startScreenShare(chosen);
  }
}

/// The loudspeaker button, on phones. Like mute and deafen it is a remembered
/// setting rather than call state, so a call starts out of whichever one the
/// last call was left on.
class VoiceSpeakerphoneButton extends ConsumerWidget {
  const VoiceSpeakerphoneButton({
    super.key,
    this.style = SlotStyle.compact,
    this.iconSize = 20,
  });

  final SlotStyle style;
  final double iconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Desktop has no earpiece to switch to; its output device picker in
    // settings is the equivalent. Drawing nothing here is what lets this
    // button sit in the shipped layout without appearing there.
    if (!canUseSpeakerphone) return const SizedBox.shrink();

    final on = ref.watch(voiceSettingsProvider.select((s) => s.speakerphone));
    return _SelfButton(
      style: style,
      iconSize: iconSize,
      icon: on ? Icons.volume_up : Icons.phone_in_talk,
      // Neither setting is a problem, so neither is drawn as one.
      alarmed: false,
      tooltip: on ? 'Use the earpiece' : 'Use the speaker',
      onPressed: ref.read(voiceSettingsProvider.notifier).toggleSpeakerphone,
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
    this.busy = false,
  });

  final SlotStyle style;
  final double iconSize;
  final IconData icon;

  /// Muted or deafened: drawn in the error colour.
  final bool alarmed;
  final String tooltip;

  /// Null disables the button; the tooltip then says why.
  final VoidCallback? onPressed;

  /// A spinner in place of the icon. Only the camera and the share need this:
  /// starting either is a round trip through the server and the media server,
  /// where mute and deafen are immediate.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final color = alarmed ? Theme.of(context).colorScheme.error : null;
    return switch (style) {
      SlotStyle.rail => RailButton(
        icon: icon,
        iconColor: color,
        tooltip: tooltip,
        onTap: onPressed ?? () {},
      ),
      SlotStyle.compact => IconButton(
        iconSize: iconSize,
        visualDensity: VisualDensity.compact,
        tooltip: tooltip,
        icon: busy
            ? AdaptiveActivityIndicator(size: iconSize)
            : Icon(icon, color: color),
        onPressed: busy ? null : onPressed,
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
