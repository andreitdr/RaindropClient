import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:msgpack_dart/msgpack_dart.dart' as msgpack;
import 'package:raindrop_client/core/crypto/message_payload.dart';

void main() {
  test('a text payload round-trips', () {
    final payload = MessagePayload.text('héllo 👋', clientMessageId: 'local-1');
    final decoded = MessagePayload.tryDecode(payload.encode())!;
    expect(decoded.type, MessagePayload.textType);
    expect(decoded.body, 'héllo 👋');
    expect(decoded.clientMessageId, 'local-1');
    expect(
      decoded.sentAt.millisecondsSinceEpoch,
      payload.sentAt.millisecondsSinceEpoch,
    );
  });

  test('anything else decodes to null rather than throwing', () {
    expect(MessagePayload.tryDecode(Uint8List.fromList([1, 2, 3])), isNull);
    expect(MessagePayload.tryDecode(Uint8List(0)), isNull);
    // A future version is not guessed at.
    expect(
      MessagePayload.tryDecode(
        msgpack.serialize({'v': 2, 't': 'text', 'b': 'x', 'c': 'c', 's': 0}),
      ),
      isNull,
    );
  });

  test('unknown fields in ext survive, unknown types are still decoded', () {
    final bytes = msgpack.serialize({
      'v': 1,
      't': 'poll',
      'b': '',
      'c': 'c',
      's': 0,
      'x': {'question': 'lunch?'},
    });
    final decoded = MessagePayload.tryDecode(bytes)!;
    expect(decoded.type, 'poll');
    expect(decoded.ext['question'], 'lunch?');
  });
}
