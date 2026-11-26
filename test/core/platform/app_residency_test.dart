import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/platform/app_residency.dart';

const _channel = MethodChannel('raindrop/residency');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    messenger.setMockMethodCallHandler(_channel, (call) async {
      calls.add(call);
      return null;
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(_channel, null));

  /// The menu bar item asking for something, the way `RaindropShell` does.
  Future<void> ask(Object? command) => messenger.handlePlatformMessage(
    _channel.name,
    _channel.codec.encodeMethodCall(MethodCall('command', command)),
    (_) {},
  );

  group('DesktopAppResidency', () {
    const residency = DesktopAppResidency();

    test('is something Settings can offer', () {
      expect(residency.available, isTrue);
    });

    test('tells the window what closing it should do', () async {
      await residency.setKeepRunningWhenClosed(true);
      await residency.setKeepRunningWhenClosed(false);

      expect(calls.map((c) => c.method), ['setKeepRunning', 'setKeepRunning']);
      expect(calls.map((c) => c.arguments), [
        {'keep': true},
        {'keep': false},
      ]);
    });

    // Closing quits, as it always did, when the platform side is missing or
    // refuses: never an exception into the settings that asked.
    test('a platform that cannot answer never reaches the caller', () async {
      messenger.setMockMethodCallHandler(_channel, (_) async {
        throw PlatformException(code: 'error');
      });
      await expectLater(residency.setKeepRunningWhenClosed(true), completes);

      messenger.setMockMethodCallHandler(_channel, null);
      await expectLater(residency.setKeepRunningWhenClosed(true), completes);
    });

    test(
      'hears the menu bar item, and ignores what it does not know',
      () async {
        final heard = <ResidencyCommand>[];
        final subscription = residency.commands.listen(heard.add);
        addTearDown(subscription.cancel);

        await ask('openSettings');
        await ask('somethingNewer');
        await ask(null);

        expect(heard, [ResidencyCommand.openSettings]);
      },
    );
  });

  group('NoAppResidency', () {
    test('offers nothing and does nothing', () async {
      const residency = NoAppResidency();

      expect(residency.available, isFalse);
      await residency.setKeepRunningWhenClosed(true);
      expect(await residency.commands.isEmpty, isTrue);
      expect(calls, isEmpty);
    });
  });

  group('createAppResidency', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('keeps every desktop running behind its icon', () {
      for (final platform in [
        TargetPlatform.macOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
      ]) {
        debugDefaultTargetPlatformOverride = platform;
        expect(
          createAppResidency(),
          isA<DesktopAppResidency>(),
          reason: '$platform',
        );
      }
    });

    // A phone decides for itself what runs in the background.
    test('leaves the phones alone', () {
      for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
        debugDefaultTargetPlatformOverride = platform;
        expect(
          createAppResidency(),
          isA<NoAppResidency>(),
          reason: '$platform',
        );
      }
    });
  });
}
