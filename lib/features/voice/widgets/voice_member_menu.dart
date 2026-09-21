import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/channels_api.dart';
import '../../../core/network/voice_api.dart';
import '../../../core/platform/platform_info.dart';
import '../../../core/voice/voice_engine.dart';
import '../../servers/controllers/server_permissions.dart';
import '../../servers/controllers/session_controller.dart';
import '../controllers/member_audio_controller.dart';

/// The menu for one member in a call — right-click on desktop, long press on
/// touch: how loud they are here, muting them here, and (for a moderator)
/// muting them for everyone.
///
/// Volume and the local mute change only this device and apply the moment
/// they are touched; "Mute for everyone" asks the server, which enforces it.
Future<void> showVoiceMemberMenu(
  BuildContext context, {
  required String serverId,
  required VoiceParticipant participant,
  required String displayName,
  Offset? position,
}) async {
  final controls = _VoiceMemberControls(
    serverId: serverId,
    participant: participant,
    displayName: displayName,
  );

  if (isDesktopPlatform && position != null) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    await showMenu<void>(
      context: context,
      position: RelativeRect.fromRect(
        position & Size.zero,
        Offset.zero & overlay.size,
      ),
      items: [_ControlsEntry(child: controls)],
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => SafeArea(child: controls),
  );
}

/// A menu entry that is not an item: dragging the slider or ticking the box
/// inside it must not close the menu the way tapping a [PopupMenuItem] does.
class _ControlsEntry extends PopupMenuEntry<void> {
  const _ControlsEntry({required this.child});

  final Widget child;

  @override
  double get height => 180;

  @override
  bool represents(void value) => false;

  @override
  State<_ControlsEntry> createState() => _ControlsEntryState();
}

class _ControlsEntryState extends State<_ControlsEntry> {
  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 280, child: widget.child);
}

class _VoiceMemberControls extends ConsumerWidget {
  const _VoiceMemberControls({
    required this.serverId,
    required this.participant,
    required this.displayName,
  });

  final String serverId;
  final VoiceParticipant participant;
  final String displayName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Watched so the slider and box follow what they set.
    ref.watch(memberAudioProvider);
    final audioController = ref.read(memberAudioProvider.notifier);
    final audio = audioController.of(serverId, participant.userId);
    final mayMuteForEveryone =
        ref
            .watch(serverPermissionsProvider(serverId))
            .valueOrNull
            ?.can(ChannelPermissionNames.muteMembers) ??
        false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayName,
            style: theme.textTheme.titleSmall,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Volume', style: theme.textTheme.bodySmall),
              const Spacer(),
              Text(
                '${(audio.volume * 100).round()}%',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          Slider.adaptive(
            value: audio.volume,
            max: maximumVolume,
            // 5% steps; 100% is one of them, so it is easy to land back on.
            divisions: (maximumVolume * 20).round(),
            onChanged: (value) =>
                audioController.setVolume(serverId, participant.userId, value),
          ),
          CheckboxListTile(
            value: audio.muted,
            onChanged: (muted) => audioController.setMuted(
              serverId,
              participant.userId,
              muted ?? false,
            ),
            title: const Text('Mute'),
            subtitle: const Text('Only for you'),
            contentPadding: EdgeInsets.zero,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
          ),
          if (mayMuteForEveryone)
            ListTile(
              leading: Icon(
                participant.serverMute ? Icons.mic : Icons.mic_off,
                color: participant.serverMute ? null : theme.colorScheme.error,
              ),
              title: Text(
                participant.serverMute
                    ? 'Unmute for everyone'
                    : 'Mute for everyone',
              ),
              contentPadding: EdgeInsets.zero,
              dense: true,
              onTap: () =>
                  _setServerMute(context, ref, !participant.serverMute),
            ),
        ],
      ),
    );
  }

  Future<void> _setServerMute(
    BuildContext context,
    WidgetRef ref,
    bool muted,
  ) async {
    // Read before closing: closing unmounts this widget, and its ref with it.
    final messenger = ScaffoldMessenger.maybeOf(context);
    final pending = ref.read(serverSessionProvider(serverId).future);
    Navigator.of(context).pop();

    final session = await pending;
    if (session == null) return;

    try {
      await session.voiceApi.setServerMute(
        session.token,
        userId: participant.userId,
        muted: muted,
      );
    } on ApiException catch (e) {
      messenger?.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}
