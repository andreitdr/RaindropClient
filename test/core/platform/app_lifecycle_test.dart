import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/platform/app_lifecycle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer container() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  group('appLifecycleProvider', () {
    test('starts on whatever the binding already says', () {
      final c = container();
      expect(c.read(appLifecycleProvider), AppLifecycleState.resumed);
      expect(c.read(appLifecycleProvider.notifier).isListening, isTrue);
    });

    test('reports each change the OS makes', () {
      final c = container();
      final seen = <AppLifecycleState>[];
      c.listen(appLifecycleProvider, (_, next) => seen.add(next));

      final notifier = c.read(appLifecycleProvider.notifier)
        ..setState(AppLifecycleState.inactive)
        ..setState(AppLifecycleState.paused)
        ..setState(AppLifecycleState.resumed);

      expect(seen, [
        AppLifecycleState.inactive,
        AppLifecycleState.paused,
        AppLifecycleState.resumed,
      ]);
      expect(notifier.state, AppLifecycleState.resumed);
    });
  });

  group('isForeground', () {
    // The distinction the event streams act on: only `resumed` means the app
    // is running normally. Everything else is a phone that has suspended it,
    // or is about to.
    test('is true only while the app is actually running', () {
      expect(isForeground(AppLifecycleState.resumed), isTrue);

      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.detached,
      ]) {
        expect(isForeground(state), isFalse, reason: '$state is not on screen');
      }
    });
  });
}
