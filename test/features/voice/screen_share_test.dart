/// The rules a screen share is held to that can be checked without a screen:
/// the box it is fitted inside, the versions it is sent in and what a ceiling
/// does to them, which sources a media-server permission allows, that a whole
/// screen never carries sound, and what the server is told about it.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/network/voice_api.dart';
import 'package:raindrop_client/core/platform/platform_info.dart';
import 'package:raindrop_client/core/voice/voice_engine.dart';
import 'package:raindrop_client/features/voice/controllers/voice_call_controller.dart';
import 'package:raindrop_client/features/voice/controllers/voice_roster_controller.dart';
import 'package:raindrop_client/features/voice/models/voice_settings.dart';
import 'package:raindrop_client/features/voice/widgets/share_quality_selector.dart';
import 'package:raindrop_client/features/voice/widgets/voice_screen_share_tile.dart';

const p480 = VoiceShareResolution.p480;
const p720 = VoiceShareResolution.p720;
const p1080 = VoiceShareResolution.p1080;
const f15 = VoiceShareFrameRate.f15;
const f24 = VoiceShareFrameRate.f24;
const f30 = VoiceShareFrameRate.f30;
const f60 = VoiceShareFrameRate.f60;

/// The versions [quality] is sent in, as "height@fps", smallest first.
List<String> ladder(VoiceShareQuality quality, {VoiceShareLimit? limit}) => [
  for (final layer in shareLadder(
    resolveShareQuality(quality, limit: limit ?? VoiceShareLimit.none),
  ))
    '${layer.resolution.height}@${layer.frameRate}',
];

