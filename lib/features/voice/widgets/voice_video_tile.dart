/// A participant's camera in the voice view, and the placeholders that stand
/// in for one.
///
/// It hosts `core/voice/`'s [VoiceVideoView], which is what keeps the media
/// library out of `features/` entirely: a feed builds its own surface, so
/// nothing here names a track type.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/voice_api.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/voice/voice_engine.dart';
import '../../../core/voice/voice_video_view.dart';
import 'voice_participant_tile.dart';

/// The width of a camera tile in the voice view's wrap.
///
/// Wider than a [VoiceParticipantTile] because a 16:9 picture at that width
/// would be too small to see a face in, and the wrap handles the mixed widths
/// on its own.
const double voiceVideoTileWidth = 240;

/// One participant's camera.
class VoiceVideoTile extends StatelessWidget {
  const VoiceVideoTile({
    super.key,
    required this.feed,
    required this.serverId,
    required this.participant,
    required this.displayName,
    required this.isCurrentUser,
    this.speaking = false,
  });

  final VoiceVideoFeed feed;
  final String serverId;
  final VoiceParticipant participant;
  final String displayName;
  final bool isCurrentUser;
  final bool speaking;

  @override
  Widget build(BuildContext context) {
    return _TileFrame(
      speaking: speaking,
      child: Stack(
        fit: StackFit.expand,
        children: [
          VoiceVideoView(feed: feed),
          // A scrim, because a name in plain text over a camera is unreadable
          // against a bright background and invisible against a dark one.
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _Scrim(),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 6,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isCurrentUser ? '$displayName (you)' : displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(
                  height: 16,
                  child: VoiceStatusIcons.overVideo(
                    serverId: serverId,
                    participant: participant,
                    isCurrentUser: isCurrentUser,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Why a camera that is on is not being shown.
enum VoiceVideoHiddenReason {
  /// Hidden here, by this user. Theirs to undo.
  hiddenByYou,

  /// Not encrypted, or not decrypting. Never theirs to undo: nothing
  /// untrusted is ever drawn.
  untrusted,
}

/// The same box as a camera, saying why there is no camera in it.
class VoiceVideoPlaceholder extends ConsumerWidget {
  const VoiceVideoPlaceholder({
    super.key,
    required this.reason,
    required this.displayName,
    this.onShow,
  });

  final VoiceVideoHiddenReason reason;
  final String displayName;

  /// Given only for [VoiceVideoHiddenReason.hiddenByYou].
  final VoidCallback? onShow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final (icon, message, colour) = switch (reason) {
      VoiceVideoHiddenReason.hiddenByYou => (
        Icons.videocam_off_outlined,
        'Camera hidden',
        theme.colorScheme.onSurfaceVariant,
      ),
      VoiceVideoHiddenReason.untrusted => (
        Icons.gpp_bad_outlined,
        'This camera is not encrypted, so it is not shown',
        theme.colorScheme.error,
      ),
    };

    return _TileFrame(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: colour),
            const SizedBox(height: 8),
            Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 2),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(color: colour),
            ),
            if (onShow != null) ...[
              const SizedBox(height: 4),
              TextButton(onPressed: onShow, child: const Text('Show')),
            ],
          ],
        ),
      ),
    );
  }
}

/// The box every camera tile and placeholder shares, so they line up in the
/// wrap whatever is inside them.
class _TileFrame extends StatelessWidget {
  const _TileFrame({required this.child, this.speaking = false});

  final Widget child;
  final bool speaking;

  @override
  Widget build(BuildContext context) => Container(
    width: voiceVideoTileWidth,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: context.surfaces.raised,
      borderRadius: BorderRadius.circular(12),
      // The same green as the participant tiles' speaking ring and the online
      // dot, so no new theme colour is needed.
      border: speaking
          ? Border.all(color: context.surfaces.onlineIndicator, width: 2)
          : null,
    ),
    child: AspectRatio(aspectRatio: 16 / 9, child: child),
  );
}

class _Scrim extends StatelessWidget {
  const _Scrim();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Color(0xCC000000), Color(0x00000000)],
      ),
    ),
    child: SizedBox(height: 36, width: double.infinity),
  );
}
