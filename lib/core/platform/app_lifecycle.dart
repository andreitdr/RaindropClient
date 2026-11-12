/// Whether the app is on screen, as something the rest of the app can watch.
///
/// This matters far more on a phone than on a desktop. A backgrounded phone
/// app is suspended outright: timers stop, sockets die without their closes
/// being delivered, and none of it is noticed until the app is back. So the
/// things that keep the app current — the event streams above all — have to
/// be told when that happens, rather than discovering it slowly.
///
/// Desktop windows are never suspended this way, so nothing here changes how
/// they behave: the state simply stays `resumed`.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app's current lifecycle state, and every change to it.
///
/// Watch it to rebuild with the state; `ref.listen` it to act on a change.
/// The interesting transition is *to* [AppLifecycleState.resumed], which is
/// when whatever was frozen has to be caught up.
final appLifecycleProvider =
    NotifierProvider<AppLifecycleController, AppLifecycleState>(
      AppLifecycleController.new,
    );

class AppLifecycleController extends Notifier<AppLifecycleState> {
  AppLifecycleListener? _listener;

  @override
  AppLifecycleState build() {
    // Flutter's own binding is the source of truth for the current state;
    // before the first change it is null, and an app being built is resumed.
    final listener = AppLifecycleListener(
      onStateChange: (next) => state = next,
    );
    _listener = listener;
    ref.onDispose(listener.dispose);

    return WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
  }

  /// Visible for tests: drives a state change without an OS to do it.
  @visibleForTesting
  void setState(AppLifecycleState next) => state = next;

  /// Visible for tests: whether the OS listener is in place.
  @visibleForTesting
  bool get isListening => _listener != null;
}

/// Whether the app is on screen right now — the state the app is interactive
/// in, as opposed to hidden, paused, or on its way out.
bool isForeground(AppLifecycleState state) =>
    state == AppLifecycleState.resumed;
