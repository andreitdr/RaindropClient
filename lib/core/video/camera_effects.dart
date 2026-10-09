/// What the user chose to do to their camera before it goes on: nothing, blur
/// the background, or replace it.
///
/// A property of the camera rather than of the call, which is why it lives here
/// and not in `core/voice/`: it is picked and remembered in settings, and the
/// same choice applies whichever call it is used in.
///
/// The work itself happens in native code, in Rust — the media library exposes
/// no way to touch a camera frame from Dart, so the frames never come through
/// here. This file is only the choice. See
/// `../../../RaindropCrypto/docs/video-effects.md`.
library;

/// Which effect to apply.
///
/// An enum, not an open string: unlike permissions or leave reasons, this is
/// never extended by a server or a plugin — it is read back from this device's
/// own settings, so an unknown value means a settings file from a newer build
/// and [VoiceCameraEffect.fromJson] reads it as [none].
enum VoiceCameraEffectKind {
  none,
  blur,

  /// A picture behind the person, named by [VoiceCameraEffect.backgroundPath].
  replace,
}

/// The chosen effect, as it is persisted.
class VoiceCameraEffect {
  const VoiceCameraEffect({
    this.kind = VoiceCameraEffectKind.none,
    this.strength = 0.7,
    this.backgroundPath,
  });

  final VoiceCameraEffectKind kind;

  /// How strong the blur is, 0 to 1. Mapped to a radius relative to the
  /// frame's height, so the effect looks the same at every capture resolution.
  final double strength;

  /// The picture a replaced background shows. Null is not a replaced
  /// background with no picture — [kind] reads as [VoiceCameraEffectKind.none]
  /// in that case, because showing somebody their real room when they asked for
  /// a background is worse than not applying the effect.
  final String? backgroundPath;

  /// What is actually applied, as opposed to what was chosen: a replacement
  /// with no picture, or any effect on a platform that cannot run one, is
  /// nothing.
  VoiceCameraEffectKind effective({required bool effectsAvailable}) {
    if (!effectsAvailable) return VoiceCameraEffectKind.none;
    if (kind == VoiceCameraEffectKind.replace && backgroundPath == null) {
      return VoiceCameraEffectKind.none;
    }
    return kind;
  }

  /// How to describe the choice in a settings row.
  String get label => switch (kind) {
    VoiceCameraEffectKind.none => 'No effect',
    VoiceCameraEffectKind.blur => 'Background blurred',
    VoiceCameraEffectKind.replace => 'Background replaced',
  };

  VoiceCameraEffect copyWith({
    VoiceCameraEffectKind? kind,
    double? strength,
    String? Function()? backgroundPath,
  }) => VoiceCameraEffect(
    kind: kind ?? this.kind,
    strength: strength ?? this.strength,
    backgroundPath: backgroundPath == null
        ? this.backgroundPath
        : backgroundPath(),
  );

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'strength': strength,
    if (backgroundPath != null) 'background': backgroundPath,
  };

  /// Tolerant per field, like every other settings model here: a blob written
  /// by a newer build, or one somebody edited by hand, falls back field by
  /// field rather than throwing the whole lot away.
  factory VoiceCameraEffect.fromJson(Map<String, dynamic> json) {
    final name = json['kind'];
    final kind = VoiceCameraEffectKind.values
        .where((value) => value.name == name)
        .firstOrNull;

    final strength = json['strength'];
    final background = json['background'];

    return VoiceCameraEffect(
      kind: kind ?? VoiceCameraEffectKind.none,
      strength: strength is num
          ? strength.toDouble().clamp(0.0, 1.0).toDouble()
          : 0.7,
      backgroundPath: background is String && background.isNotEmpty
          ? background
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is VoiceCameraEffect &&
      other.kind == kind &&
      other.strength == strength &&
      other.backgroundPath == backgroundPath;

  @override
  int get hashCode => Object.hash(kind, strength, backgroundPath);
}
