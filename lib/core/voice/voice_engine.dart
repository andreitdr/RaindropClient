/// The media half of a voice call — microphone, camera and screen share —
/// behind one interface so the rest of the app never names the media library. The server
/// says which transport to use when a call is joined
/// (`VoiceJoinResult.transport`); [createVoiceEngine] turns that name into an
/// engine, or null for a transport this build cannot speak.
library;

import 'dart:math' as math;
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
/// Independent answers, one per source, because a call token names each
/// source separately. A single "may publish" bool cannot tell a server mute
/// from a camera that is not allowed, and the two have entirely different
/// consequences.
class VoicePublishRights {
  const VoicePublishRights({
    required this.microphone,
    required this.camera,
    this.screen = false,
    this.screenAudio = false,
  });

  static const none = VoicePublishRights(microphone: false, camera: false);

  final bool microphone;
  final bool camera;

  /// The picture of a screen or window being shared.
  final bool screen;

  /// A shared window's own sound. The server only ever grants it with
  /// [screen], for a window, and while this participant may speak.
  final bool screenAudio;

  @override
  bool operator ==(Object other) =>
      other is VoicePublishRights &&
      other.microphone == microphone &&
      other.camera == camera &&
      other.screen == screen &&
      other.screenAudio == screenAudio;

  @override
  int get hashCode => Object.hash(microphone, camera, screen, screenAudio);
}

/// LiveKit's own numbers for the sources a participant may publish, as a
/// permission update carries them — its wire protocol, the same numbers
/// vendored on the server in `livekit_room_service.proto`. Compared by number
/// because the enum the permission carries is the protobuf one, which
/// `livekit_client` does not export.
abstract final class MediaSourceNumbers {
  static const camera = 1;
  static const microphone = 2;
  static const screenShare = 3;
  static const screenShareAudio = 4;
}

/// What a media-server permission lets this participant send, from its
/// `canPublish` and the source numbers in `canPublishSources`.
///
/// An **empty** source list with [canPublish] means every source: that is
/// how LiveKit reads it. Raindrop's own tokens never send one empty, but a
/// token LiveKit refreshed for a connected participant is not ours to assume
/// about. Kept here, free of the media library, so the rule can be tested.
VoicePublishRights voicePublishRightsOf({
  required bool canPublish,
  required Iterable<int> sources,
}) {
  if (!canPublish) return VoicePublishRights.none;

  final allowed = sources.toSet();
  if (allowed.isEmpty) {
    return const VoicePublishRights(
      microphone: true,
      camera: true,
      screen: true,
      screenAudio: true,
    );
  }

  return VoicePublishRights(
    microphone: allowed.contains(MediaSourceNumbers.microphone),
    camera: allowed.contains(MediaSourceNumbers.camera),
    screen: allowed.contains(MediaSourceNumbers.screenShare),
    screenAudio: allowed.contains(MediaSourceNumbers.screenShareAudio),
  );
}

/// What a video feed shows.
enum VoiceVideoKind { camera, screen }

/// What a screen share shows: a whole display, or one window.
enum VoiceScreenSourceKind { screen, window }

/// Something that can be shared — a display or a window — as the share picker
/// lists it.
class VoiceScreenSource {
  const VoiceScreenSource({
    required this.id,
    required this.name,
    required this.kind,
    this.thumbnail,
  });

  /// The platform's own id for it. For a window on Windows this is the HWND,
  /// as a decimal string — which is what lets the picker ask whose window it
  /// is before offering its sound.
  final String id;

  /// A display's name, or a window's title.
  final String name;

  final VoiceScreenSourceKind kind;

  /// A small JPEG of what it currently shows, when the platform made one.
  final Uint8List? thumbnail;

  @override
  bool operator ==(Object other) =>
      other is VoiceScreenSource &&
      other.id == id &&
      other.kind == kind &&
      other.name == name;

  @override
  int get hashCode => Object.hash(id, kind, name);
}

/// A live list of what can be shared, for the share picker. Displays and
/// windows come and go and their thumbnails refresh in place, so the picker
/// listens rather than reading once.
abstract class VoiceScreenSources {
  /// The whole list, replaced on every change.
  Stream<List<VoiceScreenSource>> get sources;

  /// What [sources] last delivered.
  List<VoiceScreenSource> get current;

