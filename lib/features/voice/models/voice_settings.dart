import '../../../core/voice/voice_engine.dart';

/// This client's own voice preferences — the "Voice & video" settings, plus
/// whether it is muted or deafened, which carries over from one call to the
/// next the way a headset's mute switch would.
///
/// The camera's settings are here too, but the camera itself is not: mute and
/// deafen are remembered *states*, and a camera is not. You cannot pre-arm a
/// camera for the next call, so what is kept is only which camera and which
/// effect to use when one is turned on.
class VoiceSettings {
  const VoiceSettings({
    this.outputVolume = 1.0,
    this.inputDeviceId,
    this.outputDeviceId,
    this.echoCancellation = true,
    this.noiseSuppression = true,
    this.autoGainControl = true,
    this.selfMute = false,
    this.selfDeaf = false,
    this.mutedBeforeDeafen = false,
    this.videoDeviceId,
    this.videoQuality = VoiceVideoQuality.sd540,
    this.cameraEffect = const VoiceCameraEffect(),
    this.speakerphone = true,
  });

  /// Everybody's volume here, multiplied into each member's own: 1 as sent.
  final double outputVolume;

  /// The microphone to use, or null for the system default.
  final String? inputDeviceId;

  /// The speakers or headset to use, or null for the system default.
  final String? outputDeviceId;

  final bool echoCancellation;
  final bool noiseSuppression;
  final bool autoGainControl;

  /// The microphone is off.
  final bool selfMute;

  /// Nobody is heard, and the microphone is off with it.
  final bool selfDeaf;

  /// Whether the microphone was already off when deafening, so undeafening
  /// puts it back how it was rather than always switching it on.
  final bool mutedBeforeDeafen;

  /// The camera to use, or null for whichever the system offers first.
  final String? videoDeviceId;

  final VoiceVideoQuality videoQuality;

  /// What to do to the camera's background. Remembered so turning the camera
  /// on is one tap after the first time.
  final VoiceCameraEffect cameraEffect;
  /// Phones only: play the call out of the loudspeaker rather than the
  /// earpiece. It is the sensible default for a chat app — a call joined from
  /// a channel list is one you are listening to, not one held to your ear —
  /// and the toggle in the call controls is how you put it back. Desktop has
  /// no earpiece to choose between, and ignores this; see
  /// `canUseSpeakerphone`.
  final bool speakerphone;

  /// Whether the microphone should be sending.
  bool get micOn => !selfMute && !selfDeaf;

  /// The remembered camera choice, as the engine takes it.
  VoiceCameraOptions get camera => VoiceCameraOptions(
    deviceId: videoDeviceId,
    quality: videoQuality,
    effect: cameraEffect,
  );

  VoiceAudioProcessing get processing => VoiceAudioProcessing(
    echoCancellation: echoCancellation,
    noiseSuppression: noiseSuppression,
    autoGainControl: autoGainControl,
  );

  VoiceSettings copyWith({
    double? outputVolume,
    String? Function()? inputDeviceId,
    String? Function()? outputDeviceId,
    bool? echoCancellation,
    bool? noiseSuppression,
    bool? autoGainControl,
    bool? selfMute,
    bool? selfDeaf,
    bool? mutedBeforeDeafen,
    String? Function()? videoDeviceId,
    VoiceVideoQuality? videoQuality,
    VoiceCameraEffect? cameraEffect,
    bool? speakerphone,
  }) => VoiceSettings(
    outputVolume: outputVolume ?? this.outputVolume,
    inputDeviceId: inputDeviceId != null ? inputDeviceId() : this.inputDeviceId,
    outputDeviceId: outputDeviceId != null
        ? outputDeviceId()
        : this.outputDeviceId,
    echoCancellation: echoCancellation ?? this.echoCancellation,
    noiseSuppression: noiseSuppression ?? this.noiseSuppression,
    autoGainControl: autoGainControl ?? this.autoGainControl,
    selfMute: selfMute ?? this.selfMute,
    selfDeaf: selfDeaf ?? this.selfDeaf,
    mutedBeforeDeafen: mutedBeforeDeafen ?? this.mutedBeforeDeafen,
    videoDeviceId: videoDeviceId != null ? videoDeviceId() : this.videoDeviceId,
    videoQuality: videoQuality ?? this.videoQuality,
    cameraEffect: cameraEffect ?? this.cameraEffect,
    speakerphone: speakerphone ?? this.speakerphone,
  );

  /// The whole camera choice at once, which is what the sheet returns.
  VoiceSettings withCamera(VoiceCameraOptions camera) => copyWith(
    videoDeviceId: () => camera.deviceId,
    videoQuality: camera.quality,
    cameraEffect: camera.effect,
  );

  Map<String, dynamic> toJson() => {
    'outputVolume': outputVolume,
    'inputDeviceId': inputDeviceId,
    'outputDeviceId': outputDeviceId,
    'echoCancellation': echoCancellation,
    'noiseSuppression': noiseSuppression,
    'autoGainControl': autoGainControl,
    'selfMute': selfMute,
    'selfDeaf': selfDeaf,
    'mutedBeforeDeafen': mutedBeforeDeafen,
    'videoDeviceId': videoDeviceId,
    'videoQuality': videoQuality.name,
    'cameraEffect': cameraEffect.toJson(),
    'speakerphone': speakerphone,
  };

  /// Reads what [toJson] wrote, falling back to the defaults for anything
  /// missing or malformed — a settings file from an older build included.
  factory VoiceSettings.fromJson(Map<String, dynamic> j) {
    const defaults = VoiceSettings();
    double volume(Object? v) => v is num
        ? v.toDouble().clamp(0.0, maximumVolume).toDouble()
        : defaults.outputVolume;
    bool flag(Object? v, bool fallback) => v is bool ? v : fallback;

    // By name, never by index: an index would silently mean a different
    // quality the moment a value is inserted into the enum.
    final quality = VoiceVideoQuality.values
        .where((value) => value.name == j['videoQuality'])
        .firstOrNull;

    final effect = j['cameraEffect'];

    return VoiceSettings(
      outputVolume: volume(j['outputVolume']),
      inputDeviceId: j['inputDeviceId'] as String?,
      outputDeviceId: j['outputDeviceId'] as String?,
      echoCancellation: flag(j['echoCancellation'], defaults.echoCancellation),
      noiseSuppression: flag(j['noiseSuppression'], defaults.noiseSuppression),
      autoGainControl: flag(j['autoGainControl'], defaults.autoGainControl),
      selfMute: flag(j['selfMute'], false),
      selfDeaf: flag(j['selfDeaf'], false),
      mutedBeforeDeafen: flag(j['mutedBeforeDeafen'], false),
      videoDeviceId: j['videoDeviceId'] as String?,
      videoQuality: quality ?? defaults.videoQuality,
      cameraEffect: effect is Map
          ? VoiceCameraEffect.fromJson(Map<String, dynamic>.from(effect))
          : defaults.cameraEffect,
      speakerphone: flag(j['speakerphone'], defaults.speakerphone),
    );
  }
}
