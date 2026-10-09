import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/voice_api.dart';
import '../../../core/theme/app_colors.dart';
import '../../servers/controllers/user_lookup.dart';
import '../controllers/member_media_controller.dart';
import '../controllers/voice_call_controller.dart';
import 'voice_member_menu.dart';

/// A member's name, resolved from their UUID — never from the call, whose
/// copy of the name goes stale when somebody is renamed mid-call.
String voiceMemberName(WidgetRef ref, String serverId, String userId) =>
    ref
        .watch(userLookupProvider((serverId: serverId, userId: userId)))
        .valueOrNull
        ?.username ??
    userId.substring(0, 8);

/// Whether [userId] is talking right now — known only for the call this
/// client is in.
bool _isSpeaking(WidgetRef ref, String serverId, String userId) => ref.watch(
  voiceCallProvider.select(
    (call) => call.serverId == serverId && call.speaking.contains(userId),
  ),
);

/// A member in a call, as a card in the voice channel's view.
class VoiceParticipantTile extends ConsumerWidget {
  const VoiceParticipantTile({
    super.key,
    required this.serverId,
    required this.participant,
    required this.isCurrentUser,
  });

  final String serverId;
  final VoiceParticipant participant;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final name = voiceMemberName(ref, serverId, participant.userId);
    final speaking = _isSpeaking(ref, serverId, participant.userId);

    return _MemberMenuTarget(
      enabled: !isCurrentUser,
      serverId: serverId,
      participant: participant,
      displayName: name,
      child: Opacity(
        opacity: participant.connected ? 1 : 0.55,
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.surfaces.raised,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: speaking
                  ? context.surfaces.onlineIndicator
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              VoiceAvatar(name: name, speaking: speaking, radius: 28),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      isCurrentUser ? '$name (you)' : name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 18,
                child: VoiceStatusIcons(
                  serverId: serverId,
                  participant: participant,
                  isCurrentUser: isCurrentUser,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A member in a call, as a compact row under the channel in the sidebar.
class VoiceParticipantRow extends ConsumerWidget {
  const VoiceParticipantRow({
    super.key,
    required this.serverId,
    required this.participant,
    required this.isCurrentUser,
  });

  final String serverId;
  final VoiceParticipant participant;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final name = voiceMemberName(ref, serverId, participant.userId);
    final speaking = _isSpeaking(ref, serverId, participant.userId);

    return _MemberMenuTarget(
      enabled: !isCurrentUser,
      serverId: serverId,
      participant: participant,
      displayName: name,
      child: Opacity(
        opacity: participant.connected ? 1 : 0.55,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(36, 2, 12, 2),
          child: Row(
            children: [
              VoiceAvatar(name: name, speaking: speaking, radius: 10),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              VoiceStatusIcons(
                serverId: serverId,
                participant: participant,
                isCurrentUser: isCurrentUser,
                color: scheme.onSurfaceVariant,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An initial in a circle, ringed while its owner is talking.
class VoiceAvatar extends StatelessWidget {
  const VoiceAvatar({
    super.key,
    required this.name,
    required this.speaking,
    required this.radius,
  });

  final String name;
  final bool speaking;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: speaking
              ? context.surfaces.onlineIndicator
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: scheme.secondaryContainer,
        child: Text(
          name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
          style: TextStyle(
            color: scheme.onSecondaryContainer,
            fontWeight: FontWeight.w700,
            fontSize: radius * 0.8,
          ),
        ),
      ),
    );
  }
}

/// Why somebody cannot be heard, as small icons: deafened, muted by
/// themselves, muted for everyone by a moderator, unable to speak here, or
/// muted by this client only.
class VoiceStatusIcons extends ConsumerWidget {
  const VoiceStatusIcons({
    super.key,
    required this.serverId,
    required this.participant,
    required this.isCurrentUser,
    required this.color,
    this.size = 16,
  });

  /// The same icons over a camera, where the picture behind them is whatever
  /// the camera is pointed at, so they are always drawn light.
  const VoiceStatusIcons.overVideo({
    super.key,
    required this.serverId,
    required this.participant,
    required this.isCurrentUser,
    this.size = 14,
  }) : color = Colors.white;

  final String serverId;
  final VoiceParticipant participant;
  final bool isCurrentUser;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = Theme.of(context).colorScheme.error;
    ref.watch(memberAudioProvider);
    final media = ref
        .read(memberAudioProvider.notifier)
        .of(serverId, participant.userId);
    final locallyMuted = !isCurrentUser && media.muted;
    final cameraHidden =
        !isCurrentUser && participant.cameraOn && media.videoHidden;

    Widget icon(IconData data, String tooltip, Color tint) => Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Icon(data, size: size, color: tint),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (participant.serverMute)
          icon(Icons.mic_off, 'Muted for everyone by a moderator', error)
        else if (participant.suppressed)
          icon(Icons.voice_over_off, 'Can listen but not speak here', error)
        else if (participant.selfMute && !participant.selfDeaf)
          icon(Icons.mic_off, 'Muted', color),
        if (participant.selfDeaf) icon(Icons.headset_off, 'Deafened', color),
        if (locallyMuted) icon(Icons.volume_off, 'Muted by you', color),
        if (cameraHidden)
          icon(Icons.videocam_off, 'Camera hidden by you', color),
        if (participant.screenShareOn)
          icon(
            Icons.screen_share,
            participant.screenShareKind == VoiceShareKinds.window
                ? participant.screenShareAudio
                      ? 'Sharing a window, with its sound'
                      : 'Sharing a window'
                : 'Sharing their screen',
            color,
          ),
      ],
    );
  }
}

/// Opens [showVoiceMemberMenu] the way each platform opens a menu: right-click
/// on desktop, long press on touch. Nothing for your own entry — your own
/// microphone has its own controls.
class _MemberMenuTarget extends StatelessWidget {
  const _MemberMenuTarget({
    required this.enabled,
    required this.serverId,
    required this.participant,
    required this.displayName,
    required this.child,
  });

  final bool enabled;
  final String serverId;
  final VoiceParticipant participant;
  final String displayName;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    void open(Offset position) => showVoiceMemberMenu(
      context,
      serverId: serverId,
      participant: participant,
      displayName: displayName,
      position: position,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown: (details) => open(details.globalPosition),
      onLongPressStart: (details) => open(details.globalPosition),
      child: MouseRegion(cursor: SystemMouseCursors.contextMenu, child: child),
    );
  }
}
