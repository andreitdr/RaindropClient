import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/voice_api.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/voice/voice_engine.dart';
import '../../../core/widgets/adaptive.dart';
import '../../channels/models/channel.dart';
import '../../servers/controllers/session_controller.dart';
import '../controllers/voice_call_controller.dart';
import '../controllers/voice_roster_controller.dart';
import '../controllers/member_media_controller.dart';
import 'voice_controls.dart';
import 'voice_participant_tile.dart';
import 'voice_screen_share_tile.dart';
import 'voice_video_tile.dart';

/// What the main pane shows for a voice channel: who is in its call, and the
/// way in — or, once in it, the controls to mute, deafen and hang up, and the
/// screens being shared in it.
/// Selecting a voice channel only opens this; joining is the button, a
/// deliberate second step.
///
/// **A share takes the stage only once it is watched.** Until then it is a
/// card among the participants with a Watch button, and nothing of it is
/// received; watched, it is drawn large above them.
class VoiceChannelView extends ConsumerWidget {
  const VoiceChannelView({
    super.key,
    required this.serverId,
    required this.channel,
    this.leading,
    this.trailingActions = const [],
  });

  final String serverId;
  final Channel channel;
  final Widget? leading;
  final List<Widget> trailingActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roster =
        ref.watch(voiceRosterProvider(serverId)).valueOrNull ??
        VoiceRoster.empty;
    final participants = roster.inChannel(channel.id);
    final call = ref.watch(voiceCallProvider);
    final here = call.isIn(serverId, channel.id);
    final me = ref
        .watch(serverSessionProvider(serverId))
        .valueOrNull
        ?.currentUser
        .userId;

