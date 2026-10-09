/// The app's view of `raindrop.v1.VoiceService` (RaindropProto's
/// `voice.proto`): call control only.
///
/// The server decides who may join, speak, show their camera, share their
/// screen and moderate; the media itself travels over a media transport it
/// names in [VoiceJoinResult.transport] —
/// see `core/voice/` for the engine that speaks it. That engine's signalling
/// is the one connection to the server that is not gRPC: LiveKit's own
/// WebSocket, relayed at [VoiceJoinResult.path].
library;

import 'grpc/protocol.dart' as pb;
import 'grpc/wire.dart';
import 'raindrop_channel.dart';

/// Why somebody is no longer in a call, as `voice.left` names it. An open set
/// like event types: a name this build does not know is treated as [left].
abstract final class VoiceLeaveReasons {
  static const left = 'left';
  static const moved = 'moved';
  static const disconnected = 'disconnected';
  static const replaced = 'replaced';
  static const permissionLost = 'permission_lost';
  static const sessionEnded = 'session_ended';
  static const channelDeleted = 'channel_deleted';
  static const serverEnded = 'server_ended';
}

/// What a screen share shows, as the wire names it. A closed set.
abstract final class VoiceShareKinds {
  /// A whole display. Never carries sound.
  static const screen = 'screen';

  /// One window, optionally with that window's own sound.
  static const window = 'window';
}

/// One member in one call — the whole state, merged on
/// ([channelId], [userId]).
class VoiceParticipant {
  const VoiceParticipant({
    required this.channelId,
    required this.userId,
    required this.selfMute,
    required this.selfDeaf,
    required this.serverMute,
    required this.suppressed,
    required this.connected,
    required this.joinedAtUtc,
    this.cameraOn = false,
    this.cameraSuppressed = false,
    this.screenShareOn = false,
    this.screenShareKind,
    this.screenShareAudio = false,
    this.screenShareSuppressed = false,
  });

  final String channelId;
  final String userId;

  /// They muted their own microphone.
  final bool selfMute;

  /// They stopped hearing the call; implies [selfMute].
  final bool selfDeaf;

  /// A moderator muted them for everyone.
  final bool serverMute;

  /// They lack `speak`, so they can only listen.
  final bool suppressed;

  /// The media server has seen them connect.
  final bool connected;

  final DateTime joinedAtUtc;

  /// They are sending their camera to the call.
  final bool cameraOn;

  /// They lack `video`, or every camera place in the call is taken, so they
  /// cannot turn their camera on. The counterpart of [suppressed].
  final bool cameraSuppressed;

  /// They are sharing a screen or a window.
  final bool screenShareOn;

  /// What they are sharing, a [VoiceShareKinds] name; null while they are not.
  final String? screenShareKind;

  /// They are sending the shared window's own sound too. Never for a screen,
  /// and never while they may not speak.
  final bool screenShareAudio;

  /// They lack `screen_share`, or this server carries no screen sharing, so
  /// they cannot start one.
  final bool screenShareSuppressed;

  /// Whether they could be heard at all right now.
  bool get canBeHeard => !selfMute && !selfDeaf && !serverMute && !suppressed;

  factory VoiceParticipant.fromProto(pb.VoiceParticipant m) => VoiceParticipant(
    channelId: m.channelId,
    userId: m.userId,
    selfMute: m.selfMute,
    selfDeaf: m.selfDeaf,
    serverMute: m.serverMute,
    suppressed: m.suppressed,
    connected: m.connected,
    joinedAtUtc: Wire.time(m.joinedAt),
    cameraOn: m.cameraOn,
    cameraSuppressed: m.cameraSuppressed,
    screenShareOn: m.screenShareOn,
    screenShareKind: m.screenShareOn ? Wire.screenShareKind(m.screenShareKind) : null,
    screenShareAudio: m.screenShareOn && m.screenShareAudio,
    screenShareSuppressed: m.screenShareSuppressed,
  );
}

/// What `voice.left` carries.
class VoiceLeft {
  const VoiceLeft({
    required this.channelId,
    required this.userId,
    required this.reason,
  });

  final String channelId;
  final String userId;
  final String reason;

  factory VoiceLeft.fromProto(pb.VoiceLeftEvent m) => VoiceLeft(
    channelId: m.channelId,
    userId: m.userId,
    reason: m.reason.isEmpty ? VoiceLeaveReasons.left : m.reason,
  );
}

/// Whether voice works on this server, and who is in every call the caller
/// can see.
class VoiceStatus {
  const VoiceStatus({
    required this.available,
    required this.transport,
    required this.maximumParticipants,
    required this.participants,
    this.maximumCameraPublishers = 0,
    this.maximumScreenShares = 0,
  });

  final bool available;
  final String transport;
  final int maximumParticipants;
  final List<VoiceParticipant> participants;

  /// How many members of one call may send their camera at once. 0 when this
  /// server carries no camera video, which is also when it does not advertise
  /// `voice.video.v1`.
  final int maximumCameraPublishers;

  /// How many members of one call may share their screen at once. 0 when this
  /// server carries no screen sharing, which is also when it does not
  /// advertise `voice.screen.v1`.
  final int maximumScreenShares;

