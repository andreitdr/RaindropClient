import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/features/chat/models/message.dart';

ChatMessage message({
  String id = 'm1',
  String authorId = 'alice',
  String? content = 'hello',
  bool deleted = false,
  MessageStatus status = MessageStatus.sent,
  DateTime? sentAt,
}) => ChatMessage(
  id: id,
  authorId: authorId,
  content: deleted ? null : content,
  sentAt: sentAt ?? DateTime.utc(2026, 1, 1),
  deleted: deleted,
  status: status,
);

void main() {
  group('canDeleteMessage', () {
    test('your own message is deletable with no permissions at all', () {
      expect(
        canDeleteMessage(
          message(authorId: 'alice'),
          currentUserId: 'alice',
          canManageMessages: false,
        ),
        isTrue,
      );
    });

    test("somebody else's needs manage_messages", () {
      final theirs = message(authorId: 'bob');
      expect(
        canDeleteMessage(
          theirs,
          currentUserId: 'alice',
          canManageMessages: false,
        ),
        isFalse,
      );
      expect(
        canDeleteMessage(
          theirs,
          currentUserId: 'alice',
          canManageMessages: true,
        ),
        isTrue,
      );
    });

    test('a moderator can still delete their own', () {
      expect(
        canDeleteMessage(
          message(authorId: 'alice'),
          currentUserId: 'alice',
          canManageMessages: true,
        ),
        isTrue,
      );
    });

    test('an unknown current user gets only what manage_messages gives', () {
      final theirs = message(authorId: 'bob');
      expect(
        canDeleteMessage(theirs, currentUserId: null, canManageMessages: false),
        isFalse,
      );
      expect(
        canDeleteMessage(theirs, currentUserId: null, canManageMessages: true),
        isTrue,
      );
    });

    test('nothing to delete on a tombstone or an unsent message', () {
      for (final m in [
        message(deleted: true),
        message(status: MessageStatus.sending),
        message(status: MessageStatus.failed),
      ]) {
        expect(
          canDeleteMessage(m, currentUserId: 'alice', canManageMessages: true),
          isFalse,
        );
      }
    });
  });

  group('mergeMessages', () {
    test('replaces a known id and sorts by time then id', () {
      final merged = mergeMessages(
        [
          message(id: 'b', sentAt: DateTime.utc(2026, 1, 2)),
          message(id: 'a', sentAt: DateTime.utc(2026, 1, 1)),
        ],
        [message(id: 'b', content: 'edited', sentAt: DateTime.utc(2026, 1, 2))],
      );
      expect(merged.map((m) => m.id), ['a', 'b']);
      expect(merged.last.content, 'edited');
    });

    test('a tombstone replaces the readable copy', () {
      final merged = mergeMessages([message()], [message(deleted: true)]);
      expect(merged.single.deleted, isTrue);
      expect(merged.single.content, isNull);
    });

    test('a readable copy never overwrites a tombstone', () {
      // A re-read that began before the delete and finished after it.
      final merged = mergeMessages([message(deleted: true)], [message()]);
      expect(merged.single.deleted, isTrue);
      expect(merged.single.content, isNull);
    });
  });
}
