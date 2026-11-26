import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/crypto/crypto_engine.dart';

void main() {
  final commitment = Uint8List.fromList(List.generate(16, (i) => i * 17));
  final codeSecret = Uint8List.fromList(List.generate(16, (i) => 255 - i));

  test('a link code survives being written out and read back', () {
    final code = DeviceLinkCode(
      linkId: 'ABCDEFGHJK',
      commitment: commitment,
      codeSecret: codeSecret,
    );
    final text = code.toString();
    expect(text, startsWith('RDL2-ABCDEFGHJK-'));

    final parsed = DeviceLinkCode.tryParse(text)!;
    expect(parsed.linkId, 'ABCDEFGHJK');
    expect(parsed.commitment, commitment);
    expect(parsed.codeSecret, codeSecret);
  });

  test('typing is forgiven: case, spaces and line breaks', () {
    final text = DeviceLinkCode(
      linkId: 'ABCDEFGHJK',
      commitment: commitment,
      codeSecret: codeSecret,
    ).toString();
    final sloppy = ' ${text.toLowerCase().replaceAll('-', ' -\n ')} ';
    expect(DeviceLinkCode.tryParse(sloppy)?.commitment, commitment);
    expect(DeviceLinkCode.tryParse(sloppy)?.codeSecret, codeSecret);
  });

  test('anything else is not a link code', () {
    final a = 'A' * 26;
    expect(DeviceLinkCode.tryParse(''), isNull);
    expect(DeviceLinkCode.tryParse('https://example.com'), isNull);
    expect(DeviceLinkCode.tryParse('RDL2-ABC'), isNull);
    // A commitment or code secret of the wrong length would weaken what it
    // protects.
    expect(DeviceLinkCode.tryParse('RDL2-ABCDEFGHJK-AAAA-$a'), isNull);
    expect(DeviceLinkCode.tryParse('RDL2-ABCDEFGHJK-$a-AAAA'), isNull);
    // A code without a code secret, as the first version was, is refused.
    expect(DeviceLinkCode.tryParse('RDL2-ABCDEFGHJK-$a'), isNull);
    expect(DeviceLinkCode.tryParse('RDL1-ABCDEFGHJK-$a'), isNull);
    expect(DeviceLinkCode.tryParse('RDL1-ABCDEFGHJK-$a-$a'), isNull);
  });
}
