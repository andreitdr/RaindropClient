/// Dart mirrors of the C# records in `RaindropServer/Channels/Voice/
/// VoiceContracts.cs`, and the wrapper over `/api/channels/voice`.
///
/// The server decides who may join, speak and moderate; the audio itself
/// travels over a media transport it names in [VoiceJoinResult.transport] —
/// see `core/voice/` for the engine that speaks it.
library;

import 'api_client.dart';

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

  /// Whether they could be heard at all right now.
  bool get canBeHeard => !selfMute && !selfDeaf && !serverMute && !suppressed;

  factory VoiceParticipant.fromJson(Map<String, dynamic> j) => VoiceParticipant(
    channelId: j['channelId'] as String,
    userId: j['userId'] as String,
    selfMute: j['selfMute'] as bool? ?? false,
    selfDeaf: j['selfDeaf'] as bool? ?? false,
    serverMute: j['serverMute'] as bool? ?? false,
    suppressed: j['suppressed'] as bool? ?? false,
    connected: j['connected'] as bool? ?? false,
    joinedAtUtc: DateTime.parse(j['joinedAtUtc'] as String),
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

  factory VoiceLeft.fromJson(Map<String, dynamic> j) => VoiceLeft(
    channelId: j['channelId'] as String,
    userId: j['userId'] as String,
    reason: j['reason'] as String? ?? VoiceLeaveReasons.left,
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
  });

  final bool available;
  final String transport;
  final int maximumParticipants;
  final List<VoiceParticipant> participants;

  factory VoiceStatus.fromJson(Map<String, dynamic> j) => VoiceStatus(
    available: j['available'] as bool? ?? false,
    transport: j['transport'] as String? ?? 'none',
    maximumParticipants: (j['maximumParticipants'] as num?)?.toInt() ?? 0,
    participants: [
      for (final p in j['participants'] as List? ?? const [])
        VoiceParticipant.fromJson(Map<String, dynamic>.from(p as Map)),
    ],
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

  factory VoiceJoinResult.fromJson(Map<String, dynamic> j) => VoiceJoinResult(
    channelId: j['channelId'] as String,
    transport: j['transport'] as String,
    url: j['url'] as String?,
    path: j['path'] as String?,
    token: j['token'] as String,
    expiresAtUtc: DateTime.parse(j['expiresAtUtc'] as String),
    you: VoiceParticipant.fromJson(Map<String, dynamic>.from(j['you'] as Map)),
    participants: [
      for (final p in j['participants'] as List? ?? const [])
        VoiceParticipant.fromJson(Map<String, dynamic>.from(p as Map)),
    ],
  );
}

/// Typed wrapper over `/api/channels/voice`. One per connected server.
class VoiceApi {
  VoiceApi(this._client);

  final ApiClient _client;

  Future<VoiceStatus> status(String token) async => VoiceStatus.fromJson(
    await _client.get('/api/channels/voice', token: token),
  );

  /// Joins a call. Needs `connect`; the server answers `channel_full`,
  /// `voice_unavailable` or `missing_permission` when it cannot.
  Future<VoiceJoinResult> join(
    String token, {
    required String channelId,
    bool selfMute = false,
    bool selfDeaf = false,
  }) async => VoiceJoinResult.fromJson(
    await _client.post(
      '/api/channels/voice/join',
      body: {
        'channelId': channelId,
        'selfMute': selfMute,
        'selfDeaf': selfDeaf,
      },
      token: token,
    ),
  );

  /// Leaves the named call. Safe to repeat: false when this session was not
  /// in it.
  Future<bool> leave(String token, {required String channelId}) async {
    final body = await _client.post(
      '/api/channels/voice/leave',
      body: {'channelId': channelId},
      token: token,
    );
    return body['left'] as bool? ?? false;
  }

  /// Tells everybody you muted or deafened yourself.
  Future<VoiceParticipant> setSelfState(
    String token, {
    required bool selfMute,
    required bool selfDeaf,
  }) async => VoiceParticipant.fromJson(
    await _client.post(
      '/api/channels/voice/state',
      body: {'selfMute': selfMute, 'selfDeaf': selfDeaf},
      token: token,
    ),
  );

  /// Mutes (or unmutes) a member in every call, for everyone. Needs
  /// `mute_members` server-wide.
  Future<void> setServerMute(
    String token, {
    required String userId,
    required bool muted,
  }) => _client.post(
    '/api/channels/voice/mute',
    body: {'userId': userId, 'muted': muted},
    token: token,
  );
}
