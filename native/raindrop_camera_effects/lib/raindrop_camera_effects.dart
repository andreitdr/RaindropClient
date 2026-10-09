/// Attaching Raindrop's camera effects to a camera track `flutter_webrtc` is
/// already capturing.
///
/// The effects themselves are native — see this package's README for why, and
/// for the public `flutter_webrtc` API this reaches through. Nothing here
/// touches a pixel: [RaindropCameraEffects.attach] hands the platform a
/// function address and an opaque context, both integers that came from Rust,
/// and the platform's capture pipeline does the rest on its own thread.
library;

import 'package:flutter/services.dart';

/// Thrown when a track cannot be given a processor. Never fatal: a camera
/// without effects is still a camera.
class CameraEffectsUnavailable implements Exception {
  const CameraEffectsUnavailable(this.reason);

  final String reason;

  @override
  String toString() => 'Camera effects could not be attached: $reason';
}

class RaindropCameraEffects {
  static const _channel = MethodChannel('raindrop/camera_effects');

  /// Whether this platform can attach a processor at all.
  ///
  /// Asked of the platform rather than inferred from the OS, so a platform
  /// gaining support is one native change and no Dart change.
  static Future<bool> get isSupported async {
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } on MissingPluginException {
      // No plugin registered for this platform at all, which is the same
      // answer as no: Windows and Linux have no processing chain to join.
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Puts [processAddress] in the capture pipeline of the track with
  /// [trackId], called per frame with [context] as its first argument.
  ///
  /// [trackId] is `MediaStreamTrack.id` — the same id `flutter_webrtc` keyed
  /// the track under natively, which is what makes the lookup possible without
  /// passing any object across.
  static Future<void> attach({
    required String trackId,
    required int processAddress,
    required int context,
  }) async {
    try {
      await _channel.invokeMethod<void>('attach', {
        'trackId': trackId,
        'processAddress': processAddress,
        'context': context,
      });
    } on PlatformException catch (e) {
      throw CameraEffectsUnavailable(e.message ?? e.code);
    } on MissingPluginException {
      throw const CameraEffectsUnavailable('not supported on this platform');
    }
  }

  /// Takes the processor off the track. Safe to call for a track that has
  /// none, or one that has already gone.
  static Future<void> detach({required String trackId}) async {
    try {
      await _channel.invokeMethod<void>('detach', {'trackId': trackId});
    } on PlatformException {
      // The track is already gone, which is the outcome asked for.
    } on MissingPluginException {
      // Nothing was ever attached here.
    }
  }
}