  /// False when the system refused this app permission to record the screen
  /// (macOS asks once; after that it is System Settings). Nothing is listed
  /// then, and the picker says where to allow it.
  bool get captureAllowed;

  Future<void> dispose();
}

/// The one thing a phone or a tablet can share: everything on its screen.
/// There is nothing to pick between, so there is no list — the system's own
/// consent sheet is the picker. Shared as a whole screen, so never with sound.
const VoiceScreenSource deviceScreenSource = VoiceScreenSource(
  id: 'device',
  name: 'This device',
  kind: VoiceScreenSourceKind.screen,
);

/// The largest picture a share is sent at: the box it is fitted inside.
///
/// Three steps rather than a free size, for the camera's reason: what this
/// really sets is how much everybody watching has to download.
enum VoiceShareResolution {
  p480(854, 480),
  p720(1280, 720),
  p1080(1920, 1080);

  const VoiceShareResolution(this.width, this.height);

  /// The box, as a landscape picture. A portrait source gets it turned.
  final int width;
  final int height;

  String get label => '${height}p';
}

/// How often a share sends a picture, at most.
enum VoiceShareFrameRate {
  f15(15),
  f24(24),
  f30(30),
  f60(60);

  const VoiceShareFrameRate(this.fps);

  final int fps;

  String get label => '$fps fps';
}

/// What a sharer asked their share to be sent at.
///
/// Either **automatic** — the best this device and its connection manage, up
/// to [autoShareResolution] at [autoShareFrameRate] — or a **maximum** the
/// sharer picked. Both are ceilings and never promises: below the ceiling the
/// connection decides, for the sharer and for each viewer separately. See
/// [shareLadder].
class VoiceShareQuality {
  const VoiceShareQuality.auto() : resolution = null, frameRate = null;

  const VoiceShareQuality.fixed(
    VoiceShareResolution this.resolution,
    VoiceShareFrameRate this.frameRate,
  );

  /// Null for automatic.
  final VoiceShareResolution? resolution;
  final VoiceShareFrameRate? frameRate;

  bool get isAuto => resolution == null || frameRate == null;

  String get label =>
      isAuto ? 'Auto' : '${resolution!.label} · ${frameRate!.label}';

  Map<String, dynamic> toJson() => isAuto
      ? const {'auto': true}
      : {'height': resolution!.height, 'fps': frameRate!.fps};

  /// Reads what [toJson] wrote. Anything it does not recognise — a size or a
  /// rate a later build added and this one never had — is automatic, which is
  /// always a safe thing for a share to be.
  factory VoiceShareQuality.fromJson(Object? json) {
    if (json is! Map) return const VoiceShareQuality.auto();
    final resolution = VoiceShareResolution.values
        .where((r) => r.height == json['height'])
        .firstOrNull;
    final frameRate = VoiceShareFrameRate.values
        .where((f) => f.fps == json['fps'])
        .firstOrNull;
    if (resolution == null || frameRate == null) {
      return const VoiceShareQuality.auto();
    }
    return VoiceShareQuality.fixed(resolution, frameRate);
  }

  @override
  bool operator ==(Object other) =>
      other is VoiceShareQuality &&
      other.resolution == resolution &&
      other.frameRate == frameRate;

  @override
  int get hashCode => Object.hash(resolution, frameRate);
}

/// What automatic aims for on a connection that can carry it. Thirty frames
/// rather than sixty: sixty costs half as much again in upload and a great
/// deal of processor for a share that is, most of the time, a document — so
/// it is something a sharer asks for, not something they are given.
const VoiceShareResolution autoShareResolution = VoiceShareResolution.p1080;
const VoiceShareFrameRate autoShareFrameRate = VoiceShareFrameRate.f30;

/// A ceiling on every share, whatever its sharer picked: the server owner's
/// (`VoiceStatus.shareLimit`), this device's (an iPhone cannot send sixty
/// frames), or both ([and]).
///
/// The server's is **honoured, not enforced**: the media is end-to-end
/// encrypted and the server never sees a frame, so there is nothing for it to
/// measure. It is the same kind of promise as the 1080p box always was.
class VoiceShareLimit {
  const VoiceShareLimit({
    this.resolution = VoiceShareResolution.p1080,
    this.frameRate = VoiceShareFrameRate.f60,
  });

  /// No ceiling beyond the largest thing a share can be.
  static const none = VoiceShareLimit();

