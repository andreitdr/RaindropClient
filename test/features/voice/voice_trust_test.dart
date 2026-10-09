/// What a call will and will not vouch for: the volume gate that keeps
/// untrusted audio silent, and the codec list that keeps a camera from ever
/// being sent in the clear.
///
/// Both rules live as top-level functions in `core/voice/voice_engine.dart`
/// precisely so they can be tested here, without a LiveKit `Room` to stand up.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/voice/voice_engine.dart';

void main() {
  group('gatedVolume', () {
    test('passes the wanted volume through when the track is trusted', () {
      expect(
        gatedVolume(volume: 1.5, unencrypted: false, undecryptable: false),
        1.5,
      );
      expect(
        gatedVolume(volume: 0, unencrypted: false, undecryptable: false),
        0,
      );
    });

    test('silences audio that arrived unencrypted', () {
      expect(
        gatedVolume(volume: 2, unencrypted: true, undecryptable: false),
        0,
      );
    });

    test('silences audio that does not decrypt', () {
      expect(
        gatedVolume(volume: 2, unencrypted: false, undecryptable: true),
        0,
      );
    });

    test('silences audio that is both', () {
      expect(gatedVolume(volume: 2, unencrypted: true, undecryptable: true), 0);
    });

    test('does not boost a muted participant back to audible', () {
      // The per-member volume is applied before the gate, so a member muted
      // locally stays silent whatever their trust is.
      expect(
        gatedVolume(volume: 0, unencrypted: false, undecryptable: false),
        0,
      );
    });
  });

  group('isBlockedVideoCodec', () {
    test('blocks AV1, which the frame cryptor silently skips', () {
      expect(isBlockedVideoCodec('av1'), isTrue);
    });

    test('reads the sender spelling and the receiver spelling alike', () {
      // Sending gives a bare codec name; receiving gives a MIME type. Both
      // reach this function, and the case is not guaranteed either way.
      expect(isBlockedVideoCodec('AV1'), isTrue);
      expect(isBlockedVideoCodec('video/AV1'), isTrue);
      expect(isBlockedVideoCodec(' video/av1 '), isTrue);
    });

    test('allows the codecs a call is actually sent as', () {
      for (final codec in ['vp8', 'VP8', 'video/vp8', 'vp9', 'h264']) {
        expect(isBlockedVideoCodec(codec), isFalse, reason: codec);
      }
    });

    test('allows an empty or unknown codec rather than refusing media', () {
      // An empty codec means the publication has not reported one yet, which
      // is not the same as reporting a blocked one. The publication's own
      // encryption state is what catches that case.
      expect(isBlockedVideoCodec(''), isFalse);
      expect(isBlockedVideoCodec('something-new'), isFalse);
    });

    test('blockedVideoCodecs is the whole list', () {
      // A guard on the comment in voice_engine.dart: if this grows, the
      // reason each entry is there needs to be written down with it.
      expect(blockedVideoCodecs, {'av1'});
    });
  });
}
