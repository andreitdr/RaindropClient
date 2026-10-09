import '../crypto/bridge/api/video.dart' as rust;
import '../platform/platform_info.dart';
import 'camera_effects.dart';

/// Whether camera effects can run here at all: the platform has somewhere to
/// put the processor, and this build carries a segmentation model.
///
/// What every screen asks — the platform half alone would offer an effect that
/// a build without the model cannot produce, and blurring the wrong shape is
/// worse than offering nothing.
///
/// Cached, because neither half can change while the app runs, and false when
/// the Rust library is not loaded: that is a widget test, which has no camera
/// to apply an effect to either.
bool get cameraEffectsAvailable => _available ??= _ask();

bool? _available;

bool _ask() {
  if (!canUseCameraEffects) return false;
  try {
    return CameraEffects.support().available;
  } on Object {
    return false;
  }
}

/// Whether this build can run camera effects, and what with.
class CameraEffectsSupport {
  const CameraEffectsSupport({required this.available, required this.backend});

  static const none = CameraEffectsSupport(available: false, backend: 'none');

  /// False when the build carries no segmentation model. Asked of the native
  /// side rather than guessed from the platform: a build without the model
  /// would blur the wrong shape, which is worse than not offering the effect.
  final bool available;

  /// Which inference backend is in this build, for the About screen and for
  /// bug reports.
  final String backend;
}

/// Something the native effects refused. Never fatal: a camera without an
/// effect is still a camera, and the caller's job is to say so once.
class CameraEffectsFailure implements Exception {
  const CameraEffectsFailure(this.message);

  final String message;

  @override
  String toString() => 'Camera effects: $message';
}

/// The native camera effects, running.
///
/// The only file outside `core/crypto/` that imports the generated bridge: the
/// effects ride in the same Rust library as the encryption core, because
/// cargokit already builds that one for all five targets. They share nothing
/// else — `raindrop_video` holds no key material.
///
/// **No frame comes through here.** What crosses the bridge is a handle and the
/// address of a C function; the platform's capture pipeline calls that function
/// per frame on its own thread, with the handle as its context. That is the
/// whole reason this class looks like a remote control rather than a filter.
/// See `../../../RaindropCrypto/docs/video-effects.md`.
class CameraEffects {
  CameraEffects._(this._handle, this._applied);

  /// The handle, as the platform wants it: an integer to hand back untouched.
  final BigInt _handle;

  VoiceCameraEffect _applied;

  bool _disposed = false;

  /// What the native side can do. Cheap and synchronous — it only reads what
  /// was compiled in — but it needs the Rust library loaded, so not before
  /// `CryptoStores.initialize()`.
  static CameraEffectsSupport support() {
    final capabilities = rust.videoEffectsCapabilities();
    return CameraEffectsSupport(
      available: capabilities.available,
      backend: capabilities.backend,
    );
  }

  /// Opens effects for one camera, with [effect] already applied, or returns
  /// null when [effect] amounts to nothing. Throws [CameraEffectsFailure] when
  /// the native side refuses.
  static Future<CameraEffects?> start(VoiceCameraEffect effect) async {
    if (effect.effective(effectsAvailable: true) ==
        VoiceCameraEffectKind.none) {
      return null;
    }

    // Created with the effect it is wanted for, not with none and then
    // changed: the first frames would otherwise go out unprocessed, which
    // reads as the effect having failed.
    final handle = await _guard(
      () => rust.videoEffectsCreate(config: _configOf(effect)),
    );

    final effects = CameraEffects._(handle, effect);

    if (effect.backgroundPath case final path?) {
      try {
        await _guard(
          () => rust.videoEffectsSetBackgroundFile(handle: handle, path: path),
        );
      } on CameraEffectsFailure {
        await effects.dispose();
        rethrow;
      }
    }

    return effects;
  }

  /// The address of the per-frame processor, and the context to call it with.
  ///
  /// Both are plain integers on purpose: they travel through a method channel
  /// into native code that knows nothing about Rust or Dart. A `usize` and a
  /// `u64` arrive as [BigInt]; every platform wants them as a 64-bit integer.
  int get processAddress => rust.videoEffectsProcessAddress().toInt();

  int get context => _handle.toInt();

  /// What is currently applied.
  VoiceCameraEffect get applied => _applied;

  /// Changes the effect under the running camera. Free: this is a processor on
  /// the frames, not a property of the capture, so nothing restarts and nobody
  /// sees a freeze.
  Future<void> apply(VoiceCameraEffect effect) async {
    if (_disposed || effect == _applied) return;

    // The picture first, then the kind: switching to a replaced background
    // before its picture is in place would composite a frame or two against
    // the last one.
    if (effect.backgroundPath case final path?
        when path != _applied.backgroundPath) {
      await _guard(
        () => rust.videoEffectsSetBackgroundFile(handle: _handle, path: path),
      );
    }

    await _guard(
      () => rust.videoEffectsUpdate(handle: _handle, config: _configOf(effect)),
    );
    _applied = effect;
  }

  /// What the effects are costing. Read to tell the user once that something
  /// has been given up — the ladder that gives it up lives in Rust, not here.
  Future<CameraEffectsLoad> load() async {
    final stats = await _guard(() => rust.videoEffectsStats(handle: _handle));
    return CameraEffectsLoad(
      frames: stats.frames.toInt(),
      masks: stats.masks.toInt(),
      degraded: stats.degraded,
    );
  }

  /// Releases the effects and the segmentation worker's thread.
  ///
  /// The capture pipeline must have been detached first. A frame that arrives
  /// after this is passed through untouched rather than crashing, but it is a
  /// frame that was not processed.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await rust.videoEffectsDestroy(handle: _handle);
  }

  static rust.VideoEffectsConfig _configOf(VoiceCameraEffect effect) =>
      rust.VideoEffectsConfig(
        // The index is the contract with `config_of` in the Rust bridge:
        // none, blur, replace, in that order.
        kind: effect.effective(effectsAvailable: true).index,
        blurStrength: effect.strength,
        // Left at the Rust default. The rate segmentation runs at is a
        // performance decision, and the degradation ladder owns it.
        maskHz: 15,
      );

  /// Turns the bridge's failure into one of ours, so nothing outside this file
  /// handles a generated type.
  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on rust.VideoFailure catch (failure) {
      throw CameraEffectsFailure(failure.message);
    }
  }
}

/// What the effects have cost so far.
class CameraEffectsLoad {
  const CameraEffectsLoad({
    required this.frames,
    required this.masks,
    required this.degraded,
  });

  final int frames;
  final int masks;

  /// True once anything has been given up to keep up with the frame rate.
  final bool degraded;

  /// Whether a mask has been produced at all. Until one has, frames pass
  /// through unprocessed, which looks exactly like the effect failing — so a
  /// preview waits for this before it is shown.
  bool get warm => masks > 0;
}
