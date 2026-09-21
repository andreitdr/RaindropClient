import '../../../core/voice/voice_engine.dart';

/// How one member sounds on this device: louder or quieter than sent, or not
/// at all. Local only — nobody else, the member included, is affected.
class MemberAudio {
  const MemberAudio({this.volume = 1.0, this.muted = false});

  /// 1 as sent, 0 silent, up to [maximumVolume] boosted.
  final double volume;

  /// Muted on this device only.
  final bool muted;

  bool get isDefault => volume == 1.0 && !muted;

  MemberAudio copyWith({double? volume, bool? muted}) =>
      MemberAudio(volume: volume ?? this.volume, muted: muted ?? this.muted);

  Map<String, dynamic> toJson() => {'volume': volume, 'muted': muted};

  factory MemberAudio.fromJson(Map<String, dynamic> j) => MemberAudio(
    volume: (j['volume'] is num)
        ? (j['volume'] as num).toDouble().clamp(0.0, maximumVolume).toDouble()
        : 1.0,
    muted: j['muted'] is bool && j['muted'] as bool,
  );
}

/// The key a member's settings are stored under: their UUID only means
/// something on one server.
String memberAudioKey(String serverId, String userId) => '$serverId/$userId';

/// What a remote member actually plays at: nothing while deafened or locally
/// muted, otherwise their own volume scaled by the output volume — capped, so
/// two boosts cannot multiply into distortion.
double effectiveVolume({
  required double outputVolume,
  required MemberAudio member,
  required bool deafened,
}) {
  if (deafened || member.muted) return 0;
  return (outputVolume * member.volume).clamp(0.0, maximumVolume).toDouble();
}
