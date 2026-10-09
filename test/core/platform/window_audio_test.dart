/// Whether a window's sound may be shared on Windows, where it is captured
/// with its whole process tree — the rule, and reading the build it needs.
/// Neither touches Windows, so both run anywhere.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/platform/platform_info.dart';
import 'package:raindrop_client/core/platform/windows_processes.dart';

void main() {
  group('windowAudioRefusal', () {
    test("an ordinary app's window can share its sound", () {
      expect(
        windowAudioRefusal(
          windowProcessId: 4100,
          thisProcessId: 900,
          thisProcessAncestors: const [600, 4],
        ),
        isNull,
      );
    });

    test("Raindrop's own window is refused: it would send the call back", () {
      expect(
        windowAudioRefusal(
          windowProcessId: 900,
          thisProcessId: 900,
          thisProcessAncestors: const [600, 4],
        ),
        isNotNull,
      );
    });

    test('a window of a process Raindrop descends from is refused', () {
      // Explorer started Raindrop, so its process tree holds Raindrop and
      // nearly every other app on the desktop.
      expect(
        windowAudioRefusal(
          windowProcessId: 600,
          thisProcessId: 900,
          thisProcessAncestors: const [600, 4],
        ),
        isNotNull,
      );
    });
  });

  group('windowsBuildOf', () {
    test('reads the build Dart reports', () {
      expect(windowsBuildOf('"Windows 10 Pro" 10.0 (Build 22631)'), 22631);
      expect(windowsBuildOf('"Windows 10 Pro" 10.0 (Build 19045)'), 19045);
    });

    test('is null for a string that names none', () {
      expect(windowsBuildOf('Darwin Kernel Version 25.0.0'), isNull);
      expect(windowsBuildOf(''), isNull);
    });

    test('Windows 11 can capture one app, Windows 10 cannot', () {
      expect(22000 >= processLoopbackMinimumBuild, isTrue);
      expect(19045 >= processLoopbackMinimumBuild, isFalse);
    });
  });
}