    return ColoredBox(
      color: context.surfaces.chat,
      child: Column(
        children: [
          _TopBar(
            channel: channel,
            leading: leading,
            actions: trailingActions,
            count: participants.length,
            capacity: roster.maximumParticipants,
            cameras: participants.where((p) => p.cameraOn).length,
            cameraCapacity: roster.maximumCameraPublishers,
            shares: participants.where((p) => p.screenShareOn).length,
            shareCapacity: roster.maximumScreenShares,
          ),
          const Divider(height: 1),
          if (here && call.screenShare.on && me != null)
            VoiceOwnShareBar(userId: me),
          Expanded(child: _body(context, ref, participants, call, here, me)),
          if (here && (call.serverMuted || call.suppressed))
            _Banner(
              call.serverMuted
                  ? 'A moderator muted you for everyone. You can still listen.'
                  : 'You can listen here, but not speak.',
            ),
          if (here && call.warning != null)
            _Banner(
              call.warning!,
              onDismiss: ref.read(voiceCallProvider.notifier).dismissWarning,
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: here
                  ? _InCallControls(status: call.status)
                  : _JoinButton(
                      serverId: serverId,
                      channel: channel,
                      available: roster.available,
                      full:
                          roster.maximumParticipants > 0 &&
                          participants.length >= roster.maximumParticipants &&
                          !participants.any((p) => p.userId == me),
                      inOtherCall: call.inCall,
                      joining:
                          call.status == VoiceCallStatus.joining &&
                          call.serverId == serverId &&
                          call.channelId == channel.id,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One member's share as this client sees it: drawn, when watched and arriving;
/// otherwise the card standing in for it.
typedef _WatchedShare = ({VoiceParticipant participant, VoiceVideoFeed feed});

extension on VoiceChannelView {
  Widget _body(
    BuildContext context,
    WidgetRef ref,
    List<VoiceParticipant> participants,
    VoiceCallState call,
    bool here,
    String? me,
  ) {
    final theme = Theme.of(context);
    if (participants.isEmpty) {
      return Center(
        child: Text(
          'Nobody is here yet.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // Shares can only be watched from inside the call; from outside, the
    // roster's icon says somebody is sharing and that is all.
    final sharers = here
        ? [
            for (final p in participants)
              if (p.screenShareOn && p.userId != me) p,
          ]
        : const <VoiceParticipant>[];

    final watched = <_WatchedShare>[];
    final cards = <Widget>[];
    final controller = ref.read(voiceCallProvider.notifier);

    for (final sharer in sharers) {
      final id = sharer.userId;
      final name = voiceMemberName(ref, serverId, id);
      final isWatching = call.watching.contains(id);
      final untrusted = call.untrustedScreenShares.contains(id);
      final feed = call.screenFeedFor(id);

      if (isWatching && !untrusted && feed != null) {
        watched.add((participant: sharer, feed: feed));
        continue;
      }

      cards.add(
        VoiceScreenShareCard(
          participant: sharer,
          displayName: name,
          state: untrusted
              ? VoiceScreenShareCardState.untrusted
              : isWatching || !call.screenShares.contains(id)
              ? VoiceScreenShareCardState.starting
              : VoiceScreenShareCardState.available,
          onWatch: () => controller.setScreenShareWatched(id, true),
          onStopWatching: isWatching
              ? () => controller.setScreenShareWatched(id, false)
              : null,
        ),
      );
    }

    final tiles = [
      ...cards,
      for (final participant in participants)
        _ParticipantSlot(
          serverId: serverId,
          participant: participant,
          isCurrentUser: participant.userId == me,
        ),
    ];

    if (watched.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: tiles,
          ),
        ),
      );
    }

    return _ShareStage(serverId: serverId, watched: watched, below: tiles);
  }
}

/// A watched share drawn large, with every other watched share, every share
/// card and every participant in a strip beneath it. Which share is large is
/// this view's own choice — tapping another in the strip brings it forward —
/// and when the one in front stops, the next takes its place.
class _ShareStage extends ConsumerStatefulWidget {
  const _ShareStage({
    required this.serverId,
    required this.watched,
    required this.below,
  });

  final String serverId;
  final List<_WatchedShare> watched;
  final List<Widget> below;

  @override
  ConsumerState<_ShareStage> createState() => _ShareStageState();
}

class _ShareStageState extends ConsumerState<_ShareStage> {
  String? _focused;

  @override
  Widget build(BuildContext context) {
    final front =
        widget.watched
            .where((share) => share.participant.userId == _focused)
            .firstOrNull ??
        widget.watched.first;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: VoiceScreenShareTile(
              feed: front.feed,
              serverId: widget.serverId,
              participant: front.participant,
              displayName: voiceMemberName(
                ref,
                widget.serverId,
                front.participant.userId,
              ),
            ),
          ),
        ),
        SizedBox(
          height: 176,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              spacing: 12,
              children: [
                for (final share in widget.watched)
                  if (share != front)
                    VoiceScreenShareTile(
                      feed: share.feed,
                      serverId: widget.serverId,
                      participant: share.participant,
                      displayName: voiceMemberName(
                        ref,
                        widget.serverId,
                        share.participant.userId,
                      ),
                      onFocus: () =>
                          setState(() => _focused = share.participant.userId),
                    ),
                ...widget.below,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// What one participant looks like: their camera, a placeholder saying why it
/// is not shown, or the plain tile when they have no camera on.
class _ParticipantSlot extends ConsumerWidget {
  const _ParticipantSlot({
    required this.serverId,
    required this.participant,
    required this.isCurrentUser,
  });

  final String serverId;
  final VoiceParticipant participant;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final call = ref.watch(voiceCallProvider);
    final displayName = voiceMemberName(ref, serverId, participant.userId);

    if (!participant.cameraOn) {
      return VoiceParticipantTile(
        serverId: serverId,
        participant: participant,
        isCurrentUser: isCurrentUser,
      );
    }

    // Untrusted outranks hidden: nothing untrusted is ever drawn, and saying
    // "hidden by you" about a camera that is actually refused would be a lie.
    if (call.untrustedVideo.contains(participant.userId)) {
      return VoiceVideoPlaceholder(
        reason: VoiceVideoHiddenReason.untrusted,
        displayName: displayName,
      );
    }

    ref.watch(memberAudioProvider);
    final hidden =
        !isCurrentUser &&
        ref
            .read(memberAudioProvider.notifier)
            .of(serverId, participant.userId)
            .videoHidden;

    if (hidden) {
      return VoiceVideoPlaceholder(
        reason: VoiceVideoHiddenReason.hiddenByYou,
        displayName: displayName,
        onShow: () => ref
            .read(memberAudioProvider.notifier)
            .setVideoHidden(serverId, participant.userId, false),
      );
    }

    final feed = call.feedFor(participant.userId);
    if (feed == null) {
      // Their camera is on and nothing has arrived yet — joining, or a track
      // still being negotiated. The plain tile is the honest thing to show.
      return VoiceParticipantTile(
        serverId: serverId,
        participant: participant,
        isCurrentUser: isCurrentUser,
      );
    }

    return VoiceVideoTile(
      feed: feed,
      serverId: serverId,
      participant: participant,
      displayName: displayName,
      isCurrentUser: isCurrentUser,
      speaking: call.speaking.contains(participant.userId),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.channel,
    required this.leading,
    required this.actions,
    required this.count,
    required this.capacity,
    required this.cameras,
    required this.cameraCapacity,
    required this.shares,
    required this.shareCapacity,
  });

  final Channel channel;
  final Widget? leading;
  final List<Widget> actions;
  final int count;
  final int capacity;
  final int cameras;

  /// 0 when this server carries no camera video, which hides the counter.
  final int cameraCapacity;

  final int shares;

  /// 0 when this server carries no screen sharing, which hides the counter.
  final int shareCapacity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      bottom: false,
      left: false,
      right: false,
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            ?leading,
            const SizedBox(width: 8),
            Icon(
              Icons.volume_up_outlined,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(channel.name, style: theme.textTheme.titleMedium),
            const SizedBox(width: 12),
            if (capacity > 0)
              Text(
                '$count / $capacity',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            // Shown beside the member count, because the camera limit is a
            // separate and much smaller one, and running into it without
            // warning would be baffling.
            if (cameraCapacity > 0) ...[
              const SizedBox(width: 10),
              Icon(
                Icons.videocam_outlined,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '$cameras / $cameraCapacity',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            // And the sharing limit, smaller still.
            if (shareCapacity > 0) ...[
              const SizedBox(width: 10),
              Tooltip(
                message: 'Screens being shared, of the most this call carries',
                child: Icon(
                  Icons.screen_share_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '$shares / $shareCapacity',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const Spacer(),
            ...actions,
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner(this.text, {this.onDismiss});

  final String text;

  /// When given, the banner can be closed. The banners that describe a lasting
  /// state — muted for everyone, cannot speak — have no dismiss, because the
  /// state would still be true afterwards; the ones that report something that
  /// already happened do.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: scheme.errorContainer,
      padding: EdgeInsets.fromLTRB(16, 8, onDismiss == null ? 16 : 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: TextStyle(color: scheme.onErrorContainer)),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              color: scheme.onErrorContainer,
              tooltip: 'Dismiss',
              icon: const Icon(Icons.close),
            ),
        ],
      ),
    );
  }
}

class _InCallControls extends ConsumerWidget {
  const _InCallControls({required this.status});

  final VoiceCallStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (status != VoiceCallStatus.connected) ...[
          const AdaptiveActivityIndicator(size: 16),
          const SizedBox(width: 12),
        ],
        const VoiceSelfControls(iconSize: 26),
        // Here as well as in the layout's toolbars: `LayoutConfig.normalize`
        // keeps unknown button ids but never adds new ones, so an existing
        // user's saved layout will not gain the camera or share buttons. This
        // is where they are always reachable.
        const VoiceCameraButton(iconSize: 26),
        const VoiceScreenShareButton(iconSize: 26),
        const SizedBox(width: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: () => ref.read(voiceCallProvider.notifier).leave(),
          icon: const Icon(Icons.call_end),
          label: const Text('Disconnect'),
        ),
      ],
    );
  }
}

class _JoinButton extends ConsumerWidget {
  const _JoinButton({
    required this.serverId,
    required this.channel,
    required this.available,
    required this.full,
    required this.inOtherCall,
    required this.joining,
  });

  final String serverId;
  final Channel channel;
  final bool available;
  final bool full;
  final bool inOtherCall;
  final bool joining;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The reason the button is off, if it is — shown rather than letting a
    // join fail with the same answer from the server.
    final String? blocked = !available
        ? 'Voice calls are not set up on this server.'
        : !channel.canConnect
        ? 'You do not have permission to join this channel.'
        : full
        ? 'This call is full.'
        : null;

    final button = FilledButton.icon(
      onPressed: blocked != null || joining ? null : () => _join(context, ref),
      icon: joining
          ? const AdaptiveActivityIndicator(size: 16)
          : const Icon(Icons.call),
      label: Text(inOtherCall ? 'Switch to this call' : 'Join voice'),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        button,
        if (blocked != null) ...[
          const SizedBox(height: 8),
          Text(
            blocked,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _join(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await ref.read(voiceCallProvider.notifier).join(serverId, channel.id);
    } on ApiException catch (e) {
      messenger?.showSnackBar(SnackBar(content: Text(e.message)));
    } on UnsupportedVoiceTransportException catch (e) {
      messenger?.showSnackBar(SnackBar(content: Text(e.toString())));
    } on VoiceEncryptionUnavailableException catch (e) {
      // Refused rather than joined unencrypted: this server's calls are
      // end-to-end encrypted, and this device could not get the key.
      messenger?.showSnackBar(SnackBar(content: Text(e.toString())));
    } on Object {
      // Connecting failed; the call controller already said so in its
      // notice, which the shell shows.
    }
  }
}