  /// From numbers — the server's, off the wire, or a platform's. Zero (or
  /// anything below) means nothing was stated. A number between two steps
  /// allows the step below it, and one under the smallest step still allows
  /// the smallest: a limit can make a share small, never impossible.
  factory VoiceShareLimit.of({int height = 0, int frameRate = 0}) {
    final resolution = height <= 0
        ? VoiceShareResolution.p1080
        : VoiceShareResolution.values.lastWhere(
            (r) => r.height <= height,
            orElse: () => VoiceShareResolution.values.first,
          );
    final rate = frameRate <= 0
        ? VoiceShareFrameRate.f60
        : VoiceShareFrameRate.values.lastWhere(
            (f) => f.fps <= frameRate,
            orElse: () => VoiceShareFrameRate.values.first,
          );
    return VoiceShareLimit(resolution: resolution, frameRate: rate);
  }

  final VoiceShareResolution resolution;
  final VoiceShareFrameRate frameRate;

  /// Both limits at once: the smaller of each.
  VoiceShareLimit and(VoiceShareLimit other) => VoiceShareLimit(
    resolution: resolution.index <= other.resolution.index
        ? resolution
        : other.resolution,
    frameRate: frameRate.index <= other.frameRate.index
        ? frameRate
        : other.frameRate,
  );

  bool allowsResolution(VoiceShareResolution wanted) =>
      wanted.index <= resolution.index;

  bool allowsFrameRate(VoiceShareFrameRate wanted) =>
      wanted.index <= frameRate.index;

  @override
  bool operator ==(Object other) =>
      other is VoiceShareLimit &&
      other.resolution == resolution &&
      other.frameRate == frameRate;

  @override
  int get hashCode => Object.hash(resolution, frameRate);
}

/// A [VoiceShareQuality] with its ceilings applied: the top of what will
/// actually be sent.
class ResolvedShareQuality {
  const ResolvedShareQuality(
    this.resolution,
    this.frameRate, {
    required this.auto,
  });

  final VoiceShareResolution resolution;
  final VoiceShareFrameRate frameRate;

  /// Whether the sharer left it to us, rather than picking a maximum.
  final bool auto;

  @override
  bool operator ==(Object other) =>
      other is ResolvedShareQuality &&
      other.resolution == resolution &&
      other.frameRate == frameRate &&
      other.auto == auto;

  @override
  int get hashCode => Object.hash(resolution, frameRate, auto);

  @override
  String toString() =>
      '${auto ? 'auto ' : ''}${resolution.label}@${frameRate.fps}';
}

/// What [quality] comes to under [limit]. Automatic starts from
/// [autoShareResolution] at [autoShareFrameRate]; a picked maximum starts from
/// itself; either is brought down to the limit, never up to it.
ResolvedShareQuality resolveShareQuality(
  VoiceShareQuality quality, {
  VoiceShareLimit limit = VoiceShareLimit.none,
}) {
  final wanted = VoiceShareLimit(
    resolution: quality.resolution ?? autoShareResolution,
    frameRate: quality.frameRate ?? autoShareFrameRate,
  ).and(limit);
  return ResolvedShareQuality(
    wanted.resolution,
    wanted.frameRate,
    auto: quality.isAuto,
  );
}

/// One of the versions a share is sent in at once.
class VoiceShareLayer {
  const VoiceShareLayer(this.resolution, this.frameRate, this.maxBitrate);

  /// The box this version is fitted inside.
  final VoiceShareLayerSize resolution;

  /// Frames per second, at most.
  final int frameRate;

  /// Bits per second, at most. A ceiling: a screen that is not changing costs
  /// a small fraction of it.
  final int maxBitrate;

  @override
  bool operator ==(Object other) =>
      other is VoiceShareLayer &&
      other.resolution == resolution &&
      other.frameRate == frameRate &&
      other.maxBitrate == maxBitrate;

  @override
  int get hashCode => Object.hash(resolution, frameRate, maxBitrate);

  @override
  String toString() =>
      '${resolution.height}p@$frameRate ${maxBitrate ~/ 1000}k';
}

/// A layer's box. Wider than [VoiceShareResolution] because the versions sent
/// *underneath* a share's top are smaller than anything a sharer can pick.
enum VoiceShareLayerSize {
  p240(426, 240),
  p360(640, 360),
  p480(854, 480),
  p720(1280, 720),
  p1080(1920, 1080);

