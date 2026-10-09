/// The media half of a voice call — microphone and camera — behind one
/// interface so the rest of the app never names the media library. The server
/// says which transport to use when a call is joined
/// (`VoiceJoinResult.transport`); [createVoiceEngine] turns that name into an
/// engine, or null for a transport this build cannot speak.
library;

import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../video/camera_effects.dart';
import '../video/camera_effects_engine.dart';
import 'livekit_voice_engine.dart';

export '../video/camera_effects.dart';

/// Where the media connection is.
enum VoiceConnectionState { connecting, connected, reconnecting, disconnected }

/// Why a call ended from the media side. Only [networkFailure] and [unknown]
/// are worth rejoining automatically after; the others mean somebody decided
/// the call is over for this device, and rejoining would fight them.
enum VoiceDisconnectReason {
  /// This client hung up.
  clientInitiated,

  /// The same account joined the same call from another device.
  replacedByOtherDevice,

  /// The server removed this participant.
  removedByServer,

  /// The call itself was closed.
  callEnded,

  /// The connection could not be kept up.
  networkFailure,

  unknown,
}

/// Echo cancellation, noise suppression and automatic gain — applied to the
/// microphone before it is sent.
class VoiceAudioProcessing {
  const VoiceAudioProcessing({
    this.echoCancellation = true,
    this.noiseSuppression = true,
    this.autoGainControl = true,
  });

  final bool echoCancellation;
  final bool noiseSuppression;
  final bool autoGainControl;

  @override
  bool operator ==(Object other) =>
      other is VoiceAudioProcessing &&
      other.echoCancellation == echoCancellation &&
      other.noiseSuppression == noiseSuppression &&
      other.autoGainControl == autoGainControl;

  @override
  int get hashCode =>
      Object.hash(echoCancellation, noiseSuppression, autoGainControl);
}

/// The key a call's media is end-to-end encrypted with, and its slot in the
/// key ring. It comes from the voice channel's MLS group (see
/// `ChannelGroups.mediaKey`) and changes with the group's epoch.
class VoiceMediaKey {
  const VoiceMediaKey({required this.key, required this.index});

  final Uint8List key;
  final int index;
}

/// Whether a call's media is end-to-end encrypted.
enum VoiceEncryption {
  /// Not encrypted beyond DTLS-SRTP to the media server, which can hear it.
  /// Only on a server that does not offer end-to-end encrypted calls.
  none,

  /// Frames are encrypted with the group's key before they leave this
  /// device, and decrypted only here.
  active,

  /// Encrypted, but something is failing: a participant's frames do not
  /// decrypt (a key change still in flight, or somebody not using the group's
  /// key), or one arrived unencrypted and is being kept silent. Nothing
  /// unencrypted is ever played or sent.
  degraded,
}

/// An audio device the user can pick in settings.
class AudioDevice {
  const AudioDevice({required this.id, required this.label});

  final String id;
  final String label;
}

/// A camera the user can pick.
class VideoDevice {
  const VideoDevice({
    required this.id,
    required this.label,
    this.isFront = false,
  });

  final String id;
  final String label;

  /// A front-facing camera, which is shown mirrored to its owner — people
  /// expect to see themselves the way a mirror shows them, and only they do.
  final bool isFront;
}

/// How much of the camera to send.
///
/// Three steps rather than a free resolution, because what this really sets is
/// how much of everybody else's bandwidth one camera takes, and three is as
/// many as anybody wants to reason about.
enum VoiceVideoQuality {
  sd360,
  sd540,
  hd720;

  String get label => switch (this) {
    VoiceVideoQuality.sd360 => '360p',
    VoiceVideoQuality.sd540 => '540p',
    VoiceVideoQuality.hd720 => '720p',
  };
}

/// How the camera is opened, and what is done to its frames before they leave
/// this device. Chosen before the camera goes on, and remembered.
class VoiceCameraOptions {
  const VoiceCameraOptions({
    this.deviceId,
    this.effect = const VoiceCameraEffect(),
    this.quality = VoiceVideoQuality.sd540,
  });

  /// Null for whichever camera the system offers first.
  final String? deviceId;
  final VoiceCameraEffect effect;
  final VoiceVideoQuality quality;

  /// Whether changing to [next] can be done under a running track, or needs
  /// the camera reopened — which other participants see as a brief freeze.
  ///
  /// Swapping the effect is free: it is a processor on the frames, not a
  /// property of the capture. Changing the camera or the quality is not.
  bool needsRestartFor(VoiceCameraOptions next) =>
      deviceId != next.deviceId || quality != next.quality;

  VoiceCameraOptions copyWith({
    String? Function()? deviceId,
    VoiceCameraEffect? effect,
    VoiceVideoQuality? quality,
  }) => VoiceCameraOptions(
    deviceId: deviceId == null ? this.deviceId : deviceId(),
    effect: effect ?? this.effect,
    quality: quality ?? this.quality,
  );

