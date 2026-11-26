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
      return answer;
    });
  }

  /// What the platform answers a call with. Only `capture` has an answer.
  Object? answer;

  /// The service telling Dart something, the way `MainActivity` relays it.
  Future<void> say(String method) => messenger.handlePlatformMessage(
    _channel.name,
    _channel.codec.encodeMethodCall(MethodCall(method)),
    (_) {},
  );

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
        'connectedAt': null,
        'micOn': true,
        'deafened': false,
        'reconnecting': false,
        'participants': 0,
        'sharingScreen': false,
        'encrypted': false,
        'concealed': false,
        'showOutsideApp': true,
      });
    });

    // The surface draws its own clock from this, so it has to survive the
    // channel as a plain number.
    test('sends when the call connected as milliseconds', () async {
      final at = DateTime.utc(2026, 11, 26, 9, 30);
      await host.begin(
        CallSessionDescription(
          title: 'In General',
          body: 'A server',
          connectedAt: at,
          micOn: false,
          participants: 3,
        ),
      );

      final sent = activity.calls.single.arguments as Map;
      expect(sent['connectedAt'], at.millisecondsSinceEpoch);
      expect(sent['micOn'], isFalse);
      expect(sent['participants'], 3);
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

    // The capture starts the moment this answers, so the answer is the
    // platform's own: a service that could not take the type must stop it.
    test('asks before capturing the screen, and passes the answer on', () async {
      activity.answer = true;
      expect(await host.setScreenCapture(true), isTrue);
      expect(activity.methods, ['capture']);
      expect(activity.calls.single.arguments, {'capturing': true});

      activity.answer = false;
      expect(await host.setScreenCapture(true), isFalse);
    });

    test('says when the capture has stopped', () async {
      activity.answer = true;
      await host.setScreenCapture(false);

      expect(activity.calls.single.arguments, {'capturing': false});
    });

    test('a capture the platform refuses or cannot answer does not start', () async {
      activity.refuse = true;
      expect(await host.setScreenCapture(true), isFalse);

      // No answer at all — an older build of the activity — is not a yes.
      activity
        ..refuse = false
        ..answer = null;
      expect(await host.setScreenCapture(true), isFalse);
    });

    // The notification's Stop sharing, or the system closing the capture:
    // neither comes through the media library.
    test('hears a capture ended from outside the app', () async {
      var ended = 0;
      final subscription = host.screenCaptureEnded.listen((_) => ended++);
      addTearDown(subscription.cancel);

      await activity.say('captureEnded');
      await activity.say('somethingElse');

      expect(ended, 1);
    });

    // Mute, deafen and hang up from the notification come back by name.
    test('hears the controls pressed outside the app', () async {
      final heard = <CallSessionAction>[];
      final subscription = host.actions.listen(heard.add);
      addTearDown(subscription.cancel);

      Future<void> press(Object? name) => activity.messenger
          .handlePlatformMessage(
            'raindrop/call_session',
            const StandardMethodCodec().encodeMethodCall(
              MethodCall('action', name),
            ),
            (_) {},
          );

      await press('toggleMute');
      await press('leave');
      // A newer native side's control this build does not know is ignored,
      // not guessed at.
      await press('raiseHand');
      await press(null);

      expect(heard, [CallSessionAction.toggleMute, CallSessionAction.leave]);
    });

    // The notification itself is the price of the call running at all; what
    // Settings offers is showing it as a call — the status bar chip and a
    // Live Update — and the choice travels with the call.
    test('offers showing the call prominently as something to turn off', () async {
      expect(host.showsCallOutsideApp, isTrue);

      await host.begin(
        const CallSessionDescription(
          title: 'In General',
          body: 'A server',
          showOutsideApp: false,
        ),
      );
      expect((activity.calls.single.arguments as Map)['showOutsideApp'], false);
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

    // Nothing to arrange is a yes: a desktop shares without asking anybody.
    test('lets a capture go ahead, having nothing to arrange for it', () async {
      const host = InactiveCallSessionHost();

      expect(await host.setScreenCapture(true), isTrue);
      expect(await host.setScreenCapture(false), isTrue);
      expect(await host.screenCaptureEnded.isEmpty, isTrue);
      expect(activity.calls, isEmpty);
    });

    test('has no controls of its own, and nothing to turn off', () async {
      const host = InactiveCallSessionHost();

      expect(await host.actions.isEmpty, isTrue);
      expect(host.showsCallOutsideApp, isFalse);
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

    // Every field is something a surface shows, so a change to any of them
    // has to reach the platform.
    test('a change to anything it shows is a different description', () {
      const base = CallSessionDescription(title: 'In General', body: 'A');
      final variants = [
        CallSessionDescription(
          title: 'In General',
          body: 'A',
          connectedAt: DateTime.utc(2026),
        ),
        const CallSessionDescription(
          title: 'In General',
          body: 'A',
          micOn: false,
        ),
        const CallSessionDescription(
          title: 'In General',
          body: 'A',
          deafened: true,
        ),
        const CallSessionDescription(
          title: 'In General',
          body: 'A',
          reconnecting: true,
        ),
        const CallSessionDescription(
          title: 'In General',
          body: 'A',
          participants: 2,
        ),
        const CallSessionDescription(
          title: 'In General',
          body: 'A',
          sharingScreen: true,
        ),
        const CallSessionDescription(
          title: 'In General',
          body: 'A',
          encrypted: true,
        ),
        const CallSessionDescription(
          title: 'In General',
          body: 'A',
          concealed: true,
        ),
        const CallSessionDescription(
          title: 'In General',
          body: 'A',
          showOutsideApp: false,
        ),
      ];
      for (final variant in variants) {
        expect(variant, isNot(base), reason: '${variant.toMap()}');
      }
    });
  });

  group('CallSessionAction', () {
    test('is found by the name the platform sends', () {
      for (final action in CallSessionAction.values) {
        expect(CallSessionAction.named(action.name), action);
      }
      expect(CallSessionAction.named('raiseHand'), isNull);
      expect(CallSessionAction.named(null), isNull);
    });
  });

  group('DesktopCallSessionHost', () {
    const host = DesktopCallSessionHost();

    // The desktops' shells read the same messages Android's service does,
    // so no platform's side can drift from the others.
    test('sends the call over the same channel as Android', () async {
      await host.begin(
        const CallSessionDescription(title: 'In General', body: 'A server'),
      );
      await host.end();

      expect(activity.methods, ['begin', 'end']);
      expect((activity.calls.first.arguments as Map)['title'], 'In General');
    });

    // A desktop asks nothing of the app before a capture, and has nothing
    // to ask the platform to arrange.
    test('lets a capture go ahead without asking the platform', () async {
      expect(await host.setScreenCapture(true), isTrue);
      expect(activity.calls, isEmpty);
    });

    // The call shows for as long as it lasts: nothing for Settings to offer.
    test('does not offer the call as something to turn off', () {
      expect(host.showsCallOutsideApp, isFalse);
    });
  });

  group('IosCallSessionHost', () {
    const host = IosCallSessionHost();

    test('sends the call over the same channel as the others', () async {
      await host.begin(
        const CallSessionDescription(
          title: 'In General',
          body: 'A server',
          showOutsideApp: false,
        ),
      );
      await host.end();

      expect(activity.methods, ['begin', 'end']);
      // The Live Activity is the person's to turn off, so the choice travels
      // with the call for the platform to honour.
      expect((activity.calls.first.arguments as Map)['showOutsideApp'], false);
    });

    test('offers the Live Activity as something to turn off', () {
      expect(host.showsCallOutsideApp, isTrue);
    });

    // The broadcast extension asks the system itself.
    test('lets a capture go ahead without asking the platform', () async {
      expect(await host.setScreenCapture(true), isTrue);
      expect(activity.calls, isEmpty);
    });
  });

  group('createCallSessionHost', () {
    // Every platform has a host now: Android keeps the call alive and shows
    // it, iOS shows it as a Live Activity, and the desktops show it.
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('keeps Android calls alive through the platform', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(createCallSessionHost(), isA<AndroidCallSessionHost>());
    });

    test('shows an iPhone or iPad call as a Live Activity', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(createCallSessionHost(), isA<IosCallSessionHost>());
    });

    test('shows the call on every desktop', () {
      for (final platform in [
        TargetPlatform.macOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
      ]) {
        debugDefaultTargetPlatformOverride = platform;
        expect(
          createCallSessionHost(),
          isA<DesktopCallSessionHost>(),
          reason: '$platform',
        );
      }
    });
  });
}
