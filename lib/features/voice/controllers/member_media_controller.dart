import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_controller.dart';
import '../models/member_media.dart';

/// Per-member volume, local mute and hidden camera, for every member on every
/// server this client has adjusted, keyed by [memberMediaKey]. Only members who
/// differ from the default are stored, so the map does not grow a row per
/// member anybody has ever been in a call with.
///
/// All of it is local: none of it reaches the server, and nobody is told.
final memberAudioProvider =
    NotifierProvider<MemberMediaController, Map<String, MemberMedia>>(
      MemberMediaController.new,
    );

class MemberMediaController extends Notifier<Map<String, MemberMedia>> {
  @override
  Map<String, MemberMedia> build() => {
    for (final entry in ref.read(appPrefsProvider).memberAudioJson.entries)
      if (entry.value is Map)
        entry.key: MemberMedia.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        ),
  };

  MemberMedia of(String serverId, String userId) =>
      state[memberMediaKey(serverId, userId)] ?? const MemberMedia();

  void setVolume(String serverId, String userId, double volume) =>
      _set(serverId, userId, of(serverId, userId).copyWith(volume: volume));

  void setMuted(String serverId, String userId, bool muted) =>
      _set(serverId, userId, of(serverId, userId).copyWith(muted: muted));

  void setVideoHidden(String serverId, String userId, bool hidden) => _set(
    serverId,
    userId,
    of(serverId, userId).copyWith(videoHidden: hidden),
  );

  void _set(String serverId, String userId, MemberMedia media) {
    final key = memberMediaKey(serverId, userId);
    state = {
      for (final entry in state.entries)
        if (entry.key != key) entry.key: entry.value,
      if (!media.isDefault) key: media,
    };
    ref.read(appPrefsProvider).setMemberAudioJson({
      for (final entry in state.entries) entry.key: entry.value.toJson(),
    });
  }
}
