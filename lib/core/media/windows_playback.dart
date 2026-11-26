import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player_win/video_player_win.dart';

import 'media_playback.dart';

/// [MediaPlayback] through Windows' Media Foundation (video_player_win), for
/// x64 and ARM64 alike.
class WindowsPlayback implements MediaPlayback {
  WindowsPlayback._(this._controller) {
    _controller.addListener(_changed);
  }

  final WinVideoPlayerController _controller;
  final _values = StreamController<WinVideoPlayerValue>.broadcast();

  static Future<WindowsPlayback> open(String path) async {
    final controller = WinVideoPlayerController.file(File(path));
    await controller.initialize();
    if (!controller.value.isInitialized) {
      final reason = controller.value.errorDescription;
      await controller.dispose();
      throw StateError('Windows could not open the file ($reason)');
    }
    final playback = WindowsPlayback._(controller);
    await controller.play();
    return playback;
  }

  void _changed() => _values.add(_controller.value);

  Stream<T> _watch<T>(T Function(WinVideoPlayerValue value) pick) =>
      startingWith(
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
  Widget view() => _WindowsVideoView(this);

  @override
  Future<void> dispose() async {
    _controller.removeListener(_changed);
    await _values.close();
    await _controller.dispose();
  }
}

/// The picture at its own aspect ratio, with what media_kit's own controls
/// give on the other platforms: a tap to play or pause, and a seek bar.
class _WindowsVideoView extends StatelessWidget {
  const _WindowsVideoView(this.playback);

  final WindowsPlayback playback;

  @override
  Widget build(BuildContext context) {
    final controller = playback._controller;
    return ValueListenableBuilder<WinVideoPlayerValue>(
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
                  child: WinVideoPlayer(controller),
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
