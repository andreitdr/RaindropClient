import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_controller.dart';
import '../models/voice_settings.dart';

/// This client's voice preferences, persisted in `AppPrefs` and applied to a
/// call in progress by `voiceCallProvider` as they change.
final voiceSettingsProvider =
    NotifierProvider<VoiceSettingsController, VoiceSettings>(
      VoiceSettingsController.new,
    );

class VoiceSettingsController extends Notifier<VoiceSettings> {
  @override
  VoiceSettings build() =>
      VoiceSettings.fromJson(ref.read(appPrefsProvider).voiceSettingsJson);

  void update(VoiceSettings Function(VoiceSettings current) change) {
    state = change(state);
    ref.read(appPrefsProvider).setVoiceSettingsJson(state.toJson());
  }

  /// Flips the microphone. Unmuting while deafened undeafens too — nobody
  /// wants to talk into a call they cannot hear.
  void toggleMute() => update(
    (s) => s.selfDeaf
        ? s.copyWith(selfDeaf: false, selfMute: false)
        : s.copyWith(selfMute: !s.selfMute),
  );

  /// Flips deafen. Deafening mutes; undeafening puts the microphone back how
  /// it was before.
  void toggleDeafen() => update(
    (s) => s.selfDeaf
        ? s.copyWith(selfDeaf: false, selfMute: s.mutedBeforeDeafen)
        : s.copyWith(
            selfDeaf: true,
            selfMute: true,
            mutedBeforeDeafen: s.selfMute,
          ),
  );
}