  const VoiceShareLayerSize(this.width, this.height);

  final int width;
  final int height;

  static VoiceShareLayerSize of(VoiceShareResolution resolution) =>
      switch (resolution) {
        VoiceShareResolution.p480 => p480,
        VoiceShareResolution.p720 => p720,
        VoiceShareResolution.p1080 => p1080,
      };
}

/// The most a share's top layer may spend, in bits per second. VP8 figures;
/// see `docs/voice.md` for why the codec is not a free choice.
int shareTopBitrate(VoiceShareResolution resolution, VoiceShareFrameRate rate) {
  const table = {
    VoiceShareResolution.p480: [500, 700, 800, 1200],
    VoiceShareResolution.p720: [1200, 1600, 2000, 3000],
    VoiceShareResolution.p1080: [2500, 3200, 4000, 6000],
  };
  return table[resolution]![rate.index] * 1000;
}

/// Every version of a share that is sent at once, **smallest first**, the
/// sharer's ceiling last.
///
/// This list is the whole of "automatic". The media server forwards each
/// viewer the largest version *their* connection carries, and moves them
/// between versions as it changes — so one viewer on a train does not cost
/// anybody else their picture, which a single version cut down for the
/// weakest viewer would. The sharer's own connection is handled from the
/// other end: versions are filled smallest first, so an upload that cannot
/// afford the top simply does not send it, and a version nobody is receiving
/// is not encoded at all.
///
/// The smaller versions are capped in frame rate as well as size: somebody
/// who can only receive 360p is better served by fifteen sharp frames than by
/// sixty smeared ones.
///
/// **Always three**, whatever the ceiling. The number of versions is fixed
/// when a share is published and cannot change while it runs, so a ladder
/// that was two long at 720p and three at 1080p could not be moved between
/// them without stopping the share — and on a phone, stopping means asking
/// the system for consent again. Three everywhere is what lets
/// `setScreenShareQuality` re-aim a running share. The cost is small: the
/// extra version is tiny, and one nobody receives is not encoded.
List<VoiceShareLayer> shareLadder(ResolvedShareQuality quality) {
  final fps = quality.frameRate.fps;
  final middle = math.min(fps, 30);
  final top = VoiceShareLayer(
    VoiceShareLayerSize.of(quality.resolution),
    fps,
    shareTopBitrate(quality.resolution, quality.frameRate),
  );

  return switch (quality.resolution) {
    VoiceShareResolution.p1080 => [
      const VoiceShareLayer(VoiceShareLayerSize.p360, 15, 400000),
      VoiceShareLayer(VoiceShareLayerSize.p720, middle, 1500000),
      top,
    ],
    VoiceShareResolution.p720 => [
      const VoiceShareLayer(VoiceShareLayerSize.p240, 15, 200000),
      VoiceShareLayer(VoiceShareLayerSize.p480, middle, 800000),
      top,
    ],
    VoiceShareResolution.p480 => [
      const VoiceShareLayer(VoiceShareLayerSize.p240, 15, 200000),
      VoiceShareLayer(VoiceShareLayerSize.p360, middle, 400000),
      top,
    ],
  };
}

/// Which of [ladder]'s versions each of a share's [encodings] encoders should
/// be sending, smallest encoder first.
///
/// One each when there are as many encoders as versions, which is the case
/// this is built for. The media library can hand back fewer — it publishes
/// one or two for a very small source — and then the largest encoder still
/// carries the ceiling and the rest are taken from the bottom, so the sharer
/// always sends what they picked and the weakest viewer is always served.
List<VoiceShareLayer> shareLayersFor(
  List<VoiceShareLayer> ladder,
  int encodings,
) {
  if (ladder.isEmpty || encodings <= 0) return const [];
  if (encodings >= ladder.length) {
    // More encoders than versions cannot happen with a three-long ladder and
    // the media library's three-encoder limit; were it to, the spare ones at
    // the top all carry the ceiling rather than something larger than it.
    return [
      ...ladder,
      for (var i = ladder.length; i < encodings; i++) ladder.last,
    ];
  }
  return [...ladder.take(encodings - 1), ladder.last];
}

/// How much smaller than the version above it each version has to be, at
/// least. See [shareLayerScales].
const double shareLayerStep = 1.5;

