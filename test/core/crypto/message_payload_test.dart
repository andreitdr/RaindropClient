import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:msgpack_dart/msgpack_dart.dart' as msgpack;
import 'package:raindrop_client/core/crypto/message_payload.dart';

/// A version 1 descriptor as older clients wrote it, for the legacy tests.
Map<String, Object?> v1Descriptor(AttachmentDescriptor f) => {
  'i': f.attachmentId,
  'k': f.key,
  'n': f.name,
  'm': f.mimeType,
  's': f.size,
  'h': f.ciphertextSha256,
  'pw': ?f.width,
  'ph': ?f.height,
  if (f.thumbnail case final t?)
    't': {'i': t.attachmentId, 'k': t.key, 'h': t.ciphertextSha256},
};

void main() {
  test('this build writes version 2: 0x02, then protobuf', () {
    final bytes = MessagePayload.text('hi', clientMessageId: 'c').encode();
    expect(bytes.first, 0x02);
    expect(MessagePayload.version, 2);
  });

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
    // A future version is not guessed at, in either encoding.
    expect(
      MessagePayload.tryDecode(Uint8List.fromList([3, 10, 1, 120])),
      isNull,
    );
    expect(
      MessagePayload.tryDecode(
        msgpack.serialize({'v': 2, 't': 'text', 'b': 'x', 'c': 'c', 's': 0}),
      ),
      isNull,
    );
  });

  test(
    'a version 1 (MessagePack) payload still decodes, attestation and all',
    () {
      final bytes = msgpack.serialize({
        'v': 1,
        't': 'text',
        'b': 'from before the switch',
        'c': 'old-1',
        's': 1700000000000,
        'a': Uint8List.fromList(List.filled(64, 5)),
      });
      final decoded = MessagePayload.tryDecode(bytes)!;
      expect(decoded.body, 'from before the switch');
      expect(decoded.clientMessageId, 'old-1');
      expect(decoded.sentAt.millisecondsSinceEpoch, 1700000000000);
      expect(decoded.attestation, List.filled(64, 5));
    },
  );

  test('unknown types are still decoded', () {
    final bytes = msgpack.serialize({
      'v': 1,
      't': 'poll',
      'b': '',
      'c': 'c',
      's': 0,
      'x': {'question': 'lunch?'},
    });
    expect(MessagePayload.tryDecode(bytes)!.type, 'poll');

    final v2 = MessagePayload(
      type: 'poll',
      body: '',
      clientMessageId: 'c',
      sentAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    ).encode();
    expect(MessagePayload.tryDecode(v2)!.type, 'poll');
  });

  AttachmentDescriptor file({
    String id = '0f8fad5b-d9cb-469f-a165-70867728950e',
  }) => AttachmentDescriptor(
    attachmentId: id,
    key: Uint8List.fromList(List.filled(32, 7)),
    name: 'holiday.jpg',
    mimeType: 'image/jpeg',
    size: 123456,
    ciphertextSha256: Uint8List.fromList(List.generate(32, (i) => i)),
    width: 4000,
    height: 3000,
    thumbnail: ThumbnailDescriptor(
      attachmentId: '7c9e6679-7425-40de-944b-e07fc1f90ae7',
      key: Uint8List.fromList(List.filled(32, 9)),
      ciphertextSha256: Uint8List.fromList(List.filled(32, 1)),
    ),
  );

  test('a files payload round-trips its caption and every descriptor', () {
    final payload = MessagePayload.files('look', [
      file(),
    ], clientMessageId: 'local-2');
    final decoded = MessagePayload.tryDecode(payload.encode())!;

    expect(decoded.type, MessagePayload.filesType);
    expect(decoded.body, 'look');
    final f = decoded.files.single;
    expect(f.attachmentId, '0f8fad5b-d9cb-469f-a165-70867728950e');
    expect(f.key, List.filled(32, 7));
    expect(f.name, 'holiday.jpg');
    expect(f.mimeType, 'image/jpeg');
    expect(f.size, 123456);
    expect((f.width, f.height), (4000, 3000));
    expect(f.thumbnail!.attachmentId, '7c9e6679-7425-40de-944b-e07fc1f90ae7');
    expect(decoded.attestsFiles, isTrue);
  });

  test('a version 1 files payload still decodes its descriptors', () {
    final bytes = msgpack.serialize({
      'v': 1,
      't': 'files',
      'b': 'look',
      'c': 'c',
      's': 0,
      'x': {
        'f': [v1Descriptor(file())],
      },
    });
    final f = MessagePayload.tryDecode(bytes)!.files.single;
    expect(f.name, 'holiday.jpg');
    expect(f.thumbnail!.attachmentId, '7c9e6679-7425-40de-944b-e07fc1f90ae7');
  });

  test('a v2 descriptor with a key of the wrong length is left out', () {
    final good = file(id: 'b');
    final bad = AttachmentDescriptor(
      attachmentId: 'a',
      key: Uint8List(16),
      name: 'x',
      mimeType: 'y',
      size: 1,
      ciphertextSha256: Uint8List(32),
    );
    final bytes = MessagePayload.files('', [
      bad,
      good,
    ], clientMessageId: 'c').encode();
    expect(MessagePayload.tryDecode(bytes)!.files.map((f) => f.attachmentId), [
      'b',
    ]);
  });

  test('a descriptor this build cannot read is left out, not guessed at', () {
    final bytes = msgpack.serialize({
      'v': 1,
      't': 'files',
      'b': '',
      'c': 'c',
      's': 0,
      'x': {
        'f': [
          {
            'i': 'a',
            'k': Uint8List(16),
            'n': 'x',
            'm': 'y',
            's': 1,
            'h': Uint8List(32),
          },
          v1Descriptor(file(id: 'b')),
        ],
      },
    });
    expect(MessagePayload.tryDecode(bytes)!.files.map((f) => f.attachmentId), [
      'b',
    ]);
  });

  test('a text payload keeps the v1 attestation bytes', () {
    final payload = MessagePayload.text('hi', clientMessageId: 'c1');
    expect(payload.attestsFiles, isFalse);
    expect(payload.attestedFiles, isEmpty);
  });

  // The same vector RaindropServer.Tests' AttestationWithFilesTests checks
  // against MessageReportService.CanonicalWithFiles, computed independently of
  // both: the v1 fields, a count, then each file's id and ciphertext hash.
  test('the v2 attestation bytes match the server byte for byte', () {
    final payload = MessagePayload(
      type: MessagePayload.filesType,
      body: 'hi',
      clientMessageId: 'c1',
      sentAt: DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true),
      files: [
        AttachmentDescriptor(
          attachmentId: '0F8FAD5B-D9CB-469F-A165-70867728950E',
          key: Uint8List(32),
          name: 'a.png',
          mimeType: 'image/png',
          size: 1,
          ciphertextSha256: Uint8List.fromList(List.generate(32, (i) => i)),
        ),
      ],
    );

    const golden =
        '0000002436663163326433652d346135622d346336642d386537662d3030313132323333343435350000000263310000018bcfe568'
        '000000000566696c6573000000026869000000010000002430663866616435622d643963622d343639662d613136352d37303836'
        '3737323839353065000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f';
    final bytes = payload.attestationBytes(
      '6F1C2D3E-4A5B-4C6D-8E7F-001122334455',
    );
    expect(
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      golden,
    );
    // A thumbnail, when there is one, follows its file in the attested list.
    expect(
      MessagePayload.files('', [
        file(),
      ], clientMessageId: 'c').attestedFiles.map((f) => f.attachmentId),
      [
        '0f8fad5b-d9cb-469f-a165-70867728950e',
        '7c9e6679-7425-40de-944b-e07fc1f90ae7',
      ],
    );
    expect(
      utf8.decode(bytes.sublist(4, 40)),
      '6f1c2d3e-4a5b-4c6d-8e7f-001122334455',
    );
  });
}
