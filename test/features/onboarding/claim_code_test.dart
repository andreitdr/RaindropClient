// A claim code from a server's owner: read forgivingly, and only when it is
// one.
import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/features/onboarding/models/claim_code.dart';

void main() {
  const id = '0f8fad5b-d9cb-469f-a165-70867728950e';
  const secret = '0123456789abcdef0123456789abcdef';

  test('names the account it hands over', () {
    final claim = ClaimCode.tryParse('RDC1-$id-$secret')!;
    expect(claim.accountId, id);
    expect(claim.text, 'rdc1-$id-$secret');
  });

  test('forgives case and the spaces a copy or a line break adds', () {
    final claim = ClaimCode.tryParse('  rdc1-${id.toUpperCase()}-\n${secret.toUpperCase()} ');
    expect(claim?.accountId, id);
  });

  test('is nothing else', () {
    expect(ClaimCode.tryParse('RDC1-$id-0123'), isNull);
    expect(ClaimCode.tryParse('RDC2-$id-$secret'), isNull);
    expect(ClaimCode.tryParse('RDP1-abc-def'), isNull);
    expect(ClaimCode.tryParse(''), isNull);
  });
}