/// How much to scale a [width]×[height] source down for each of [layers],
/// smallest version first — the numbers an encoder is given.
///
/// Each version is fitted inside its own box ([screenShareScale]), which is
/// the whole rule for a source larger than the boxes. A *small* source needs
/// one more: a 900×600 window already fits the 720p box as well as the 1080p
/// one, and would be sent twice at the same size, which helps no viewer and
/// costs the sharer an encoder. So working down from the top, every version
/// is also at least [shareLayerStep] times smaller than the one above it.
List<double> shareLayerScales(
  List<VoiceShareLayer> layers, {
  required int width,
  required int height,
}) {
  final scales = List<double>.filled(layers.length, 1);
  double? above;
  for (var i = layers.length - 1; i >= 0; i--) {
    final fitted = screenShareScale(
      width: width,
      height: height,
      boxWidth: layers[i].resolution.width,
      boxHeight: layers[i].resolution.height,
    );
    scales[i] = above == null
        ? fitted
        : math.max(fitted, above * shareLayerStep);
    above = scales[i];
  }
  return scales;
}

/// Whether a share should give up frames before sharpness when its connection
/// runs short.
///
/// At fifteen frames a share is a document, and text that goes soft is
/// unreadable while text that updates a little late is not. Anything faster
/// was picked for motion, and automatic has to serve both, so those give up a
/// little of each instead.
bool shareKeepsResolution(ResolvedShareQuality quality) =>
    !quality.auto && quality.frameRate == VoiceShareFrameRate.f15;

/// What to share, whether to send its sound, and how good to send it.
class VoiceScreenShareOptions {
  /// [withAudio] is dropped for a whole screen rather than trusted: a screen
  /// is never shared with sound, because the host's sound is never sent. Only
  /// a window can carry its own, and only after its sharer agreed to it.
  VoiceScreenShareOptions({
    required this.source,
    bool withAudio = false,
    this.quality = const VoiceShareQuality.auto(),
    this.limit = VoiceShareLimit.none,
  }) : withAudio = withAudio && source.kind == VoiceScreenSourceKind.window;

  final VoiceScreenSource source;
  final bool withAudio;

  /// What the sharer asked for.
  final VoiceShareQuality quality;

  /// What it may not exceed, whatever they asked for.
  final VoiceShareLimit limit;
}

/// What this client is actually sharing right now.
class VoiceScreenShareState {
  const VoiceScreenShareState.off()
    : source = null,
      withAudio = false,
      quality = const VoiceShareQuality.auto();

  const VoiceScreenShareState.sharing(
    VoiceScreenSource this.source, {
    required this.withAudio,
    this.quality = const VoiceShareQuality.auto(),
  });

  /// What is being shared, or null when nothing is.
  final VoiceScreenSource? source;

  /// Whether its sound is really going out — which can be less than was asked
  /// for, when it could not be captured or the server withdrew it.
  final bool withAudio;

  /// The ceiling its sharer picked. What is really going out is
  /// [VoiceShareSendStats].
  final VoiceShareQuality quality;

  bool get on => source != null;
}

/// What is holding a share below its ceiling.
enum VoiceShareLimitedBy {
  /// Nothing: it is going out as asked.
  nothing,

  /// This device's upload cannot carry more.
  network,

  /// This device cannot encode more — its processor is the limit.
  device,

  /// Nobody is watching it any larger, so nothing larger is being made. Not a
  /// problem, and said so the sharer does not go looking for one.
  viewers,
}

/// What a share is really being sent at, measured — as opposed to what its
/// sharer asked for. The largest version being sent at the moment.
class VoiceShareSendStats {
  const VoiceShareSendStats({
    required this.width,
    required this.height,
    required this.frameRate,
    required this.bitrate,
    required this.limitedBy,
  });

  /// Nothing is going out at all: nobody is watching the share, so no version
  /// of it is being encoded.
  const VoiceShareSendStats.idle()
    : width = 0,
      height = 0,
      frameRate = 0,
      bitrate = 0,
      limitedBy = VoiceShareLimitedBy.viewers;

  final int width;
  final int height;
  final int frameRate;

  bool get idle => width <= 0 || height <= 0;

  /// Bits per second, across every version being sent.
  final int bitrate;

  final VoiceShareLimitedBy limitedBy;

  /// The picture's size the way people say it: by its shorter side, so a
  /// portrait phone at 1080×1920 is "1080p" like the landscape one.
  String get sizeLabel => '${math.min(width, height)}p';

