/// Screen shares in the voice view: the card for one this client is not
/// watching, the tile for one it is, the full-window view, and the bar that
/// says what this client is sharing itself.
///
/// Like the camera tiles, everything here draws a [VoiceVideoFeed] it was
/// handed and names no track type — the feed builds its own surface.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/voice_api.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/voice/voice_engine.dart';
import '../../../core/voice/voice_video_view.dart';
import '../../../core/widgets/adaptive.dart';
import '../controllers/member_media_controller.dart';
import '../controllers/voice_call_controller.dart';
import 'voice_video_tile.dart';

/// What somebody is sharing, in words: "a window, with its sound".
String screenShareDescription(VoiceParticipant participant) {
  final what = participant.screenShareKind == VoiceShareKinds.window
      ? 'a window'
      : 'their screen';
  return participant.screenShareAudio ? '$what, with its sound' : what;
}

/// Why a share this client could watch is not being shown.
enum VoiceScreenShareCardState {
  /// Not watched: nothing is being received from it. The card offers Watch.
  available,

  /// Being set up — published but not yet received, or watched and the first
  /// frame not yet in.
  starting,

  /// Arrived unencrypted or is not decrypting. Never shown or played.
  untrusted,
}

/// A share this client is not showing, and why, with Watch when it can be.
///
/// **Nothing is received until Watch is pressed**: the media server forwards
/// nothing of a share to a member who has not chosen to watch it.
class VoiceScreenShareCard extends StatelessWidget {
  const VoiceScreenShareCard({
    super.key,
    required this.participant,
    required this.displayName,
    required this.state,
    this.onWatch,
    this.onStopWatching,
  });

  final VoiceParticipant participant;
  final String displayName;
  final VoiceScreenShareCardState state;

  /// Given for [VoiceScreenShareCardState.available].
  final VoidCallback? onWatch;

  /// Given while it is watched but not showing yet, so a share that never
  /// arrives can be let go of.
  final VoidCallback? onStopWatching;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final untrusted = state == VoiceScreenShareCardState.untrusted;
    final colour = untrusted
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;

    return Container(
      width: voiceVideoTileWidth,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.surfaces.raised,
        borderRadius: BorderRadius.circular(12),
      ),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                untrusted
                    ? Icons.gpp_bad_outlined
                    : Icons.screen_share_outlined,
                size: 24,
                color: colour,
              ),
              const SizedBox(height: 6),
              Text(
                '$displayName is sharing ${screenShareDescription(participant)}',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              switch (state) {
                VoiceScreenShareCardState.available => FilledButton.tonalIcon(
                  onPressed: onWatch,
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Watch'),
                ),
                VoiceScreenShareCardState.starting => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AdaptiveActivityIndicator(size: 14),
                    const SizedBox(width: 8),
                    Text('Starting…', style: theme.textTheme.labelSmall),
                    if (onStopWatching != null)
                      IconButton(
                        tooltip: 'Stop watching',
                        visualDensity: VisualDensity.compact,
                        iconSize: 16,
                        onPressed: onStopWatching,
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
                VoiceScreenShareCardState.untrusted => Text(
                  'This share is not encrypted, so it is not shown',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(color: colour),
                ),
              },
            ],
          ),
        ),
      ),
    );
  }
}

/// A share being watched: the whole picture, never cropped and never
/// mirrored, with its sound's volume, a full-window view, and Stop watching.
class VoiceScreenShareTile extends ConsumerWidget {
  const VoiceScreenShareTile({
    super.key,
    required this.feed,
    required this.serverId,
    required this.participant,
    required this.displayName,
    this.onFocus,
  });

  final VoiceVideoFeed feed;
  final String serverId;
  final VoiceParticipant participant;
  final String displayName;

  /// Given when this tile is one of several watched and not the one shown
  /// large: tapping it brings it forward.
  final VoidCallback? onFocus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final call = ref.read(voiceCallProvider.notifier);
    ref.watch(memberAudioProvider);
    final media = ref
        .read(memberAudioProvider.notifier)
        .of(serverId, participant.userId);

    final picture = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ColoredBox(
        color: Colors.black,
        child: VoiceVideoView(feed: feed, fit: BoxFit.contain),
      ),
    );

    // Small, in a strip of other watched shares: the picture and a name, and
    // a tap to bring it forward.
    if (onFocus != null) {
      return SizedBox(
        width: voiceVideoTileWidth,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onFocus,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              picture,
              const SizedBox(height: 4),
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(child: Center(child: picture)),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.screen_share_outlined,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$displayName is sharing ${screenShareDescription(participant)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            if (participant.screenShareAudio) ...[
              Tooltip(
                message:
                    "The sound of their window, only for you — their voice "
                    'has its own volume',
                child: Icon(
                  media.screenVolume == 0 ? Icons.volume_off : Icons.volume_up,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(
                width: 140,
                child: Slider.adaptive(
                  value: media.screenVolume,
                  max: maximumVolume,
                  divisions: 20,
                  label: '${(media.screenVolume * 100).round()}%',
                  onChanged: (value) => ref
                      .read(memberAudioProvider.notifier)
                      .setScreenVolume(serverId, participant.userId, value),
                ),
              ),
            ],
            IconButton(
              tooltip: 'Full view',
              icon: const Icon(Icons.fullscreen),
              onPressed: () => showScreenShareFullView(
                context,
                userId: participant.userId,
                displayName: displayName,
              ),
            ),
            IconButton(
              tooltip: 'Stop watching',
              icon: const Icon(Icons.visibility_off_outlined),
              onPressed: () =>
                  call.setScreenShareWatched(participant.userId, false),
            ),
          ],
        ),
      ],
    );
  }
}

