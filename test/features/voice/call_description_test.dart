import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/voice/call_session_host.dart';
import 'package:raindrop_client/core/voice/voice_engine.dart';
import 'package:raindrop_client/features/voice/controllers/voice_call_controller.dart';
import 'package:raindrop_client/features/voice/models/voice_settings.dart';

const _inGeneral = VoiceCallState(
  serverId: 'server',
  channelId: 'general',
  status: VoiceCallStatus.connected,
);

/// [describeCall] with everything a connected call in General would give it,
/// and any one part changed.
CallSessionDescription describe({
  VoiceCallState call = _inGeneral,
  VoiceSettings settings = const VoiceSettings(),
  String? channelName = 'General',
  String? serverName = 'Andrei’s server',
  int participants = 3,
  DateTime? connectedAt,
  bool locked = false,
  bool showOutsideApp = true,
}) => describeCall(
  call: call,
  settings: settings,
  channelName: channelName,
  serverName: serverName,
  participants: participants,
  connectedAt: connectedAt,
  locked: locked,
  showOutsideApp: showOutsideApp,
);

void main() {
  group('describeCall', () {
    test('names the channel and the server, and passes the rest on', () {
      final at = DateTime.utc(2026, 11, 26, 9);
      final description = describe(connectedAt: at);

      expect(description.title, 'In General');
      expect(description.body, 'Andrei’s server');
      expect(description.connectedAt, at);
      expect(description.participants, 3);
      expect(description.micOn, isTrue);
      expect(description.deafened, isFalse);
      expect(description.reconnecting, isFalse);
      expect(description.concealed, isFalse);
      expect(description.showOutsideApp, isTrue);
    });

    // Before the channel list has loaded there is still a call to announce.
    test('says plainly that there is a call before the channel is known', () {
      final description = describe(channelName: null, serverName: null);

      expect(description.title, 'In a voice call');
      expect(description.body, '');
    });

    // The lock is there so that whoever is holding the device learns nothing
    // the owner has not unlocked it for — and the Lock Screen and the notch
    // are exactly where somebody else would look.
    test('names nothing while the app is locked', () {
      final description = describe(locked: true);

      expect(description.title, 'In a voice call');
      expect(description.body, '');
      expect(description.concealed, isTrue);
    });

    test('reads as muted whenever nobody can hear this member', () {
      expect(
        describe(settings: const VoiceSettings(selfMute: true)).micOn,
        isFalse,
      );
      expect(
        describe(settings: const VoiceSettings(selfDeaf: true, selfMute: true))
            .micOn,
        isFalse,
      );
      expect(describe(call: _with(serverMuted: true)).micOn, isFalse);
      expect(describe(call: _with(suppressed: true)).micOn, isFalse);
      expect(describe(call: _with(microphoneFailed: true)).micOn, isFalse);
    });

    test('says when this member is deafened', () {
      expect(
        describe(settings: const VoiceSettings(selfDeaf: true, selfMute: true))
            .deafened,
        isTrue,
      );
    });

    test('says when the call is being put back together', () {
      expect(
        describe(
          call: const VoiceCallState(
            serverId: 'server',
            channelId: 'general',
            status: VoiceCallStatus.reconnecting,
          ),
        ).reconnecting,
        isTrue,
      );
    });

    test('says when the screen is being shared, and the call encrypted', () {
      final description = describe(
        call: _inGeneral.copyWith(
          screenShare: const VoiceScreenShareState.sharing(
            VoiceScreenSource(
              id: '1',
              name: 'Display',
              kind: VoiceScreenSourceKind.screen,
            ),
            withAudio: false,
          ),
          encryption: VoiceEncryption.active,
        ),
      );

      expect(description.sharingScreen, isTrue);
      expect(description.encrypted, isTrue);
    });

    test('carries the person’s choice about showing it outside the app', () {
      expect(describe(showOutsideApp: false).showOutsideApp, isFalse);
    });

    // Nothing in it ticks or reads a clock, so the controller can compare
    // two and send only a real change.
    test('describes the same call the same way every time', () {
      final at = DateTime.utc(2026, 11, 26, 9);
      expect(describe(connectedAt: at), describe(connectedAt: at));
    });
  });
}

VoiceCallState _with({
  bool serverMuted = false,
  bool suppressed = false,
  bool microphoneFailed = false,
}) => _inGeneral.copyWith(
  serverMuted: serverMuted,
  suppressed: suppressed,
  microphoneFailed: microphoneFailed,
);