  factory VoiceStatus.fromProto(pb.GetVoiceStatusResponse m) => VoiceStatus(
    available: m.available,
    transport: m.transport.isEmpty ? 'none' : m.transport,
    maximumParticipants: m.maximumParticipants,
    participants: [
      for (final p in m.participants) VoiceParticipant.fromProto(p),
    ],
    maximumCameraPublishers: m.maximumCameraPublishers,
    maximumScreenShares: m.maximumScreenShares,
  );
}

/// What joining returns: where and how to connect the audio.
class VoiceJoinResult {
  const VoiceJoinResult({
    required this.channelId,
    required this.transport,
    required this.url,
    required this.path,
    required this.token,
    required this.expiresAtUtc,
    required this.you,
    required this.participants,
  });

  final String channelId;

  /// Which engine to connect with, e.g. `livekit`.
  final String transport;

  /// An absolute address to connect to, or null to connect through this
  /// server at [path].
  final String? url;
  final String? path;

  /// Short-lived: join again for a fresh one rather than reusing it.
  final String token;
  final DateTime expiresAtUtc;

  final VoiceParticipant you;
  final List<VoiceParticipant> participants;

  /// The WebSocket address to hand the engine. Built from the host and port
  /// this client already connects to — and pins — when the server relays the
  /// connection itself, which is the usual case.
  Uri signalUri({required String host, required int port}) {
    if (url case final absolute?) return Uri.parse(absolute);
    return Uri(scheme: 'wss', host: host, port: port, path: path ?? '/');
  }

  factory VoiceJoinResult.fromProto(pb.JoinVoiceResponse m) => VoiceJoinResult(
    channelId: m.channelId,
    transport: m.transport,
    url: m.hasUrl() ? m.url : null,
    path: m.hasPath() ? m.path : null,
    token: m.token,
    expiresAtUtc: Wire.time(m.expiresAt),
    you: VoiceParticipant.fromProto(m.you),
    participants: [
      for (final p in m.participants) VoiceParticipant.fromProto(p),
    ],
  );
}

/// `raindrop.v1.VoiceService`. One per connected server.
class VoiceApi {
  VoiceApi(this._channel) : _voice = pb.VoiceServiceClient(_channel.channel);

  final RaindropChannel _channel;
  final pb.VoiceServiceClient _voice;

  Future<VoiceStatus> status(String token) async => VoiceStatus.fromProto(
    await _channel.call(
      (o) => _voice.getVoiceStatus(pb.GetVoiceStatusRequest(), options: o),
      token: token,
    ),
  );

  /// Joins a call. Needs `connect`; the server answers `channel_full`,
  /// `voice_unavailable` or `missing_permission` when it cannot.
  Future<VoiceJoinResult> join(
    String token, {
    required String channelId,
    bool selfMute = false,
    bool selfDeaf = false,
  }) async => VoiceJoinResult.fromProto(
    await _channel.call(
      (o) => _voice.joinVoice(
        pb.JoinVoiceRequest(
          channelId: channelId,
          selfMute: selfMute,
          selfDeaf: selfDeaf,
        ),
        options: o,
      ),
      token: token,
    ),
  );

  /// Leaves the named call. Safe to repeat: false when this session was not
  /// in it.
  Future<bool> leave(String token, {required String channelId}) async =>
      (await _channel.call(
        (o) => _voice.leaveVoice(
          pb.LeaveVoiceRequest(channelId: channelId),
          options: o,
        ),
        token: token,
      )).left;

  /// Tells everybody you muted or deafened yourself, turns your camera on or
  /// off, and starts, changes or stops your screen share.
  ///
  /// **This is the whole state, not a change**: every field is read, so a call
  /// that leaves out a camera or a share that is running turns it off. Pass
  /// what is true now, not only what changed.
  ///
  /// Mute and deafen are only everybody's icons and are always accepted. The
  /// camera and a share each earn the media server's permission to send one,
  /// so they can be refused — `missing_permission` without `video` or
  /// `screen_share` (or asking for a window's sound while unable to speak),
  /// `camera_limit_reached` / `screen_share_limit_reached` when every place is
  /// taken — and a refusal leaves a mute in the same request standing. A share
  /// with no kind, or a screen with sound, is `invalid_payload`.
  Future<VoiceParticipant> setSelfState(
    String token, {
    required bool selfMute,
    required bool selfDeaf,
    required bool cameraOn,
    required bool screenShareOn,
    String? screenShareKind,
    bool screenShareAudio = false,
  }) async => VoiceParticipant.fromProto(
    (await _channel.call(
      (o) => _voice.setVoiceSelfState(
        pb.SetVoiceSelfStateRequest(
          selfMute: selfMute,
          selfDeaf: selfDeaf,
          cameraOn: cameraOn,
          screenShareOn: screenShareOn,
          screenShareKind: Wire.screenShareKindOf(
            screenShareOn ? screenShareKind : null,
          ),
          screenShareAudio: screenShareOn && screenShareAudio,
        ),
        options: o,
      ),
      token: token,
    )).participant,
  );

  /// Mutes (or unmutes) a member in every call, for everyone. Needs
  /// `mute_members` server-wide.
  Future<void> setServerMute(
    String token, {
    required String userId,
    required bool muted,
  }) => _channel.call(
    (o) => _voice.muteVoiceMember(
      pb.MuteVoiceMemberRequest(userId: userId, muted: muted),
      options: o,
    ),
    token: token,
  );
}
