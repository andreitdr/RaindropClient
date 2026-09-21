import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/features/channels/models/channel_name.dart';

void main() {
  group('validateChannelName', () {
    test('accepts what the server accepts', () {
      for (final name in ['general', 'ab', 'dev-chat', 'v1.2_notes', 'A1']) {
        expect(validateChannelName(name), isNull, reason: name);
      }
    });

    test('judges the trimmed name, like the server', () {
      expect(validateChannelName('  general  '), isNull);
      expect(validateChannelName('   '), isNotNull);
      expect(validateChannelName(null), isNotNull);
      expect(validateChannelName(''), isNotNull);
    });

    test('enforces the length bounds', () {
      expect(validateChannelName('a'), isNotNull);
      expect(validateChannelName('a' * 64), isNull);
      expect(validateChannelName('a' * 65), isNotNull);
    });

    test('rejects characters outside letters, digits and _ . -', () {
      for (final name in ['has space', 'emoji-😀', 'café', 'a/b', '#general']) {
        expect(validateChannelName(name), isNotNull, reason: name);
      }
    });

    test('must start and end alphanumeric', () {
      for (final name in ['-general', 'general-', '_ab', 'ab.', '.ab']) {
        expect(validateChannelName(name), isNotNull, reason: name);
      }
    });
  });
}
