import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/network/voice_api.dart';
import 'package:raindrop_client/core/storage/app_prefs.dart';
import 'package:raindrop_client/core/theme/theme_controller.dart';
import 'package:raindrop_client/features/channels/models/channel.dart';
import 'package:raindrop_client/features/voice/controllers/member_media_controller.dart';
import 'package:raindrop_client/features/voice/controllers/voice_roster_controller.dart';
import 'package:raindrop_client/features/voice/controllers/voice_settings_controller.dart';
import 'package:raindrop_client/core/voice/voice_engine.dart';
import 'package:raindrop_client/features/voice/models/member_media.dart';
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
          member: const MemberMedia(volume: 1.5),
          deafened: false,
        ),
        0.75,
      );
    });

    test('is silent while deafened or locally muted', () {
      expect(
        effectiveVolume(
          outputVolume: 1,
          member: const MemberMedia(),
          deafened: true,
        ),
        0,
      );
      expect(
        effectiveVolume(
          outputVolume: 1,
          member: const MemberMedia(muted: true),
          deafened: false,
        ),
        0,
      );
    });

    test('caps two boosts rather than multiplying them into distortion', () {
      expect(
        effectiveVolume(
          outputVolume: 2,
          member: const MemberMedia(volume: 2),
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
        result(path: '/api/channels/voice/signal')
            .signalUri(host: 'chat.example', port: 5001)
            .toString(),
        'wss://chat.example:5001/api/channels/voice/signal',
      );
    });

    test('uses an absolute url when the server gives one', () {
      expect(
        result(url: 'wss://media.example')
            .signalUri(host: 'chat.example', port: 5001)
            .toString(),
        'wss://media.example',
      );
    });
  });

  group('groupByType', () {
    const text = Channel(id: '1', name: 'general', type: ChannelType.text);

    test(
      'shows an empty voice heading only for somebody who can create one',
      () {
        expect(groupByType([text]).map((c) => c.type), [ChannelType.text]);
        expect(groupByType([text], alwaysShowVoice: true).map((c) => c.type), [
          ChannelType.text,
          ChannelType.voice,
        ]);
      },
    );
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
      final back = VoiceSettings.fromJson({
        'outputVolume': 'loud',
        'selfDeaf': 1,
      });
      expect(back.outputVolume, 1.0);
      expect(back.selfDeaf, isFalse);
    });

    // Settings saved by a build without a speakerphone toggle — every
    // desktop build before phones were a target — must not read as
    // "earpiece", which on a phone would be a call nobody can hear.
    test('settings from a build without a speakerphone default to it', () {
      expect(VoiceSettings.fromJson(const {}).speakerphone, isTrue);
      expect(
        VoiceSettings.fromJson(const {'speakerphone': 'yes'}).speakerphone,
        isTrue,
      );
    });

    test('a chosen earpiece survives the round trip', () {
      const settings = VoiceSettings(speakerphone: false);
      expect(VoiceSettings.fromJson(settings.toJson()).speakerphone, isFalse);
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

    test('the speaker is remembered from one call to the next', () async {
      final first = await containerWithPrefs();
      first.read(voiceSettingsProvider.notifier).toggleSpeakerphone();
      expect(first.read(voiceSettingsProvider).speakerphone, isFalse);

      final stored = (await SharedPreferences.getInstance()).getString(
        'voice.settings',
      )!;
      final second = await containerWithPrefs({'voice.settings': stored});
      expect(second.read(voiceSettingsProvider).speakerphone, isFalse);
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

  group('member media', () {
    test('is kept per server and member, and forgets defaults', () async {
      final container = await containerWithPrefs();
      final media = container.read(memberAudioProvider.notifier)
        ..setVolume('s1', 'bob', 1.5)
        ..setMuted('s2', 'bob', true);

      expect(media.of('s1', 'bob').volume, 1.5);
      expect(media.of('s1', 'bob').muted, isFalse);
      expect(media.of('s2', 'bob').muted, isTrue);

      media.setVolume('s1', 'bob', 1.0);
      expect(container.read(memberAudioProvider).keys, ['s2/bob']);
    });

    test('a hidden camera is remembered, and forgotten when shown again', () async {
      final container = await containerWithPrefs();
      final media = container.read(memberAudioProvider.notifier)
        ..setVideoHidden('s1', 'bob', true);

      expect(media.of('s1', 'bob').videoHidden, isTrue);
      expect(media.of('s1', 'carol').videoHidden, isFalse);

      // Hiding a camera is the only non-default thing about bob, so showing it
      // again must drop the row rather than leave a default one behind.
      media.setVideoHidden('s1', 'bob', false);
      expect(container.read(memberAudioProvider), isEmpty);
    });

    test('a hidden camera survives a restart', () async {
      final container = await containerWithPrefs();
      container.read(memberAudioProvider.notifier)
        ..setVideoHidden('s1', 'bob', true)
        ..setVolume('s1', 'bob', 0.5);

      final stored = container.read(appPrefsProvider).memberAudioJson;
      final second = ProviderContainer(
        overrides: [
          appPrefsProvider.overrideWithValue(container.read(appPrefsProvider)),
        ],
      );
      addTearDown(second.dispose);

      expect(stored.containsKey('s1/bob'), isTrue);
      expect(
        second.read(memberAudioProvider.notifier).of('s1', 'bob').videoHidden,
        isTrue,
      );
      expect(
        second.read(memberAudioProvider.notifier).of('s1', 'bob').volume,
        0.5,
      );
    });

    test('a settings blob from before hidden cameras reads as not hidden', () {
      // An older build wrote volume and muted only; it must not read as a
      // member whose camera is hidden.
      final media = MemberMedia.fromJson({'volume': 1.5, 'muted': true});

      expect(media.volume, 1.5);
      expect(media.muted, isTrue);
      expect(media.videoHidden, isFalse);
    });

    test('MemberMedia round-trips through JSON', () {
      const media = MemberMedia(
        volume: 0.25,
        muted: true,
        videoHidden: true,
        screenVolume: 0.4,
      );
      final back = MemberMedia.fromJson(media.toJson());

      expect(back.volume, media.volume);
      expect(back.muted, media.muted);
      expect(back.videoHidden, media.videoHidden);
      expect(back.screenVolume, media.screenVolume);
    });

    test('isDefault accounts for every field', () {
      expect(const MemberMedia().isDefault, isTrue);
      expect(const MemberMedia(volume: 0.5).isDefault, isFalse);
      expect(const MemberMedia(muted: true).isDefault, isFalse);
      expect(const MemberMedia(videoHidden: true).isDefault, isFalse);
      expect(const MemberMedia(screenVolume: 0.5).isDefault, isFalse);
    });

    test('a settings blob from before shares reads its share as sent', () {
      final media = MemberMedia.fromJson({'volume': 0.5, 'videoHidden': true});

      expect(media.screenVolume, 1.0);
      expect(media.videoHidden, isTrue);
    });

    test('a share volume out of range is clamped, and garbage is ignored', () {
      expect(
        MemberMedia.fromJson({'screenVolume': 9}).screenVolume,
        maximumVolume,
      );
      expect(MemberMedia.fromJson({'screenVolume': -1}).screenVolume, 0);
      expect(MemberMedia.fromJson({'screenVolume': 'loud'}).screenVolume, 1.0);
    });

    test("a shared window's sound follows deafen, but not a member's mute", () {
      // Muting somebody mutes their voice; their film has its own slider.
      expect(
        effectiveScreenVolume(
          outputVolume: 1,
          member: const MemberMedia(muted: true, screenVolume: 0.5),
          deafened: false,
        ),
        0.5,
      );
      expect(
        effectiveScreenVolume(
          outputVolume: 1,
          member: const MemberMedia(screenVolume: 0.5),
          deafened: true,
        ),
        0,
      );
      expect(
        effectiveScreenVolume(
          outputVolume: 2,
          member: const MemberMedia(screenVolume: 2),
          deafened: false,
        ),
        maximumVolume,
      );
    });
  });

  group('camera settings', () {
    test('round-trip through JSON, camera choice included', () {
      const settings = VoiceSettings(
        videoDeviceId: 'cam-1',
        videoQuality: VoiceVideoQuality.hd720,
        cameraEffect: VoiceCameraEffect(
          kind: VoiceCameraEffectKind.replace,
          strength: 0.4,
          backgroundPath: '/tmp/beach.png',
        ),
      );

      final back = VoiceSettings.fromJson(settings.toJson());

      expect(back.videoDeviceId, 'cam-1');
      expect(back.videoQuality, VoiceVideoQuality.hd720);
      expect(back.cameraEffect.kind, VoiceCameraEffectKind.replace);
      expect(back.cameraEffect.strength, 0.4);
      expect(back.cameraEffect.backgroundPath, '/tmp/beach.png');
      expect(back.camera, settings.camera);
    });

    test('an unknown quality name falls back rather than throwing', () {
      // By name, never by index: a quality written by a newer build must not
      // silently become a different one here.
      final back = VoiceSettings.fromJson({'videoQuality': 'uhd4320'});

      expect(back.videoQuality, const VoiceSettings().videoQuality);
    });

    test('a malformed camera effect falls back field by field', () {
      final back = VoiceSettings.fromJson({
        'cameraEffect': {'kind': 'hologram', 'strength': 'quite a lot'},
      });

      expect(back.cameraEffect.kind, VoiceCameraEffectKind.none);
      expect(back.cameraEffect.strength, const VoiceCameraEffect().strength);
      expect(back.cameraEffect.backgroundPath, isNull);
    });

    test('a replaced background with no picture applies nothing', () {
      // Showing somebody their real room when they asked for a background is
      // worse than not applying the effect.
      const chosen = VoiceCameraEffect(kind: VoiceCameraEffectKind.replace);

      expect(
        chosen.effective(effectsAvailable: true),
        VoiceCameraEffectKind.none,
      );
      expect(
        const VoiceCameraEffect(
          kind: VoiceCameraEffectKind.replace,
          backgroundPath: '/tmp/beach.png',
        ).effective(effectsAvailable: true),
        VoiceCameraEffectKind.replace,
      );
    });

    test('no effect is applied where effects cannot run', () {
      const chosen = VoiceCameraEffect(kind: VoiceCameraEffectKind.blur);

      expect(
        chosen.effective(effectsAvailable: false),
        VoiceCameraEffectKind.none,
      );
      expect(
        chosen.effective(effectsAvailable: true),
        VoiceCameraEffectKind.blur,
      );
    });

    test('only a different camera or quality needs the track restarted', () {
      const camera = VoiceCameraOptions(deviceId: 'cam-1');

      // Swapping the effect is a processor on the frames, not a property of the
      // capture, so other participants should see no freeze.
      expect(
        camera.needsRestartFor(
          camera.copyWith(
            effect: const VoiceCameraEffect(kind: VoiceCameraEffectKind.blur),
          ),
        ),
        isFalse,
      );
      expect(
        camera.needsRestartFor(camera.copyWith(deviceId: () => 'cam-2')),
        isTrue,
      );
      expect(
        camera.needsRestartFor(
          camera.copyWith(quality: VoiceVideoQuality.hd720),
        ),
        isTrue,
      );
    });
  });

  group('publish rights', () {
    test('the two sources are independent, and compare by value', () {
      // A single "may publish" bool cannot tell a server mute from a camera
      // that is not allowed, which is why this type exists at all.
      const muted = VoicePublishRights(microphone: false, camera: true);
      const silent = VoicePublishRights(microphone: true, camera: false);

      expect(muted, isNot(silent));
      expect(muted, const VoicePublishRights(microphone: false, camera: true));
      expect(VoicePublishRights.none.microphone, isFalse);
      expect(VoicePublishRights.none.camera, isFalse);
    });
  });
}