  @override
  bool operator ==(Object other) =>
      other is VoiceCameraOptions &&
      other.deviceId == deviceId &&
      other.effect == effect &&
      other.quality == quality;

  @override
  int get hashCode => Object.hash(deviceId, effect, quality);
}

/// What the server currently lets this participant send.
///
/// Two independent answers, because a call token now names two sources. A
/// single "may publish" bool cannot tell a server mute from a camera that is
/// not allowed, and the two have entirely different consequences.
class VoicePublishRights {
  const VoicePublishRights({required this.microphone, required this.camera});

  static const none = VoicePublishRights(microphone: false, camera: false);

  final bool microphone;
  final bool camera;

  @override
  bool operator ==(Object other) =>
      other is VoicePublishRights &&
      other.microphone == microphone &&
      other.camera == camera;

  @override
  int get hashCode => Object.hash(microphone, camera);
}

/// One live camera in a call, or in the pre-join preview.
///
/// The engine builds its own surface, which is what keeps the media library
/// inside `livekit_voice_engine.dart`: a feed *is* the renderer, so no widget
/// outside `core/voice/` ever names a track type. [VoiceVideoView] draws one.
abstract class VoiceVideoFeed {
  /// Whose camera this is — their member UUID, as in the roster.
  String get identity;

  /// This device's own camera.
  bool get isLocal;

  /// Whether to mirror it. True for your own front camera and nobody else's:
  /// a mirror is how people expect to see themselves, and how nobody expects
  /// to see anyone else.
  bool get mirror;

  /// Whether this track should be producing frames. False for a camera that
  /// has been muted at the source, which is how a tile knows to show a
  /// placeholder rather than an empty box.
  ///
  /// Not an aspect ratio: the media library settles no dimensions before the
  /// first frame, so a tile picks its own shape and fits the picture into it.
  bool get live;

  Widget buildSurface(BuildContext context, {BoxFit fit = BoxFit.cover});
}

/// A camera running outside a call: what the camera-and-effects sheet shows
/// while a camera and an effect are being chosen. Nothing is published, and
/// nothing about the call is touched — a preview can be opened without being
/// in one at all.
abstract class VoiceCameraPreview {
  VoiceVideoFeed get feed;

  /// Applies a changed choice. Reopens the camera only when
  /// [VoiceCameraOptions.needsRestartFor] says it must.
  Future<void> apply(VoiceCameraOptions options);

  /// Why the chosen effect is not running, or null when it is. Set by the last
  /// [apply]: an effect that cannot be applied is not an error to throw, it is
  /// something the sheet says while still showing the camera.
  String? get warning;

  /// What the effects are costing, or null when none are running.
  ///
  /// The sheet polls this before it shows the preview: until the first mask has
  /// been produced the frames pass through untouched, and an unblurred preview
  /// reads as the effect having failed rather than as not having started.
  Future<CameraEffectsLoad?> load();

  Future<void> dispose();
}

/// One call's audio. Created per call and disposed when it ends.
///
/// Participants are named by their identity in the call, which is their
/// member UUID on the server.
abstract class VoiceEngine {
  /// Connects and — when [micEnabled] — starts sending the microphone.
  ///
  /// With a [mediaKey], the call is end-to-end encrypted and fails closed:
  /// every frame sent is encrypted with the key, and a participant whose
  /// audio arrives unencrypted is kept silent.
  Future<void> connect(
    Uri url,
    String token, {
    required bool micEnabled,
    required VoiceAudioProcessing processing,
    String? inputDeviceId,
    String? outputDeviceId,
    VoiceMediaKey? mediaKey,
  });

  /// Switches to a new media key — after the voice channel's group moved to
  /// a new epoch. The previous keys stay in the ring for frames still in
  /// flight.
  Future<void> setMediaKey(VoiceMediaKey key);

  /// Whether the call is end-to-end encrypted, as it changes.
  Stream<VoiceEncryption> get encryptionChanges;

  Future<void> disconnect();

  /// Starts or stops sending the microphone. A no-op, not an error, while the
  /// server does not let this participant speak.
  Future<void> setMicEnabled(bool enabled);

  /// How loud [identity] plays here: 0 silent, 1 as sent, above 1 boosted up
  /// to [maximumVolume]. Remembered, so it applies to audio that arrives
  /// later too.
  Future<void> setParticipantVolume(String identity, double volume);

  /// The volume for anybody [setParticipantVolume] has not been told about —
  /// somebody whose audio arrives before the roster names them.
  Future<void> setDefaultVolume(double volume);

  Future<void> setInputDevice(String deviceId);

  Future<void> setOutputDevice(String deviceId);

  /// Re-opens the microphone with different processing.
  Future<void> applyProcessing(VoiceAudioProcessing processing);

  Stream<VoiceConnectionState> get connectionStates;

  /// Who is talking right now, this participant included.
  Stream<Set<String>> get activeSpeakers;

