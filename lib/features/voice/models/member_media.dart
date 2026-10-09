import '../../../core/voice/voice_engine.dart';

/// What one member sounds and looks like on this device: louder or quieter
/// than sent or not at all, whether their camera is shown, and how loud the
/// window they share plays.
///
/// **Local only** — nobody else, the member included, is affected or told.
class MemberMedia {
  const MemberMedia({
    this.volume = 1.0,
    this.muted = false,
    this.videoHidden = false,
    this.screenVolume = 1.0,
  });

  /// 1 as sent, 0 silent, up to [maximumVolume] boosted.
  final double volume;

  /// Muted on this device only.
  final bool muted;

  /// Their camera is not shown here, and not even received: hiding a camera
  /// saves the bandwidth as well as the screen space. They are not told, and
  /// keep sending to everybody else.
  final bool videoHidden;

  /// How loud a window they share plays, apart from their voice: a film shared
  /// into a call usually wants turning down, and turning *them* down with it
  /// would make them hard to hear over it. 1 as sent, 0 silent.
  final double screenVolume;

  bool get isDefault =>
      volume == 1.0 && !muted && !videoHidden && screenVolume == 1.0;

  MemberMedia copyWith({
    double? volume,
    bool? muted,
    bool? videoHidden,
    double? screenVolume,
  }) => MemberMedia(
    volume: volume ?? this.volume,
    muted: muted ?? this.muted,
    videoHidden: videoHidden ?? this.videoHidden,
    screenVolume: screenVolume ?? this.screenVolume,
  );

  Map<String, dynamic> toJson() => {
    'volume': volume,
    'muted': muted,
    'videoHidden': videoHidden,
    'screenVolume': screenVolume,
  };

  factory MemberMedia.fromJson(Map<String, dynamic> j) => MemberMedia(
    volume: _volumeOf(j['volume']),
    muted: j['muted'] is bool && j['muted'] as bool,
    videoHidden: j['videoHidden'] is bool && j['videoHidden'] as bool,
    // Absent in what an older build wrote, which reads as "as sent".
    screenVolume: _volumeOf(j['screenVolume']),
  );

  static double _volumeOf(Object? value) => value is num
      ? value.toDouble().clamp(0.0, maximumVolume).toDouble()
      : 1.0;
}

/// The key a member's settings are stored under: their UUID only means
/// something on one server.
String memberMediaKey(String serverId, String userId) => '$serverId/$userId';

/// What a remote member actually plays at: nothing while deafened or locally
/// muted, otherwise their own volume scaled by the output volume — capped, so
/// two boosts cannot multiply into distortion.
double effectiveVolume({
  required double outputVolume,
  required MemberMedia member,
  required bool deafened,
}) {
  if (deafened || member.muted) return 0;
  return (outputVolume * member.volume).clamp(0.0, maximumVolume).toDouble();
}

/// What a member's shared window actually plays at: nothing while deafened,
/// otherwise its own volume scaled by the output volume. Muting the member
/// does not silence it — that mutes their voice, and their share has its own
/// slider — so a muted talker's film can still be heard.
double effectiveScreenVolume({
  required double outputVolume,
  required MemberMedia member,
  required bool deafened,
}) {
  if (deafened) return 0;
  return (outputVolume * member.screenVolume)
      .clamp(0.0, maximumVolume)
      .toDouble();
}
