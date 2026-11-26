import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/app_residency.dart';
import '../../../core/router/app_router.dart';
import '../../identity/controllers/app_lock.dart';
import 'background_settings_controller.dart';

/// Keeps the desktop's [AppResidency] in step with the person's choice, and
/// carries out what its icon asks for. Watched once by the app's root widget,
/// for as long as the app runs; inert where there is no residency.
final appResidencyBindingProvider = Provider<void>((ref) {
  final residency = ref.watch(appResidencyProvider);
  if (!residency.available) return;

  ref.listen(
    backgroundSettingsProvider.select((s) => s.keepRunningWhenClosed),
    (_, keep) => unawaited(residency.setKeepRunningWhenClosed(keep)),
    fireImmediately: true,
  );

  final commands = residency.commands.listen((command) {
    switch (command) {
      case ResidencyCommand.openSettings:
        // Settings are behind the lock like everything else: a locked app
        // shows its lock when the window comes back, and nothing more.
        if (ref.read(appLockProvider)) unawaited(appRouter.push('/settings'));
    }
  });
  ref.onDispose(commands.cancel);
});
