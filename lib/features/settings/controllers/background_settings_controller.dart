import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_controller.dart';
import '../models/background_settings.dart';

/// This device's [BackgroundSettings], persisted in `AppPrefs`. The call
/// controller reads [BackgroundSettings.showCallOutsideApp] into what it tells
/// the OS about a call; `appResidencyBindingProvider` hands
/// [BackgroundSettings.keepRunningWhenClosed] to the desktop's window.
final backgroundSettingsProvider =
    NotifierProvider<BackgroundSettingsController, BackgroundSettings>(
      BackgroundSettingsController.new,
    );

class BackgroundSettingsController extends Notifier<BackgroundSettings> {
  @override
  BackgroundSettings build() => BackgroundSettings.fromJson(
    ref.read(appPrefsProvider).backgroundSettingsJson,
  );

  void setKeepRunningWhenClosed(bool keep) =>
      _update(state.copyWith(keepRunningWhenClosed: keep));

  void setShowCallOutsideApp(bool show) =>
      _update(state.copyWith(showCallOutsideApp: show));

  void _update(BackgroundSettings next) {
    if (next == state) return;
    state = next;
    ref.read(appPrefsProvider).setBackgroundSettingsJson(next.toJson());
  }
}