/// The sizes a [width]×[height] source goes out at, one per version.
List<(int, int)> sizes(VoiceShareQuality quality, int width, int height) {
  final layers = shareLadder(resolveShareQuality(quality));
  final scales = shareLayerScales(layers, width: width, height: height);
  return [
    for (final scale in scales)
      ((width / scale).round(), (height / scale).round()),
  ];
}

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

  group('resolveShareQuality', () {
    test('automatic aims for 1080p at thirty, not the most there is', () {
      final resolved = resolveShareQuality(const VoiceShareQuality.auto());

      expect(resolved.resolution, p1080);
      expect(resolved.frameRate, f30);
      expect(resolved.auto, isTrue);
    });

    test('a picked maximum is what it says, sixty included', () {
      final resolved = resolveShareQuality(
        const VoiceShareQuality.fixed(p1080, f60),
      );

      expect(resolved, const ResolvedShareQuality(p1080, f60, auto: false));
    });

    test('a limit brings a choice down, each half on its own', () {
      const limit = VoiceShareLimit(resolution: p720, frameRate: f30);

      expect(
        resolveShareQuality(
          const VoiceShareQuality.fixed(p1080, f60),
          limit: limit,
        ),
        const ResolvedShareQuality(p720, f30, auto: false),
      );
      // Already under the size; only the rate is over.
      expect(
        resolveShareQuality(
          const VoiceShareQuality.fixed(p480, f60),
          limit: limit,
        ),
        const ResolvedShareQuality(p480, f30, auto: false),
      );
    });

    test('a limit never raises anything, automatic included', () {
      expect(
        resolveShareQuality(
          const VoiceShareQuality.fixed(p480, f15),
          limit: VoiceShareLimit.none,
        ),
        const ResolvedShareQuality(p480, f15, auto: false),
      );
      expect(
        resolveShareQuality(const VoiceShareQuality.auto()).frameRate,
        f30,
      );
    });

    test('automatic under a limit is still automatic, only lower', () {
      final resolved = resolveShareQuality(
        const VoiceShareQuality.auto(),
        limit: const VoiceShareLimit(resolution: p720, frameRate: f24),
      );

      expect(resolved, const ResolvedShareQuality(p720, f24, auto: true));
    });
  });

  group('VoiceShareLimit', () {
    test('nothing stated is no limit', () {
      expect(VoiceShareLimit.of(), VoiceShareLimit.none);
      expect(VoiceShareLimit.of(height: 0, frameRate: 0), VoiceShareLimit.none);
      expect(VoiceShareLimit.of(height: -1), VoiceShareLimit.none);
    });

    test('reads the steps a server names', () {
      expect(
        VoiceShareLimit.of(height: 720, frameRate: 30),
        const VoiceShareLimit(resolution: p720, frameRate: f30),
      );
    });

    // A newer server could name a step this build has never heard of.
    test('a number between two steps allows the one below it', () {
      expect(VoiceShareLimit.of(height: 900).resolution, p720);
      expect(VoiceShareLimit.of(frameRate: 50).frameRate, f30);
      expect(VoiceShareLimit.of(height: 2160).resolution, p1080);
    });

    test('a limit under the smallest step still leaves a share possible', () {
      expect(VoiceShareLimit.of(height: 240).resolution, p480);
      expect(VoiceShareLimit.of(frameRate: 5).frameRate, f15);
    });

    test('two limits together are the lower of each', () {
      const server = VoiceShareLimit(resolution: p720, frameRate: f60);
      const device = VoiceShareLimit(resolution: p1080, frameRate: f30);

      expect(
        server.and(device),
        const VoiceShareLimit(resolution: p720, frameRate: f30),
      );
      expect(server.and(device), device.and(server));
    });

    test('says which choices it leaves', () {
      const limit = VoiceShareLimit(resolution: p720, frameRate: f30);

      expect(limit.allowsResolution(p480), isTrue);
      expect(limit.allowsResolution(p720), isTrue);
      expect(limit.allowsResolution(p1080), isFalse);
      expect(limit.allowsFrameRate(f30), isTrue);
      expect(limit.allowsFrameRate(f60), isFalse);
    });
  });

  group('shareLadder', () {
    test('ends on the ceiling, with smaller versions under it', () {
      expect(ladder(const VoiceShareQuality.auto()), [
        '360@15',
        '720@30',
        '1080@30',
      ]);
      expect(ladder(const VoiceShareQuality.fixed(p720, f24)), [
        '240@15',
        '480@24',
        '720@24',
      ]);
      expect(ladder(const VoiceShareQuality.fixed(p480, f15)), [
        '240@15',
        '360@15',
        '480@15',
      ]);
    });

    // Somebody who can only receive a smaller version is on a connection
    // that sixty frames of it would not fit down either.
    test('only the top version runs at sixty', () {
      expect(ladder(const VoiceShareQuality.fixed(p1080, f60)), [
        '360@15',
        '720@30',
        '1080@60',
      ]);
    });

    // The count is fixed when a share is published; a ladder whose length
    // depended on the ceiling could not be changed under a running share.
    test('is three versions long whatever the ceiling', () {
      for (final resolution in VoiceShareResolution.values) {
        for (final rate in VoiceShareFrameRate.values) {
          final layers = shareLadder(
            resolveShareQuality(VoiceShareQuality.fixed(resolution, rate)),
          );
          expect(layers, hasLength(3), reason: '$resolution $rate');
        }
      }
    });

    test('every version is smaller and cheaper than the one above it', () {
      for (final resolution in VoiceShareResolution.values) {
        for (final rate in VoiceShareFrameRate.values) {
          final layers = shareLadder(
            resolveShareQuality(VoiceShareQuality.fixed(resolution, rate)),
          );
          for (var i = 1; i < layers.length; i++) {
            final reason = '$resolution $rate, version $i';
            expect(
              layers[i].resolution.height,
              greaterThan(layers[i - 1].resolution.height),
              reason: reason,
            );
            expect(
              layers[i].maxBitrate,
              greaterThan(layers[i - 1].maxBitrate),
              reason: reason,
            );
            expect(
              layers[i].frameRate,
              greaterThanOrEqualTo(layers[i - 1].frameRate),
              reason: reason,
            );
          }
        }
      }
    });

    test('the top spends more for more pixels and for more frames', () {
      expect(shareTopBitrate(p1080, f30), 4000000);
      expect(shareTopBitrate(p1080, f60), 6000000);
      expect(shareTopBitrate(p480, f15), 500000);

      for (final resolution in VoiceShareResolution.values) {
        for (var i = 1; i < VoiceShareFrameRate.values.length; i++) {
          expect(
            shareTopBitrate(resolution, VoiceShareFrameRate.values[i]),
            greaterThan(
              shareTopBitrate(resolution, VoiceShareFrameRate.values[i - 1]),
            ),
          );
        }
      }
    });

    test('a document keeps its sharpness; motion and automatic give a little '
        'of both', () {
      bool keeps(VoiceShareQuality quality) =>
          shareKeepsResolution(resolveShareQuality(quality));

      expect(keeps(const VoiceShareQuality.fixed(p1080, f15)), isTrue);
      expect(keeps(const VoiceShareQuality.fixed(p1080, f30)), isFalse);
      expect(keeps(const VoiceShareQuality.fixed(p480, f60)), isFalse);
      expect(keeps(const VoiceShareQuality.auto()), isFalse);
    });
  });

  group('shareLayersFor', () {
    final three = shareLadder(
      resolveShareQuality(const VoiceShareQuality.auto()),
    );

    test('one version per encoder when there are as many', () {
      expect(shareLayersFor(three, 3), three);
    });

    // The media library opens fewer encoders for a very small source.
    test('fewer encoders still carry the ceiling and the smallest', () {
      expect(shareLayersFor(three, 2), [three.first, three.last]);
      expect(shareLayersFor(three, 1), [three.last]);
    });

    test('nothing to aim is nothing aimed', () {
      expect(shareLayersFor(three, 0), isEmpty);
      expect(shareLayersFor(const [], 3), isEmpty);
    });
  });

  group('shareLayerScales', () {
    test('fits each version inside its own box', () {
      expect(sizes(const VoiceShareQuality.auto(), 3840, 2160), [
        (640, 360),
        (1280, 720),
        (1920, 1080),
      ]);
      expect(sizes(const VoiceShareQuality.fixed(p720, f30), 2560, 1440), [
        (426, 240),
        (853, 480),
        (1280, 720),
      ]);
    });

    test('turns every box for a phone held upright', () {
      expect(sizes(const VoiceShareQuality.auto(), 1080, 2400), [
        (288, 640),
        (576, 1280),
        (864, 1920),
      ]);
    });

    // A 900×600 window fits the 720p box as well as the 1080p one. Sent at
    // the same size twice it would cost an encoder and help nobody.
    test('a small source is still sent in three different sizes', () {
      final sent = sizes(const VoiceShareQuality.auto(), 900, 600);

      expect(sent.last, (900, 600));
      expect(sent[1], (600, 400));
      expect(sent[0], (400, 267));
    });

    test('never scales the top version up', () {
      final layers = shareLadder(
        resolveShareQuality(const VoiceShareQuality.auto()),
      );
      expect(shareLayerScales(layers, width: 640, height: 480).last, 1);
    });

    test('fits other boxes than 1080p', () {
      expect(
        screenShareScale(
          width: 1920,
          height: 1080,
          boxWidth: 854,
          boxHeight: 480,
        ),
        closeTo(2.25, 0.01),
      );
    });
  });

  group('remembering the quality', () {
    test('a picked maximum survives being saved', () {
      const settings = VoiceSettings(
        shareQuality: VoiceShareQuality.fixed(p720, f60),
      );

      expect(
        VoiceSettings.fromJson(settings.toJson()).shareQuality,
        const VoiceShareQuality.fixed(p720, f60),
      );
    });

    test('automatic survives being saved, and is where everybody starts', () {
      expect(const VoiceSettings().shareQuality.isAuto, isTrue);
      expect(
        VoiceSettings.fromJson(const VoiceSettings().toJson()).shareQuality,
        const VoiceShareQuality.auto(),
      );
      // Settings from a build that had no such choice.
      expect(VoiceSettings.fromJson(const {}).shareQuality.isAuto, isTrue);
    });

    test('anything it cannot read is automatic rather than a guess', () {
      for (final saved in <Object?>[
        'p1080',
        42,
        const {'height': 1440, 'fps': 30},
        const {'height': 720, 'fps': 25},
        const {'height': 720},
      ]) {
        expect(
          VoiceShareQuality.fromJson(saved),
          const VoiceShareQuality.auto(),
          reason: '$saved',
        );
      }
    });

    test('names itself for the menu', () {
      expect(const VoiceShareQuality.auto().label, 'Auto');
      expect(const VoiceShareQuality.fixed(p1080, f60).label, '1080p · 60 fps');
    });
  });

  group("the server owner's ceiling", () {
    VoiceRoster rosterOf({int height = 0, int frameRate = 0}) =>
        VoiceRoster.fromStatus(
          VoiceStatus(
            available: true,
            transport: 'livekit',
            maximumParticipants: 25,
            participants: const [],
            maximumScreenShares: 2,
            maximumScreenShareHeight: height,
            maximumScreenShareFrameRate: frameRate,
          ),
        );

    test('reaches the roster as a limit', () {
      expect(
        rosterOf(height: 720, frameRate: 30).shareLimit,
        const VoiceShareLimit(resolution: p720, frameRate: f30),
      );
    });

    // A server from before the setting existed sends zeros.
    test('a server that states none holds a share to nothing new', () {
      expect(rosterOf().shareLimit, VoiceShareLimit.none);
    });

    // What the picker offers and what a share is held to are both this, so
    // they cannot disagree. (They are reached separately — the provider the
    // picker reads watches the call, and the call reading it back is a
    // circle Riverpod refuses.)
    test('is combined with what the platform can send', () {
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      expect(shareLimitFor(null), VoiceShareLimit.none);
      expect(
        shareLimitFor(rosterOf(height: 720, frameRate: 60)),
        const VoiceShareLimit(resolution: p720, frameRate: f60),
      );

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(
        shareLimitFor(rosterOf(height: 720, frameRate: 60)),
        const VoiceShareLimit(resolution: p720, frameRate: f30),
      );
      expect(
        shareLimitFor(null),
        const VoiceShareLimit(resolution: p1080, frameRate: f30),
      );
    });

    test('is kept when the roster changes', () {
      final roster = rosterOf(height: 480, frameRate: 15);

      expect(roster.removeChannel('gone').shareLimit, roster.shareLimit);
    });
  });

  group('what the platform can send', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('every phone and desktop can share', () {
      for (final platform in [
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.macOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
      ]) {
        debugDefaultTargetPlatformOverride = platform;
        expect(canShareScreen, isTrue, reason: '$platform');
      }
    });

    test('a phone shares the whole device; a desktop picks', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(sharesWholeDeviceOnly, isTrue);
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(sharesWholeDeviceOnly, isTrue);
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      expect(sharesWholeDeviceOnly, isFalse);
    });

    // Its screen crosses from a broadcast extension, which cannot keep up
    // with sixty. Offered and never delivered would be worse than not offered.
    test('iOS is held to thirty frames; nothing else is held at all', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(
        VoiceShareLimit.of(frameRate: maximumShareFrameRate),
        const VoiceShareLimit(resolution: p1080, frameRate: f30),
      );

      for (final platform in [
        TargetPlatform.android,
        TargetPlatform.macOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
      ]) {
        debugDefaultTargetPlatformOverride = platform;
        expect(
          VoiceShareLimit.of(frameRate: maximumShareFrameRate),
          VoiceShareLimit.none,
          reason: '$platform',
        );
      }
    });

    test('a phone shares its screen as a screen, never with sound', () {
      final options = VoiceScreenShareOptions(
        source: deviceScreenSource,
        withAudio: true,
      );

      expect(options.withAudio, isFalse);
      expect(screenShareClaimOf(options), (
        on: true,
        kind: VoiceShareKinds.screen,
        audio: false,
      ));
    });
  });

  group('what the sharer is told', () {
    const auto = VoiceShareQuality.auto();

    VoiceShareSendStats sending({
      int width = 1920,
      int height = 1080,
      int frameRate = 30,
      int bitrate = 2100000,
      VoiceShareLimitedBy limitedBy = VoiceShareLimitedBy.nothing,
    }) => VoiceShareSendStats(
      width: width,
      height: height,
      frameRate: frameRate,
      bitrate: bitrate,
      limitedBy: limitedBy,
    );

    test('what is going out, when it is what was asked for', () {
      expect(
        shareSendingDescription(sending(), auto),
        'Auto · sending 1080p · 30 fps · 2.1 Mbit/s',
      );
      expect(
        shareSendingDescription(
          sending(width: 1280, height: 720, frameRate: 60, bitrate: 2900000),
          const VoiceShareQuality.fixed(p720, f60),
        ),
        'Up to 720p · 60 fps · sending 720p · 60 fps · 2.9 Mbit/s',
      );
    });

    test('and what is holding it back, when something is', () {
      String told(VoiceShareLimitedBy by) => shareSendingDescription(
        sending(width: 1280, height: 720, frameRate: 24, limitedBy: by),
        auto,
      );

      expect(told(VoiceShareLimitedBy.network), endsWith('your connection'));
      expect(told(VoiceShareLimitedBy.device), endsWith('this device'));
      expect(told(VoiceShareLimitedBy.viewers), contains('nobody is watching'));
      expect(told(VoiceShareLimitedBy.network), contains('720p · 24 fps'));
    });

    // An upright phone at 1080×1920 is 1080p, like the one lying down.
    test('a size is named by its shorter side', () {
      expect(sending(width: 864, height: 1920).sizeLabel, '864p');
      expect(sending(width: 1080, height: 1920).sizeLabel, '1080p');
      expect(sending().sizeLabel, '1080p');
    });

    test('nothing measured yet, and nobody watching, each say so', () {
      expect(shareSendingDescription(null, auto), 'Auto · starting…');
      expect(
        shareSendingDescription(const VoiceShareSendStats.idle(), auto),
        contains('nothing is being sent'),
      );
      expect(const VoiceShareSendStats.idle().idle, isTrue);
    });

    test('a bitrate is rounded so the line does not flicker', () {
      expect(roundedShareBitrate(2149000), 2100000);
      expect(roundedShareBitrate(2150000), 2200000);
      expect(roundedShareBitrate(0), 0);
    });

    test('the choice is explained as a ceiling, with what caps it', () {
      expect(
        shareQualityExplanation(auto, VoiceShareLimit.none),
        startsWith('Up to 1080p at 30 frames a second'),
      );
      expect(
        shareQualityExplanation(
          const VoiceShareQuality.fixed(p1080, f60),
          const VoiceShareLimit(resolution: p720, frameRate: f30),
        ),
        startsWith('At most 720p at 30 frames a second'),
      );
      expect(shareLimitExplanation(VoiceShareLimit.none), isNull);
      expect(
        shareLimitExplanation(
          const VoiceShareLimit(resolution: p720, frameRate: f30),
        ),
        contains('This server allows'),
      );
    });
  });
}
