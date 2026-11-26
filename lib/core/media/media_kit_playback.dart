import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'media_playback.dart';

/// [MediaPlayback] through media_kit (libmpv): every platform but Windows.
class MediaKitPlayback implements MediaPlayback {
  MediaKitPlayback._(this._player, this._controller);

  final Player _player;
  final VideoController? _controller;

  static void initialize() => MediaKit.ensureInitialized();

  static Future<MediaKitPlayback> open(
    String path, {
    required bool video,
  }) async {
    final player = Player();
    // The video output has to exist before the file is opened.
    final controller = video ? VideoController(player) : null;
    await player.open(Media(Uri.file(path).toString()));
    return MediaKitPlayback._(player, controller);
  }

  static Future<VideoStill?> grabStill(String path) async {
    final player = Player();
    try {
      final controller = VideoController(player);
      await player.open(Media(Uri.file(path).toString()), play: false);
      await controller.waitUntilFirstFrameRendered.timeout(
        const Duration(seconds: 5),
      );
      final duration = player.state.duration;
      if (duration > const Duration(seconds: 4)) {
        await player.seek(const Duration(seconds: 2));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
      final frame = await player.screenshot(format: 'image/jpeg');
      if (frame == null) return null;
      return VideoStill(
        frame,
        width: player.state.width,
        height: player.state.height,
        duration: duration > Duration.zero ? duration : null,
      );
    } finally {
      await player.dispose();
    }
  }

  @override
  Stream<bool> get playing =>
      startingWith(_player.state.playing, _player.stream.playing);

  @override
  Stream<Duration> get position =>
      startingWith(_player.state.position, _player.stream.position);

  @override
  Stream<Duration> get duration =>
      startingWith(_player.state.duration, _player.stream.duration);

  @override
  Future<void> playOrPause() => _player.playOrPause();

  @override
  Future<void> seek(Duration to) => _player.seek(to);

  @override
  Widget view() => switch (_controller) {
    final controller? => Video(controller: controller),
    null => const SizedBox.shrink(),
  };

  @override
  Future<void> dispose() => _player.dispose();
}
