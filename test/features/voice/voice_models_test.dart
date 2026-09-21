import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/network/voice_api.dart';
import 'package:raindrop_client/core/storage/app_prefs.dart';
import 'package:raindrop_client/core/theme/theme_controller.dart';
import 'package:raindrop_client/features/channels/models/channel.dart';
import 'package:raindrop_client/features/voice/controllers/member_audio_controller.dart';
import 'package:raindrop_client/features/voice/controllers/voice_roster_controller.dart';
import 'package:raindrop_client/features/voice/controllers/voice_settings_controller.dart';
import 'package:raindrop_client/features/voice/models/member_audio.dart';
import 'package:raindrop_client/features/voice/models/voice_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

VoiceParticipant participant(
  String channelId,
  String userId, {
  int joinedSecond = 0,
  bool serverMute = false,
}) => VoiceParticipant(
  channelId: channelId,
  userId: userId,
  selfMute: false,
  selfDeaf: false,
  serverMute: serverMute,
  suppressed: false,
  connected: true,
  joinedAtUtc: DateTime.utc(2026, 1, 1, 0, 0, joinedSecond),
);

Future<ProviderContainer> containerWithPrefs([
  Map<String, Object> values = const {},
]) async {
  SharedPreferences.setMockInitialValues(values);
  final prefs = AppPrefs(await SharedPreferences.getInstance());
  final container = ProviderContainer(
    overrides: [appPrefsProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('effectiveVolume', () {
    test('scales a member by the output volume', () {
      expect(
        effectiveVolume(
          outputVolume: 0.5,
          member: const MemberAudio(volume: 1.5),
          deafened: false,
        ),
        0.75,
      );
    });

    test('is silent while deafened or locally muted', () {
      expect(
        effectiveVolume(
          outputVolume: 1,
          member: const MemberAudio(),
          deafened: true,
        ),
        0,
      );
      expect(
        effectiveVolume(
          outputVolume: 1,
          member: const MemberAudio(muted: true),
          deafened: false,
        ),
        0,
      );
    });

    test('caps two boosts rather than multiplying them into distortion', () {
      expect(
        effectiveVolume(
          outputVolume: 2,
          member: const MemberAudio(volume: 2),
          deafened: false,
        ),
        2,
      );
    });
  });

  group('VoiceRoster', () {
    const empty = VoiceRoster(
      available: true,
      transport: 'livekit',
      maximumParticipants: 25,
      byChannel: {},
    );

    test('keeps each call in join order', () {
      final roster = empty
          .upsert(participant('a', 'late', joinedSecond: 5))
          .upsert(participant('a', 'early', joinedSecond: 1));
      expect(roster.inChannel('a').map((p) => p.userId), ['early', 'late']);
    });

    test('merges a state change in place', () {
      final roster = empty
          .upsert(participant('a', 'bob'))
          .upsert(participant('a', 'bob', serverMute: true));
      expect(roster.inChannel('a'), hasLength(1));
      expect(roster.inChannel('a').single.serverMute, isTrue);
    });

    test('moves a member who joins another call', () {
      final roster = empty
          .upsert(participant('a', 'bob'))
          .upsert(participant('b', 'bob'));
      expect(roster.inChannel('a'), isEmpty);
      expect(roster.inChannel('b').single.userId, 'bob');
    });

    test('drops a member who left, and a deleted channel', () {
      var roster = empty
          .upsert(participant('a', 'bob'))
          .upsert(participant('a', 'eve'))
          .upsert(participant('b', 'sam'));
      roster = roster.remove('a', 'bob');
      expect(roster.inChannel('a').map((p) => p.userId), ['eve']);
      roster = roster.removeChannel('b');
      expect(roster.byChannel.keys, ['a']);
    });

    test('leaving someone else\'s call changes nothing', () {
      final roster = empty.upsert(participant('a', 'bob'));
      expect(roster.remove('b', 'bob').inChannel('a'), hasLength(1));
    });
  });

  group('VoiceJoinResult.signalUri', () {
    VoiceJoinResult result({String? url, String? path}) => VoiceJoinResult(
      channelId: 'c',
      transport: 'livekit',
      url: url,
      path: path,
      token: 't',
      expiresAtUtc: DateTime.utc(2026),
      you: participant('c', 'me'),
      participants: const [],
    );

    test('goes through the server this client pinned when there is no url', () {
      expect(
        result(
          path: '/api/channels/voice/signal',
        ).signalUri(host: 'chat.example', port: 5001).toString(),
        'wss://chat.example:5001/api/channels/voice/signal',
      );
    });

    test('uses an absolute url when the server gives one', () {
      expect(
        result(
          url: 'wss://media.example',
        ).signalUri(host: 'chat.example', port: 5001).toString(),
        'wss://media.example',
      );
    });
  });

  group('groupByType', () {
    const text = Channel(id: '1', name: 'general', type: ChannelType.text);

    test('shows an empty voice heading only for somebody who can create one', () {
      expect(groupByType([text]).map((c) => c.type), [ChannelType.text]);
      expect(
        groupByType([text], alwaysShowVoice: true).map((c) => c.type),
        [ChannelType.text, ChannelType.voice],
      );
    });
  });

  group('VoiceSettings', () {
    test('round-trips through JSON', () {
      const settings = VoiceSettings(
        outputVolume: 1.25,
        inputDeviceId: 'mic-1',
        noiseSuppression: false,
        selfMute: true,
      );
      final back = VoiceSettings.fromJson(settings.toJson());
      expect(back.outputVolume, 1.25);
      expect(back.inputDeviceId, 'mic-1');
      expect(back.outputDeviceId, isNull);
      expect(back.noiseSuppression, isFalse);
      expect(back.echoCancellation, isTrue);
      expect(back.selfMute, isTrue);
    });

    test('falls back to defaults for missing or malformed values', () {
      final back = VoiceSettings.fromJson({'outputVolume': 'loud', 'selfDeaf': 1});
      expect(back.outputVolume, 1.0);
      expect(back.selfDeaf, isFalse);
    });
  });

  group('mute and deafen', () {
    test('deafening mutes, and undeafening restores the microphone', () async {
      final container = await containerWithPrefs();
      final controller = container.read(voiceSettingsProvider.notifier);

      controller.toggleDeafen();
      expect(container.read(voiceSettingsProvider).selfDeaf, isTrue);
      expect(container.read(voiceSettingsProvider).micOn, isFalse);

      controller.toggleDeafen();
      expect(container.read(voiceSettingsProvider).micOn, isTrue);
    });

    test('a microphone muted before deafening stays muted after', () async {
      final container = await containerWithPrefs();
      final controller = container.read(voiceSettingsProvider.notifier)
        ..toggleMute()
        ..toggleDeafen()
        ..toggleDeafen();
      expect(container.read(voiceSettingsProvider).selfMute, isTrue);
      expect(controller.state.selfDeaf, isFalse);
    });

    test('unmuting while deafened undeafens too', () async {
      final container = await containerWithPrefs();
      container.read(voiceSettingsProvider.notifier)
        ..toggleDeafen()
        ..toggleMute();
      final settings = container.read(voiceSettingsProvider);
      expect(settings.selfDeaf, isFalse);
      expect(settings.micOn, isTrue);
    });

    test('persists across restarts', () async {
      final first = await containerWithPrefs();
      first.read(voiceSettingsProvider.notifier).toggleMute();
      final stored = (await SharedPreferences.getInstance()).getString(
        'voice.settings',
      )!;

      final second = await containerWithPrefs({'voice.settings': stored});
      expect(second.read(voiceSettingsProvider).selfMute, isTrue);
    });
  });

  group('member audio', () {
    test('is kept per server and member, and forgets defaults', () async {
      final container = await containerWithPrefs();
      final audio = container.read(memberAudioProvider.notifier)
        ..setVolume('s1', 'bob', 1.5)
        ..setMuted('s2', 'bob', true);

      expect(audio.of('s1', 'bob').volume, 1.5);
      expect(audio.of('s1', 'bob').muted, isFalse);
      expect(audio.of('s2', 'bob').muted, isTrue);

      audio.setVolume('s1', 'bob', 1.0);
      expect(container.read(memberAudioProvider).keys, ['s2/bob']);
    });
  });
}
