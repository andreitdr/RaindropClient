import 'dart:async';
import 'dart:io';

import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail_platform_interface.dart'
    show FcVideoThumbnailTime, FcVideoThumbnailTimeUnit;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'media_playback.dart';

/// [MediaPlayback] through the system's own player, via video_player:
/// AVFoundation on iOS and macOS, Media Foundation on Windows (x64 and ARM64,
/// through video_player_win, which registers itself as video_player's Windows
/// implementation). See `playsMediaThroughSystemPlayer`.
class SystemPlayback implements MediaPlayback {
  SystemPlayback._(this._controller) {
    _controller.addListener(_changed);
  }

  final VideoPlayerController _controller;
  final _values = StreamController<VideoPlayerValue>.broadcast();

  static Future<SystemPlayback> open(String path) async {
    final controller = VideoPlayerController.file(File(path));
    try {
      await controller.initialize();
    } on Object catch (error) {
      await controller.dispose();
      throw StateError('The system player could not open the file ($error)');
    }
    if (!controller.value.isInitialized || controller.value.hasError) {
      final reason = controller.value.errorDescription;
      await controller.dispose();
      throw StateError('The system player could not open the file ($reason)');
    }
    final playback = SystemPlayback._(controller);
    await controller.play();
    return playback;
  }

  /// A still from two seconds in (or the first frame, for a shorter video),
  /// at most [_stillEdge] on its longer side. Windows' shell thumbnail cache
  /// cannot seek, so there it is whatever frame Windows picks.
  static Future<VideoStill?> grabStill(String path) async {
    final thumbnails = FcNativeVideoThumbnail();
    Future<VideoStill?> at(FcVideoThumbnailTime? time) async {
      final jpeg = await thumbnails.saveThumbnailToBytes(
        srcFile: path,
        width: _stillEdge,
        height: _stillEdge,
        format: 'jpeg',
        quality: 90,
        at: time,
      );
      return jpeg == null ? null : VideoStill(jpeg);
    }

    try {
      final twoSecondsIn = await at(
        FcVideoThumbnailTime(2, FcVideoThumbnailTimeUnit.seconds),
      );
      if (twoSecondsIn != null) return twoSecondsIn;
    } on Object {
      // Shorter than two seconds: fall through to the first frame.
    }
    try {
      return await at(null);
    } on Object {
      return null;
    }
  }

  /// Bigger than the 320-pixel thumbnail it is shrunk to, so the shrink has
  /// something to work with.
  static const _stillEdge = 640;

  void _changed() => _values.add(_controller.value);

  Stream<T> _watch<T>(T Function(VideoPlayerValue value) pick) => startingWith(
    pick(_controller.value),
    _values.stream.map(pick),
  ).distinct();

  @override
  Stream<bool> get playing => _watch((v) => v.isPlaying);

  @override
  Stream<Duration> get position => _watch((v) => v.position);

  @override
  Stream<Duration> get duration => _watch((v) => v.duration);

  @override
  Future<void> playOrPause() =>
      _controller.value.isPlaying ? _controller.pause() : _controller.play();

  @override
  Future<void> seek(Duration to) => _controller.seekTo(to);

  @override
  Widget view() => _SystemVideoView(this);

  @override
  Future<void> dispose() async {
    _controller.removeListener(_changed);
    await _values.close();
    await _controller.dispose();
  }
}

/// The picture at its own aspect ratio, with what media_kit's own controls
/// give on the other platforms: a tap to play or pause, and a seek bar.
class _SystemVideoView extends StatelessWidget {
  const _SystemVideoView(this.playback);

  final SystemPlayback playback;

  @override
  Widget build(BuildContext context) {
    final controller = playback._controller;
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final total = value.duration;
        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: Colors.black,
              child: Center(
                child: AspectRatio(
                  aspectRatio: value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: playback.playOrPause,
              child: value.isPlaying
                  ? const SizedBox.expand()
                  : const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        size: 56,
                        color: Colors.white,
                      ),
                    ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Slider(
                value: total > Duration.zero
                    ? (value.position.inMilliseconds / total.inMilliseconds)
                          .clamp(0, 1)
                          .toDouble()
                    : 0,
                onChanged: total > Duration.zero
                    ? (v) => playback.seek(total * v)
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }
}
