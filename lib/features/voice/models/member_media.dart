import '../../../core/voice/voice_engine.dart';

/// What one member sounds and looks like on this device: louder or quieter
/// than sent or not at all, and whether their camera is shown.
///
/// **Local only** — nobody else, the member included, is affected or told.
class MemberMedia {
  const MemberMedia({
    this.volume = 1.0,
    this.muted = false,
    this.videoHidden = false,
  });

  /// 1 as sent, 0 silent, up to [maximumVolume] boosted.
  final double volume;

  /// Muted on this device only.
  final bool muted;

  /// Their camera is not shown here, and not even received: hiding a camera
  /// saves the bandwidth as well as the screen space. They are not told, and
  /// keep sending to everybody else.
  final bool videoHidden;

  bool get isDefault => volume == 1.0 && !muted && !videoHidden;

  MemberMedia copyWith({double? volume, bool? muted, bool? videoHidden}) =>
      MemberMedia(
        volume: volume ?? this.volume,
        muted: muted ?? this.muted,
        videoHidden: videoHidden ?? this.videoHidden,
      );

  Map<String, dynamic> toJson() => {
    'volume': volume,
    'muted': muted,
    'videoHidden': videoHidden,
  };

  factory MemberMedia.fromJson(Map<String, dynamic> j) => MemberMedia(
    volume: (j['volume'] is num)
        ? (j['volume'] as num).toDouble().clamp(0.0, maximumVolume).toDouble()
        : 1.0,
    muted: j['muted'] is bool && j['muted'] as bool,
    videoHidden: j['videoHidden'] is bool && j['videoHidden'] as bool,
  );
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
