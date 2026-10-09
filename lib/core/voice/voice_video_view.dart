/// Draws a [VoiceVideoFeed], and a placeholder until it has a frame.
///
/// Deliberately knows nothing about the media library: the feed builds its own
/// surface, so this file is layout and nothing else. That is what lets a video
/// tile live in `features/voice/` without importing a track type.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'voice_engine.dart';

class VoiceVideoView extends StatelessWidget {
  const VoiceVideoView({
    super.key,
    required this.feed,
    this.fit = BoxFit.cover,
    this.aspectRatio = 16 / 9,
  });

  final VoiceVideoFeed feed;
  final BoxFit fit;

  /// The box the video is drawn in, whatever the camera's own shape — a tile in
  /// a wrap has to be a predictable size, and [BoxFit.cover] is what makes a
  /// 4:3 webcam fill a 16:9 tile without letterboxing.
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ColoredBox(
        color: context.surfaces.rail,
        // A camera muted at the source draws nothing at all, which reads as a
        // broken tile; the surface goes in only when there should be a picture.
        child: feed.live
            ? feed.buildSurface(context, fit: fit)
            : Center(
                child: Icon(
                  Icons.videocam_outlined,
                  size: 28,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
      ),
    );
  }
}
