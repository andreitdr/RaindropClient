import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../platform/platform_info.dart';
import 'media_kit_playback.dart';
import 'system_playback.dart';

/// Plays one local media file (a decrypted video or audio attachment) through
/// the player this platform builds with: the system's own on iOS, macOS and
/// Windows, media_kit on Android and Linux (see
/// [playsMediaThroughSystemPlayer]).
/// Nothing outside `core/media/` imports either player.
abstract class MediaPlayback {
  /// Opens [path] and starts playing it. With [video], [view] draws its
  /// picture; an audio file needs no view.
  static Future<MediaPlayback> open(String path, {bool video = false}) =>
      playsMediaThroughSystemPlayer
      ? SystemPlayback.open(path)
      : MediaKitPlayback.open(path, video: video);

  /// Each of these starts with the current value, then follows changes, so a
  /// listener that arrives after [open] misses nothing.
  Stream<bool> get playing;
  Stream<Duration> get position;
  Stream<Duration> get duration;

  Future<void> playOrPause();
  Future<void> seek(Duration to);

  /// The picture, with the player's own controls.
  Widget view();

  Future<void> dispose();
}

/// Starts the media library, once, before anything plays.
void initializeMedia() {
  if (!playsMediaThroughSystemPlayer) MediaKitPlayback.initialize();
}

/// A JPEG still from a video, at the size the player produced it, with what
/// the player learnt about the video on the way (media_kit learns its size
/// and length; the system thumbnailers give only the picture).
class VideoStill {
  const VideoStill(this.jpeg, {this.width, this.height, this.duration});

  final Uint8List jpeg;
  final int? width;
  final int? height;
  final Duration? duration;
}

/// A still from a few seconds into the video at [path], grabbed without
/// showing it anywhere, or null when the video gave none.
Future<VideoStill?> grabVideoStill(String path) => playsMediaThroughSystemPlayer
    ? SystemPlayback.grabStill(path)
    : MediaKitPlayback.grabStill(path);

/// [current], then every value of [later].
Stream<T> startingWith<T>(T current, Stream<T> later) async* {
  yield current;
  yield* later;
}