  /// Fires once when the call ends from the media side.
  Stream<VoiceDisconnectReason> get disconnects;

  /// What the server currently lets this participant send, as it changes —
  /// after a mute for everyone, a permission change, or the camera grant
  /// arriving. Fires only when one of the two answers actually differs.
  Stream<VoicePublishRights> get publishRights;

  /// What it is right now. The camera handshake has to know before it waits:
  /// a grant that is already in place must not be waited for.
  VoicePublishRights get currentPublishRights;

  /// Opens the camera and starts sending it, or stops and closes it.
  ///
  /// Returns false, without throwing, when the server does not currently let
  /// this participant publish a camera — the caller asked the server for the
  /// grant and it has not arrived. The camera is never opened in that case, so
  /// no light comes on for a camera nobody will see.
  Future<bool> setCameraEnabled(bool enabled, {VoiceCameraOptions? options});

  /// Changes the camera or the effect while it is already being sent. Swapping
  /// the effect is free; changing the camera or the quality reopens the track,
  /// which other participants see as a brief freeze.
  Future<void> applyCameraOptions(VoiceCameraOptions options);

  /// Whether this client is sending its camera, as it changes — including when
  /// the engine turned it off itself, for a track it could not encrypt.
  Stream<bool> get cameraStates;

  /// Every camera in the call, this client's own first. The whole list is
  /// replaced on every change, like [activeSpeakers], so a listener never has
  /// to merge.
  Stream<List<VoiceVideoFeed>> get videoFeeds;

  /// Participants whose camera arrived in a state this client will not render:
  /// unencrypted, or not decrypting. Their tile says so instead of showing
  /// video. Nothing untrusted is ever drawn.
  Stream<Set<String>> get untrustedVideo;

  /// Stops receiving one participant's camera, or starts again.
  ///
  /// Local only: the sender is never told and keeps sending to everybody else.
  /// It really stops the stream rather than hiding it, so hiding a camera
  /// saves the bandwidth as well as the screen space.
  Future<void> setVideoVisible(String identity, bool visible);

  /// Something the engine refused for safety, in words for the user — media it
  /// could not encrypt, an effect it had to turn off. Never fatal: the call
  /// goes on without whatever was refused.
  Stream<String> get warnings;

  Future<void> dispose();
}

/// The loudest a participant can be turned up here, as a multiple of how
/// they were sent. The WebRTC source gain this maps onto accepts up to 10,
/// but past 2 speech clips audibly.
const double maximumVolume = 2.0;

/// How loud a participant's audio plays once trust is taken into account:
/// silence for anything this device will not vouch for, and nothing else
/// touched. Pulled out of the engine so the rule can be tested without a
/// media library.
///
/// [unencrypted] is per participant and lasts the whole call — a client that
/// sent one frame in the clear does not get a second chance. [undecryptable]
/// is per publication and transient, usually a key change the other side has
/// not made yet.
double gatedVolume({
  required double volume,
  required bool unencrypted,
  required bool undecryptable,
}) => unencrypted || undecryptable ? 0 : volume;

/// Video codecs a call will not carry.
///
/// AV1 is refused because `livekit_client` silently skips frame-cryptor setup
/// for it (`e2ee_manager.dart` in 2.13.0, the `isAV1Codec` early returns in
/// both the publish and the subscribe handler) while the publication still
/// reports itself as encrypted. An AV1 track would therefore travel in the
/// clear with nothing to notice it. Re-read those two early returns on every
/// `livekit_client` bump before removing anything from here.
const Set<String> blockedVideoCodecs = {'av1'};

/// Whether a codec name — from `publication.track?.codec` when sending, or the
/// subtype of `publication.mimeType` when receiving — is one a call refuses.
/// Tolerates the case and the `video/` prefix either side may use.
bool isBlockedVideoCodec(String codec) {
  final name = codec.toLowerCase().split('/').last.trim();
  return blockedVideoCodecs.contains(name);
}

/// The engine for a transport the server named, or null when this build does
/// not speak it.
VoiceEngine? createVoiceEngine(String transport) => switch (transport) {
  LiveKitVoiceEngine.transportName => LiveKitVoiceEngine(),
  _ => null,
};

/// The audio devices this machine has, for the settings screen.
Future<List<AudioDevice>> audioInputDevices() => LiveKitVoiceEngine.inputs();

Future<List<AudioDevice>> audioOutputDevices() => LiveKitVoiceEngine.outputs();

/// The cameras this machine has.
Future<List<VideoDevice>> videoInputDevices() => LiveKitVoiceEngine.cameras();

/// Opens a camera outside a call, for the camera-and-effects sheet.
///
/// Deliberately not a method on [VoiceEngine]: the sheet is reachable from
/// settings with no call in progress, and a preview must not need one.
Future<VoiceCameraPreview> openCameraPreview(VoiceCameraOptions options) =>
    LiveKitVoiceEngine.preview(options);