  @override
  bool operator ==(Object other) =>
      other is VoiceShareSendStats &&
      other.width == width &&
      other.height == height &&
      other.frameRate == frameRate &&
      other.bitrate == bitrate &&
      other.limitedBy == limitedBy;

  @override
  int get hashCode => Object.hash(width, height, frameRate, bitrate, limitedBy);
}

/// Which version of somebody's share this device asks for.
///
/// [auto] is the media server choosing for this device's connection and the
/// size the share is drawn at, which is right nearly always. The others pin it
/// lower — for a metered connection, where "what the connection can carry" and
/// "what its owner wants to pay for" are different answers. Never higher than
/// automatic would give: a version the connection cannot carry does not arrive
/// for being asked for.
enum VoiceShareReceiveQuality {
  auto('Auto'),
  high('High'),
  medium('Medium'),
  low('Low');

  const VoiceShareReceiveQuality(this.label);

  final String label;
}

/// How much to scale a [width]×[height] picture down so it fits inside
/// [boxWidth]×[boxHeight] — 1920×1080 unless told otherwise — or the same box
/// turned on its side, for a portrait source, keeping its shape. Never below
/// 1: nothing is scaled up.
///
/// Fitting the box rather than only capping the height is what bounds the
/// bandwidth: an ultrawide 3440×1440 capped at 1080 lines would still be 34%
/// more pixels than 1080p, where fitting it gives 1920×804.
double screenShareScale({
  required int width,
  required int height,
  int boxWidth = 1920,
  int boxHeight = 1080,
}) {
  if (width <= 0 || height <= 0) return 1;

  final long = math.max(width, height);
  final short = math.min(width, height);

  return math.max(1, math.max(long / boxWidth, short / boxHeight));
}

/// One live camera in a call, or in the pre-join preview.
///
/// The engine builds its own surface, which is what keeps the media library
/// inside `livekit_voice_engine.dart`: a feed *is* the renderer, so no widget
/// outside `core/voice/` ever names a track type. [VoiceVideoView] draws one.
abstract class VoiceVideoFeed {
  /// Whose camera or screen this is — their member UUID, as in the roster.
  String get identity;

  /// A camera, or a shared screen or window. A screen is drawn whole
  /// (`BoxFit.contain`) and never mirrored.
  VoiceVideoKind get kind;

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

/// One call's media. Created per call and disposed when it ends.
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

  /// Phones only: plays the call out of the loudspeaker rather than the
  /// earpiece. A no-op where there is only one of them — see
  /// `canUseSpeakerphone`.
  Future<void> setSpeakerphone(bool enabled);

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

  /// Every camera in the call and every screen share this client watches —
  /// its own share included — this client's own first. Tell them apart by
  /// [VoiceVideoFeed.kind]. The whole list is replaced on every change, like
  /// [activeSpeakers], so a listener never has to merge.
  Stream<List<VoiceVideoFeed>> get videoFeeds;

  /// Participants whose *camera* arrived in a state this client will not
  /// render: unencrypted, or not decrypting. Their tile says so instead of
  /// showing video. Nothing untrusted is ever drawn. Shares are
  /// [untrustedScreenShares].
  Stream<Set<String>> get untrustedVideo;

  /// Stops receiving one participant's camera, or starts again.
  ///
  /// Local only: the sender is never told and keeps sending to everybody else.
  /// It really stops the stream rather than hiding it, so hiding a camera
  /// saves the bandwidth as well as the screen space.
  Future<void> setVideoVisible(String identity, bool visible);

  /// Starts sharing a screen or a window, or stops.
  ///
  /// Returns false, without throwing and without capturing anything, when the
  /// server has not granted what [options] asks for — the picture, and the
  /// sound too when it asks for sound. The caller asked the server first and
  /// waits for the grant, like the camera's handshake. A new share replaces a
  /// running one.
  ///
  /// The picture is scaled down to fit the box [VoiceScreenShareOptions.quality]
  /// comes to before it is encoded, whatever the source's size, and sent in
  /// every version [shareLadder] lists.
  Future<bool> setScreenShareEnabled(
    bool enabled, {
    VoiceScreenShareOptions? options,
  });

