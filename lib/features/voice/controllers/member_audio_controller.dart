import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_controller.dart';
import '../models/member_audio.dart';

/// Per-member volume and local mute, for every member on every server this
/// client has adjusted, keyed by [memberAudioKey]. Only members who differ
/// from the default are stored.
final memberAudioProvider =
    NotifierProvider<MemberAudioController, Map<String, MemberAudio>>(
      MemberAudioController.new,
    );

class MemberAudioController extends Notifier<Map<String, MemberAudio>> {
  @override
  Map<String, MemberAudio> build() => {
    for (final entry in ref.read(appPrefsProvider).memberAudioJson.entries)
      if (entry.value is Map)
        entry.key: MemberAudio.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        ),
  };

  MemberAudio of(String serverId, String userId) =>
      state[memberAudioKey(serverId, userId)] ?? const MemberAudio();

  void setVolume(String serverId, String userId, double volume) =>
      _set(serverId, userId, of(serverId, userId).copyWith(volume: volume));

  void setMuted(String serverId, String userId, bool muted) =>
      _set(serverId, userId, of(serverId, userId).copyWith(muted: muted));

  void _set(String serverId, String userId, MemberAudio audio) {
    final key = memberAudioKey(serverId, userId);
    state = {
      for (final entry in state.entries)
        if (entry.key != key) entry.key: entry.value,
      if (!audio.isDefault) key: audio,
    };
    ref.read(appPrefsProvider).setMemberAudioJson({
      for (final entry in state.entries) entry.key: entry.value.toJson(),
    });
  }
}
