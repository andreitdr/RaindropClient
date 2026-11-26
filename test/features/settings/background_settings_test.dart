import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/platform/app_residency.dart';
import 'package:raindrop_client/core/storage/app_prefs.dart';
import 'package:raindrop_client/core/theme/theme_controller.dart';
import 'package:raindrop_client/core/voice/call_session_host.dart';
import 'package:raindrop_client/features/settings/controllers/background_settings_controller.dart';
import 'package:raindrop_client/features/settings/controllers/residency_binding.dart';
import 'package:raindrop_client/features/settings/models/background_settings.dart';
import 'package:raindrop_client/features/settings/widgets/background_settings_section.dart';
import 'package:raindrop_client/features/settings/widgets/settings_section_label.dart';
import 'package:raindrop_client/features/voice/controllers/voice_call_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A desktop's window, as far as the binding can see it: what it was told,
/// and an icon that can ask for things.
class _FakeResidency implements AppResidency {
  _FakeResidency({this.available = true});

  @override
  final bool available;

  final told = <bool>[];
  final _commands = StreamController<ResidencyCommand>.broadcast();

  @override
  Future<void> setKeepRunningWhenClosed(bool keep) async => told.add(keep);

  @override
  Stream<ResidencyCommand> get commands => _commands.stream;
}

/// A call host that shows the call somewhere the person may turn off.
class _ShowingHost extends InactiveCallSessionHost {
  const _ShowingHost();

  @override
  bool get showsCallOutsideApp => true;
}

Future<ProviderContainer> containerWith({
  Map<String, Object> prefs = const {},
  AppResidency residency = const NoAppResidency(),
  CallSessionHost host = const InactiveCallSessionHost(),
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final container = ProviderContainer(
    overrides: [
      appPrefsProvider.overrideWithValue(
        AppPrefs(await SharedPreferences.getInstance()),
      ),
      appResidencyProvider.overrideWithValue(residency),
      callSessionHostProvider.overrideWithValue(host),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('BackgroundSettings', () {
    test('is on unless the person turned it off', () {
      const settings = BackgroundSettings();
      expect(settings.keepRunningWhenClosed, isTrue);
      expect(settings.showCallOutsideApp, isTrue);
      expect(BackgroundSettings.fromJson(const {}), settings);
    });

    test('reads back what it wrote', () {
      const settings = BackgroundSettings(
        keepRunningWhenClosed: false,
        showCallOutsideApp: false,
      );
      expect(BackgroundSettings.fromJson(settings.toJson()), settings);
    });

    // A damaged or foreign value is not a reason to turn a feature off.
    test('treats a value of the wrong type as the default', () {
      expect(
        BackgroundSettings.fromJson(const {
          'keepRunningWhenClosed': 'no',
          'showCallOutsideApp': 0,
        }),
        const BackgroundSettings(),
      );
    });
  });

  group('backgroundSettingsProvider', () {
    test('remembers a choice across a restart', () async {
      final container = await containerWith();
      container
          .read(backgroundSettingsProvider.notifier)
          .setKeepRunningWhenClosed(false);

      final prefs = container.read(appPrefsProvider);
      final again = ProviderContainer(
        overrides: [appPrefsProvider.overrideWithValue(prefs)],
      );
      addTearDown(again.dispose);

      expect(
        again.read(backgroundSettingsProvider),
        const BackgroundSettings(keepRunningWhenClosed: false),
      );
    });
  });

  group('appResidencyBindingProvider', () {
    test('tells the window the choice at once, and every change', () async {
      final residency = _FakeResidency();
      final container = await containerWith(residency: residency);

      container.read(appResidencyBindingProvider);
      expect(residency.told, [true]);

      final settings = container.read(backgroundSettingsProvider.notifier);
      settings.setKeepRunningWhenClosed(false);
      settings.setShowCallOutsideApp(false);
      settings.setKeepRunningWhenClosed(true);

      // The phone-only choice is not the window's business.
      expect(residency.told, [true, false, true]);
    });

    test('a saved choice reaches the window on startup', () async {
      final residency = _FakeResidency();
      final container = await containerWith(
        residency: residency,
        prefs: {'settings.background': '{"keepRunningWhenClosed":false}'},
      );

      container.read(appResidencyBindingProvider);
      expect(residency.told, [false]);
    });

    test('leaves a platform with no residency alone', () async {
      final residency = _FakeResidency(available: false);
      final container = await containerWith(residency: residency);

      container.read(appResidencyBindingProvider);
      container
          .read(backgroundSettingsProvider.notifier)
          .setKeepRunningWhenClosed(false);

      expect(residency.told, isEmpty);
    });
  });

  group('BackgroundSettingsSection', () {
    Future<void> pump(WidgetTester tester, ProviderContainer container) =>
        tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(body: BackgroundSettingsSection()),
            ),
          ),
        );

    testWidgets('is not drawn where nothing can honour it', (tester) async {
      final container = await tester.runAsync(containerWith);
      await pump(tester, container!);

      expect(find.byType(SettingsSectionLabel), findsNothing);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('offers keeping the app running where it can', (tester) async {
      final container = await tester.runAsync(
        () => containerWith(residency: _FakeResidency()),
      );
      await pump(tester, container!);

      expect(find.byType(SettingsSectionLabel), findsOneWidget);
      expect(find.byType(ListTile), findsOneWidget);

      await tester.tap(find.byType(ListTile));
      await tester.pump();

      expect(
        container.read(backgroundSettingsProvider).keepRunningWhenClosed,
        isFalse,
      );
      expect(find.textContaining('quits Raindrop'), findsOneWidget);
    });

    testWidgets('offers showing the call where the host shows one', (
      tester,
    ) async {
      final container = await tester.runAsync(
        () => containerWith(host: const _ShowingHost()),
      );
      await pump(tester, container!);

      expect(find.byType(ListTile), findsOneWidget);

      await tester.tap(find.byType(ListTile));
      await tester.pump();

      expect(
        container.read(backgroundSettingsProvider).showCallOutsideApp,
        isFalse,
      );
    });
  });
}
