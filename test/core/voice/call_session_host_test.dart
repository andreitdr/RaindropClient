import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/voice/call_session_host.dart';

/// Stands in for `MainActivity`'s side of the channel: records what Dart
/// asked for, and can be told to refuse the way a real platform does when the
/// notification permission is denied or the OS will not start a service.
class _FakeActivity {
  _FakeActivity(this.messenger) {
    messenger.setMockMethodCallHandler(_channel, (call) async {
      if (refuse) {
        throw PlatformException(code: 'error', message: 'refused');
      }
      calls.add(call);
      return null;
    });
  }

  static const _channel = MethodChannel('raindrop/call_session');

  final TestDefaultBinaryMessenger messenger;
  final calls = <MethodCall>[];
  bool refuse = false;

  void dispose() => messenger.setMockMethodCallHandler(_channel, null);

  List<String> get methods => calls.map((c) => c.method).toList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeActivity activity;

  setUp(() {
    activity = _FakeActivity(
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger,
    );
    addTearDown(activity.dispose);
  });

  group('AndroidCallSessionHost', () {
    const host = AndroidCallSessionHost();
    const call = CallSessionDescription(
      title: 'In General',
      body: 'Andrei’s server',
    );

    test('sends the call description to the platform', () async {
      await host.begin(call);

      expect(activity.methods, ['begin']);
      expect(activity.calls.single.arguments, {
        'title': 'In General',
        'body': 'Andrei’s server',
      });
    });

    test('ends the session with no arguments to get wrong', () async {
      await host.begin(call);
      await host.end();

      expect(activity.methods, ['begin', 'end']);
      expect(activity.calls.last.arguments, isNull);
    });

    test('renaming a call updates it rather than starting another', () async {
      await host.begin(call);
      await host.update(
        const CallSessionDescription(title: 'In Lobby', body: 'Andrei’s server'),
      );

      expect(activity.methods, ['begin', 'update']);
      expect(
        (activity.calls.last.arguments as Map)['title'],
        'In Lobby',
      );
    });

    // A call the OS refuses to keep alive in the background is still a
    // working call while the app is on screen, so none of this may throw
    // into the join or the hang-up.
    test('a platform refusal never reaches the caller', () async {
      activity.refuse = true;

      await expectLater(host.begin(call), completes);
      await expectLater(host.update(call), completes);
      await expectLater(host.end(), completes);
    });
  });

  group('InactiveCallSessionHost', () {
    test('does nothing at all, in any order', () async {
      const host = InactiveCallSessionHost();

      await host.end();
      await host.begin(
        const CallSessionDescription(title: 'In General', body: 'A server'),
      );
      await host.end();
      await host.end();

      expect(activity.calls, isEmpty);
    });
  });

  group('CallSessionDescription', () {
    test('compares by what it says, so an unchanged call is not re-sent', () {
      const a = CallSessionDescription(title: 'In General', body: 'A server');
      const b = CallSessionDescription(title: 'In General', body: 'A server');
      const c = CallSessionDescription(title: 'In Lobby', body: 'A server');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('createCallSessionHost', () {
    // Android is the one platform that needs to be told about a call at
    // runtime; everywhere else the static configuration (iOS) or the OS
    // itself (desktop) covers it.
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('keeps Android calls alive through the platform', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(createCallSessionHost(), isA<AndroidCallSessionHost>());
    });

    test('is inactive everywhere else', () {
      for (final platform in [
        TargetPlatform.iOS,
        TargetPlatform.macOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
      ]) {
        debugDefaultTargetPlatformOverride = platform;
        expect(
          createCallSessionHost(),
          isA<InactiveCallSessionHost>(),
          reason: '$platform needs no runtime call session',
        );
      }
    });
  });
}