/// Shows [userId]'s share on its own, filling the window, until Escape or the
/// close button — or until the share ends (they stopped it, left the call, or
/// this client left it), when it closes itself.
Future<void> showScreenShareFullView(
  BuildContext context, {
  required String userId,
  required String displayName,
}) => Navigator.of(context, rootNavigator: true).push(
  MaterialPageRoute<void>(
    fullscreenDialog: true,
    builder: (_) =>
        _ScreenShareFullView(userId: userId, displayName: displayName),
  ),
);

class _ScreenShareFullView extends ConsumerStatefulWidget {
  const _ScreenShareFullView({required this.userId, required this.displayName});

  final String userId;
  final String displayName;

  @override
  ConsumerState<_ScreenShareFullView> createState() =>
      _ScreenShareFullViewState();
}

class _ScreenShareFullViewState extends ConsumerState<_ScreenShareFullView> {
  /// Whether a picture has been shown yet. Until then a missing feed is the
  /// share still arriving, not the share having ended.
  bool _shown = false;
  bool _closing = false;

  String get userId => widget.userId;
  String get displayName => widget.displayName;

  /// Closes once, after the frame: never mid-build, and never twice when the
  /// share and the call end in the same moment.
  void _closeWhenEnded() {
    if (_closing) return;
    _closing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(
      voiceCallProvider.select((call) => call.screenFeedFor(userId)),
    );
    final ended = ref.watch(
      voiceCallProvider.select(
        (call) =>
            !call.inCall ||
            !call.watching.contains(userId) ||
            !(call.screenShares.contains(userId) ||
                call.untrustedScreenShares.contains(userId)),
      ),
    );
    if (feed != null) _shown = true;
    if (ended || (_shown && feed == null)) _closeWhenEnded();

    void close() => Navigator.of(context).maybePop();

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): close},
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Positioned.fill(
                // No picture: either it has not arrived yet, or the share just
                // ended and this view is about to close.
                child: feed == null
                    ? Center(
                        child: Text(
                          _shown
                              ? '$displayName stopped sharing.'
                              : "Waiting for $displayName's screen…",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      )
                    // The whole picture, never cropped: a share is a document,
                    // and the edge of it is as likely to matter as the middle.
                    : feed.buildSurface(context, fit: BoxFit.contain),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: SafeArea(
                  child: IconButton.filledTonal(
                    tooltip: 'Close (Esc)',
                    icon: const Icon(Icons.close),
                    onPressed: close,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What this client is sharing, while it is: what, whether its sound is going
/// too, a small preview of exactly what everybody else sees, and Stop.
class VoiceOwnShareBar extends ConsumerStatefulWidget {
  const VoiceOwnShareBar({super.key, required this.userId});

  /// This client's own member id, to find its share's feed.
  final String userId;

  @override
  ConsumerState<VoiceOwnShareBar> createState() => _VoiceOwnShareBarState();
}

class _VoiceOwnShareBarState extends ConsumerState<VoiceOwnShareBar> {
  /// Whether the preview is shown. It can be folded away, and is then not
  /// drawn at all: a local preview of a large screen costs a texture upload
  /// every frame, for a picture its sharer can already see.
  bool _preview = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final call = ref.watch(voiceCallProvider);
    final share = call.screenShare;
    final source = share.source;
    if (source == null) return const SizedBox.shrink();

    final feed = call.screenFeedFor(widget.userId);
    final what = source.kind == VoiceScreenSourceKind.window
        ? '“${source.name}”'
        : source.name;

    return Material(
      color: context.surfaces.raised,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.screen_share,
                  size: 18,
                  color: context.surfaces.onlineIndicator,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    share.withAudio
                        ? "You're sharing $what, with its sound"
                        : "You're sharing $what",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                IconButton(
                  tooltip: _preview ? 'Hide preview' : 'Show preview',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(_preview ? Icons.expand_less : Icons.expand_more),
                  onPressed: () => setState(() => _preview = !_preview),
                ),
                TextButton.icon(
                  onPressed: call.screenShareBusy
                      ? null
                      : () => ref
                            .read(voiceCallProvider.notifier)
                            .stopScreenShare(),
                  icon: const Icon(Icons.stop_screen_share, size: 18),
                  label: const Text('Stop sharing'),
                ),
              ],
            ),
            if (_preview && feed != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: SizedBox(
                  width: voiceVideoTileWidth,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ColoredBox(
                      color: Colors.black,
                      child: VoiceVideoView(feed: feed, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
