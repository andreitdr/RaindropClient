import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/crypto/crypto_engine.dart';

void main() {
  final commitment = Uint8List.fromList(List.generate(16, (i) => i * 17));

  test('a link code survives being written out and read back', () {
    final code = DeviceLinkCode(linkId: 'ABCDEFGHJK', commitment: commitment);
    final text = code.toString();
    expect(text, startsWith('RDL1-ABCDEFGHJK-'));

    final parsed = DeviceLinkCode.tryParse(text)!;
    expect(parsed.linkId, 'ABCDEFGHJK');
    expect(parsed.commitment, commitment);
  });

  test('typing is forgiven: case, spaces and line breaks', () {
    final text = DeviceLinkCode(
      linkId: 'ABCDEFGHJK',
      commitment: commitment,
    ).toString();
    final sloppy = ' ${text.toLowerCase().replaceAll('-', ' -\n ')} ';
    expect(DeviceLinkCode.tryParse(sloppy)?.commitment, commitment);
  });

  test('anything else is not a link code', () {
    expect(DeviceLinkCode.tryParse(''), isNull);
    expect(DeviceLinkCode.tryParse('https://example.com'), isNull);
    expect(DeviceLinkCode.tryParse('RDL1-ABC'), isNull);
    // A commitment of the wrong length would weaken what it protects.
    expect(DeviceLinkCode.tryParse('RDL1-ABCDEFGHJK-AAAA'), isNull);
    expect(DeviceLinkCode.tryParse('RDL2-ABCDEFGHJK-${'A' * 26}'), isNull);
  });
}