  /// Asks the system for whatever it wants before a screen may be captured,
  /// and answers whether it was given.
  ///
  /// On the desktops there is nothing to ask at this point (macOS asks when
  /// the picker lists the screens), so this is true at once. On a phone it
  /// **is** the picker: Android's capture consent, or iOS's broadcast sheet —
  /// and on iOS the answer only comes once the broadcast has really started,
  /// since that sheet reports nothing when it is dismissed.
  ///
  /// It comes *before* the server is told anything, so a sharer who thinks
  /// better of it at the system's sheet was never shown to anybody as
  /// sharing. Having been given consent, a share that then does not start
  /// must hand it back: [cancelScreenCapture].
  Future<bool> prepareScreenCapture();

  /// Gives up a consent [prepareScreenCapture] obtained, for a share that is
  /// not going to start after all — the server refused it, or the call ended.
  /// On iOS this is what takes the recording indicator down again.
  Future<void> cancelScreenCapture();

  /// Changes a running share's ceiling without restarting it where that is
  /// possible — which is everywhere but one case: a desktop capture opened at
  /// a lower frame rate cannot be asked for a higher one, and is reopened.
  /// Nothing is asked of the user again either way. A no-op when not sharing.
  Future<void> setScreenShareQuality(
    VoiceShareQuality quality, {
    VoiceShareLimit limit = VoiceShareLimit.none,
  });

  /// What the share is really going out at, every couple of seconds while one
  /// is running.
  Stream<VoiceShareSendStats> get screenShareSendStats;

  /// Which version of [identity]'s share this device asks for. Kept like
  /// [setScreenShareWatched], so it outlives the share it was set on.
  Future<void> setScreenShareReceiveQuality(
    String identity,
    VoiceShareReceiveQuality quality,
  );

  /// What this client is sharing, as it changes — including when the engine
  /// stopped it itself (the window closed, the grant was withdrawn, it could
  /// not be encrypted) or carries on without sound it could not capture.
  Stream<VoiceScreenShareState> get screenShareStates;

  VoiceScreenShareState get currentScreenShare;

  /// Starts or stops receiving one participant's screen share — its picture
  /// and its sound together.
  ///
  /// **Nobody's share is received until it is watched**: the media server
  /// forwards nothing from it to this device until then, which is the biggest
  /// bandwidth saving in a call. The wish is kept, so a share that is stopped
  /// and started again stays watched, or unwatched.
  Future<void> setScreenShareWatched(String identity, bool watched);

  /// How loud [identity]'s shared window plays here, separately from their
  /// voice: 0 silent, 1 as sent, up to [maximumVolume].
  Future<void> setScreenShareVolume(String identity, double volume);

  /// Participants who are sharing a screen this client trusts — watched or
  /// not. The whole set is replaced on every change.
  Stream<Set<String>> get screenShares;

  /// Participants whose share arrived unencrypted or is not decrypting. It is
  /// never drawn or played.
  Stream<Set<String>> get untrustedScreenShares;

  /// Something the engine refused for safety, in words for the user — media it
  /// could not encrypt, an effect it had to turn off. Never fatal: the call
  /// goes on without whatever was refused.
  Stream<String> get warnings;

  /// Fires when the microphone could not be opened, having been asked for.
  ///
  /// This is a *device* problem, not a permission or a moderator's decision:
  /// something else holds the microphone (on a phone, a cellular call is the
  /// usual culprit), or the OS took it away. It is deliberately not an error
  /// from [connect] or [setMicEnabled], because a call you can hear is worth
  /// keeping — this participant is simply not heard until it works. Trying
  /// again is [setMicEnabled].
  Stream<void> get microphoneFailures;

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

/// Prepares the media stack before the first call, which `main` does at
/// startup. On phones this has to happen before any call: the audio session a
/// call needs is decided when the media library first initializes, not when a
/// call starts. Everywhere else it is a no-op.
Future<void> initializeVoice() => LiveKitVoiceEngine.initialize();

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

/// The displays and windows this machine can share, live, for the share
/// picker. Not a method on [VoiceEngine], for the same reason as
/// [openCameraPreview]: choosing comes before the share, and must not need one.
Future<VoiceScreenSources> openScreenSources() =>
    LiveKitVoiceEngine.screenSources();

/// Opens a camera outside a call, for the camera-and-effects sheet.
///
/// Deliberately not a method on [VoiceEngine]: the sheet is reachable from
/// settings with no call in progress, and a preview must not need one.
Future<VoiceCameraPreview> openCameraPreview(VoiceCameraOptions options) =>
    LiveKitVoiceEngine.preview(options);
