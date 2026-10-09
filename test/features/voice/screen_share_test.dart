/// The rules a screen share is held to that can be checked without a screen:
/// the 1080p box, which sources a media-server permission allows, that a
/// whole screen never carries sound, and what the server is told about it.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/network/voice_api.dart';
import 'package:raindrop_client/core/voice/voice_engine.dart';
import 'package:raindrop_client/features/voice/controllers/voice_call_controller.dart';

/// What [screenShareScale] makes of a source, as the size actually sent.
(int, int) sent(int width, int height) {
  final scale = screenShareScale(width: width, height: height);
  return ((width / scale).round(), (height / scale).round());
}

const window = VoiceScreenSource(
  id: '1311',
  name: 'Notes',
  kind: VoiceScreenSourceKind.window,
);

const display = VoiceScreenSource(
  id: '0',
  name: 'Screen 1',
  kind: VoiceScreenSourceKind.screen,
);

void main() {
  group('screenShareScale', () {
    test('fits anything larger inside 1920×1080, keeping its shape', () {
      expect(sent(3840, 2160), (1920, 1080)); // 4K
      expect(sent(5120, 2880), (1920, 1080)); // 5K
      expect(sent(2560, 1440), (1920, 1080)); // 1440p
      expect(sent(2880, 1800), (1728, 1080)); // 16:10 Retina
      expect(sent(1920, 1200), (1728, 1080)); // 16:10, only too tall
    });

    test('fits a wide screen by its width, not by capping its height', () {
      // Capping only the height would send 2580×1080 — 34% more pixels than
      // 1080p, which is the bandwidth the cap exists to save.
      expect(sent(3440, 1440), (1920, 804));
      expect(sent(5120, 1440), (1920, 540));
    });

    test('turns the box for a portrait source', () {
      expect(sent(1080, 1920), (1080, 1920));
      expect(sent(1440, 2560), (1080, 1920));
      expect(sent(2160, 3840), (1080, 1920));
    });

    test('never scales anything up', () {
      expect(screenShareScale(width: 1920, height: 1080), 1);
      expect(screenShareScale(width: 1280, height: 720), 1);
      expect(screenShareScale(width: 800, height: 1000), 1);
      expect(screenShareScale(width: 1, height: 1), 1);
    });

    test('leaves a size it cannot read alone', () {
      expect(screenShareScale(width: 0, height: 1080), 1);
      expect(screenShareScale(width: -1, height: -1), 1);
    });
  });

  group('voicePublishRightsOf', () {
    test('reads each source on its own', () {
      final rights = voicePublishRightsOf(
        canPublish: true,
        sources: [
          MediaSourceNumbers.microphone,
          MediaSourceNumbers.screenShare,
        ],
      );

      expect(rights.microphone, isTrue);
      expect(rights.camera, isFalse);
      expect(rights.screen, isTrue);
      expect(rights.screenAudio, isFalse);
    });

    test('a window with sound is two sources', () {
      final rights = voicePublishRightsOf(
        canPublish: true,
        sources: [
          MediaSourceNumbers.screenShare,
          MediaSourceNumbers.screenShareAudio,
        ],
      );

      expect(
        rights,
        const VoicePublishRights(
          microphone: false,
          camera: false,
          screen: true,
          screenAudio: true,
        ),
      );
    });

    test(
      'an empty list with canPublish is every source, as LiveKit reads it',
      () {
        expect(
          voicePublishRightsOf(canPublish: true, sources: const []),
          const VoicePublishRights(
            microphone: true,
            camera: true,
            screen: true,
            screenAudio: true,
          ),
        );
      },
    );

    test('without canPublish nothing is allowed, whatever the list says', () {
      expect(
        voicePublishRightsOf(
          canPublish: false,
          sources: [
            MediaSourceNumbers.microphone,
            MediaSourceNumbers.screenShare,
          ],
        ),
        VoicePublishRights.none,
      );
    });
  });

  group('VoiceScreenShareOptions', () {
    test('a window keeps the sound its sharer agreed to', () {
      expect(
        VoiceScreenShareOptions(source: window, withAudio: true).withAudio,
        isTrue,
      );
      expect(VoiceScreenShareOptions(source: window).withAudio, isFalse);
    });

    test('a whole screen never carries sound, even when asked', () {
      expect(
        VoiceScreenShareOptions(source: display, withAudio: true).withAudio,
        isFalse,
      );
    });
  });

  group('screenShareClaimOf', () {
    test('names the kind the server expects, and the sound', () {
      expect(
        screenShareClaimOf(
          VoiceScreenShareOptions(source: window, withAudio: true),
        ),
        (on: true, kind: VoiceShareKinds.window, audio: true),
      );
      expect(
        screenShareClaimOf(
          VoiceScreenShareOptions(source: display, withAudio: true),
        ),
        (on: true, kind: VoiceShareKinds.screen, audio: false),
      );
    });

    test('not sharing claims nothing at all', () {
      expect(noScreenShare, (on: false, kind: null, audio: false));
    });
  });
}
