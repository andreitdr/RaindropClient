import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/crypto/totp.dart';
import 'package:raindrop_client/core/storage/identity_store.dart';
import 'package:raindrop_client/features/identity/controllers/pairing.dart';
import 'package:raindrop_client/features/identity/models/vault.dart';

Uint8List _fill(int length, int value) =>
    Uint8List(length)..fillRange(0, length, value);

VaultServer _server(String host, {int at = 1, String name = 'Home'}) =>
    VaultServer(
      host: host,
      port: 5001,
      displayName: name,
      fingerprint: 'AA:BB',
      identityKey: _fill(65, 4),
      updatedAtMs: at,
    );

VaultDevice _device(String id, {int at = 1, String name = 'Phone'}) =>
    VaultDevice(installId: id, name: name, platform: 'ios', updatedAtMs: at);

void main() {
  group('authenticator codes', () {
    final secret = Uint8List.fromList(utf8.encode('12345678901234567890'));
    DateTime at(int seconds) =>
        DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);

    test('match RFC 6238, which is what the server checks against', () {
      // The RFC lists eight digits; an authenticator shows the last six.
      expect(Totp.code(secret, at: at(59)), '287082');
      expect(Totp.code(secret, at: at(1111111109)), '081804');
      expect(Totp.code(secret, at: at(1234567890)), '005924');
    });

    test('a key is base32, as authenticator apps take it', () {
      expect(Totp.base32(secret), 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ');
      final uri = Totp.provisioningUri(secret);
      expect(uri.scheme, 'otpauth');
      expect(uri.queryParameters['secret'], Totp.base32(secret));
    });

    test('backup codes are ten, distinct, and long enough for the server', () {
      final codes = Totp.newBackupCodes();
      expect(codes.toSet().length, 10);
      for (final code in codes) {
        expect(code.replaceAll('-', '').length, inInclusiveRange(8, 32));
      }
    });
  });

  group('pairing code', () {
    test('survives being typed back by hand', () {
      final code = PairingCode(
        pairingId: 'ABCDEFGH23',
        commitment: Uint8List.fromList(List.generate(16, (i) => i * 7)),
      );
      final typed = ' ${code.toString().toLowerCase().replaceAll('-', ' - ')}\n';
      final parsed = PairingCode.tryParse(typed.replaceAll(' - ', '-'))!;
      expect(parsed.pairingId, code.pairingId);
      expect(parsed.commitment, code.commitment);
    });

    test('anything else is not one', () {
      expect(PairingCode.tryParse('RDL1-ABC-AAAA'), isNull);
      expect(PairingCode.tryParse('RDP1-ABC-AAAA'), isNull);
      expect(PairingCode.tryParse('hello'), isNull);
    });
  });

  group('vault', () {
    test('merging keeps what either side added, and the newer of each', () {
      final phone = const Vault()
          .withServer(_server('a.example'))
          .withServer(_server('b.example', at: 5, name: 'Renamed'))
          .withDevice(_device('phone'));
      final laptop = const Vault()
          .withServer(_server('b.example', at: 2, name: 'Old name'))
          .withServer(_server('c.example'))
          .withDevice(_device('laptop', name: 'Laptop'));

      final merged = phone.merge(laptop);
      expect(merged.servers.keys, {
        'a.example:5001',
        'b.example:5001',
        'c.example:5001',
      });
      expect(merged.servers['b.example:5001']!.displayName, 'Renamed');
      expect(merged.devices.keys, {'phone', 'laptop'});
      // Whichever way round, the same vault.
      expect(laptop.merge(phone).sameAs(merged), isTrue);
    });

    test('round-trips through the bytes that are sealed', () {
      final vault = const Vault()
          .withServer(_server('a.example'))
          .withDevice(_device('phone'))
          .withAuthenticator('0123456789abcdef', 9);
      final read = Vault.tryFromBytes(vault.toBytes())!;
      expect(read.sameAs(vault), isTrue);
      expect(read.authenticatorId, '0123456789abcdef');
      expect(Vault.tryFromBytes(Uint8List.fromList([1, 2, 3])), isNull);
    });

    test('the newer word on the authenticator wins, removal included', () {
      final enabled = const Vault().withAuthenticator('aaaa', 5);
      final removedLater = const Vault().withAuthenticator('', 9);
      expect(enabled.merge(removedLater).authenticatorId, '');
      expect(removedLater.merge(enabled).authenticatorId, '');
    });

    test('an authenticator is named by a fingerprint, never its secret', () {
      final id = authenticatorIdOf(_fill(20, 7));
      expect(id.length, 16);
      expect(id, isNot(authenticatorIdOf(_fill(20, 8))));
      expect(authenticatorIdOf(null), '');
    });
  });

  test('a pairing payload carries the identity and the vault', () {
    final payload = PairingPayload(
      identity: ClientIdentity(
        root: _fill(32, 1),
        recoverySeed: _fill(32, 2),
        authenticatorSecret: _fill(20, 3),
      ),
      vault: const Vault().withServer(_server('a.example')),
    );
    final read = PairingPayload.tryFromBytes(payload.toBytes())!;
    expect(read.identity.root, payload.identity.root);
    expect(read.identity.recoverySeed, payload.identity.recoverySeed);
    expect(read.identity.authenticatorSecret, _fill(20, 3));
    expect(read.vault.servers.keys, {'a.example:5001'});
    expect(PairingPayload.tryFromBytes(Uint8List(4)), isNull);
  });
}
