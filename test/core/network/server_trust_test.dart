import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/network/grpc/protocol.dart' as pb;
import 'package:raindrop_client/core/network/server_trust.dart';
import 'package:raindrop_client/core/network/users_api.dart';

// Captured from a running RaindropServer's handshake, so this checks the Dart
// verifier against what .NET actually signs.
const _fingerprint =
    'B5:F1:C9:84:E9:BB:01:2C:0F:73:72:A3:50:19:77:14:5C:5A:3D:CD:22:4B:1A:7B:98:4E:FA:D0:9F:80:79:75';
final _info = pb.GetServerInfoResponse(
  protocolVersion: '2',
  tlsFingerprint: _fingerprint,
  identityKey: base64.decode(
    'BB+JzxqycAN/b7ie4UUbXzC1ctO1eB6KKbgkrs2X+yMrAx2XZvPTPShYsOIIFXi13tmOmkl9v2y6bYze6V1RnDg=',
  ),
  tlsBindingSignature: base64.decode(
    'TVg9ue1EUkZxRsBtpESjjERgZON3aIfoiPHNtI96qBkcYzzNH4r3An1fBchu0vcH9Y+rwj+Y9yu7KjByX8YxkA==',
  ),
  capabilities: ['tls.identity-binding.v1'],
);

const _presented =
    'b5f1c984e9bb012c0f7372a3501977145c5a3dcd224b1a7b984efad09f807975';

void main() {
  final info = ServerInfo.fromProto(_info);

  test('accepts the signature the server made', () {
    expect(
      ServerTrust.verifyTlsBinding(
        publicKey: info.identityKey!,
        fingerprint: info.tlsFingerprint!,
        signature: info.tlsBindingSignature!,
      ),
      isTrue,
    );
    expect(ServerTrust.isConsistent(info, _presented), isTrue);
  });

  test('rejects a certificate the identity key did not sign', () {
    final other = _presented.replaceFirst('b5', 'b6');
    expect(
      ServerTrust.verifyTlsBinding(
        publicKey: info.identityKey!,
        fingerprint: other,
        signature: info.tlsBindingSignature!,
      ),
      isFalse,
    );
    expect(ServerTrust.isConsistent(info, other), isFalse);
  });

  test('rejects a tampered signature', () {
    final sig = Uint8List.fromList(info.tlsBindingSignature!)..[10] ^= 1;
    expect(
      ServerTrust.verifyTlsBinding(
        publicKey: info.identityKey!,
        fingerprint: _presented,
        signature: sig,
      ),
      isFalse,
    );
  });

  test('rejects malformed keys instead of throwing', () {
    expect(
      ServerTrust.verifyTlsBinding(
        publicKey: Uint8List(65)..[0] = 4,
        fingerprint: _presented,
        signature: info.tlsBindingSignature!,
      ),
      isFalse,
    );
    expect(
      ServerTrust.verifyTlsBinding(
        publicKey: base64.decode('AAAA'),
        fingerprint: _presented,
        signature: info.tlsBindingSignature!,
      ),
      isFalse,
    );
  });

  test('a server without identity keys passes on fingerprint alone', () {
    final legacy = ServerInfo.fromProto(
      pb.GetServerInfoResponse(
        protocolVersion: '2',
        tlsFingerprint: _fingerprint,
      ),
    );
    expect(legacy.identityKey, isNull);
    expect(ServerTrust.isConsistent(legacy, _presented), isTrue);
  });
}
