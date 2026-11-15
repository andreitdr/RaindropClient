import 'dart:convert';
import 'dart:typed_data';

import '../../../core/storage/identity_store.dart';
import '../models/vault.dart';

/// What a new device shows for one of the person's paired devices to scan or
/// type: the relay's id for the pairing, and a commitment to the offer the
/// new device made, so a relay that swapped in an offer of its own is caught.
///
/// Written `RDP1-<pairing id>-<commitment in base32>`; parsing forgives case,
/// spaces and line breaks, because half the time it is typed by hand.
class PairingCode {
  const PairingCode({required this.pairingId, required this.commitment});

  final String pairingId;
  final Uint8List commitment;

  static const _prefix = 'RDP1';
  static const _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  @override
  String toString() => '$_prefix-$pairingId-${_base32(commitment)}';

  static PairingCode? tryParse(String text) {
    final parts = text.toUpperCase().replaceAll(RegExp(r'\s'), '').split('-');
    if (parts.length != 3 || parts[0] != _prefix || parts[1].isEmpty) {
      return null;
    }
    final commitment = _unbase32(parts[2]);
    if (commitment == null || commitment.length != 16) return null;
    return PairingCode(pairingId: parts[1], commitment: commitment);
  }

  static String _base32(Uint8List bytes) {
    final out = StringBuffer();
    var buffer = 0, bits = 0;
    for (final byte in bytes) {
      buffer = (buffer << 8) | byte;
      bits += 8;
      while (bits >= 5) {
        out.write(_alphabet[(buffer >> (bits - 5)) & 31]);
        bits -= 5;
      }
    }
    if (bits > 0) out.write(_alphabet[(buffer << (5 - bits)) & 31]);
    return out.toString();
  }

  static Uint8List? _unbase32(String text) {
    final out = <int>[];
    var buffer = 0, bits = 0;
    for (final unit in text.codeUnits) {
      final value = _alphabet.indexOf(String.fromCharCode(unit));
      if (value < 0) return null;
      buffer = ((buffer << 5) | value) & 0xffffffff;
      bits += 5;
      if (bits >= 8) {
        out.add((buffer >> (bits - 8)) & 0xff);
        bits -= 8;
      }
    }
    return Uint8List.fromList(out);
  }
}

/// What a paired device hands a new one, sealed to it: the person's whole
/// identity and the vault as that device knows it. This is the only thing
/// that ever carries the authenticator's secret between devices.
class PairingPayload {
  const PairingPayload({required this.identity, required this.vault});

  final ClientIdentity identity;
  final Vault vault;

  Uint8List toBytes() => Uint8List.fromList(
    utf8.encode(
      jsonEncode({
        'v': 1,
        'root': base64.encode(identity.root),
        'recoverySeed': base64.encode(identity.recoverySeed),
        if (identity.authenticatorSecret != null)
          'authenticator': base64.encode(identity.authenticatorSecret!),
        'vault': vault.toJson(),
      }),
    ),
  );

  /// Null for bytes that are not a payload this build understands.
  static PairingPayload? tryFromBytes(Uint8List bytes) {
    try {
      final json = jsonDecode(utf8.decode(bytes));
      if (json is! Map || json['v'] != 1) return null;
      final authenticator = json['authenticator'] as String?;
      return PairingPayload(
        identity: ClientIdentity(
          root: base64.decode(json['root'] as String),
          recoverySeed: base64.decode(json['recoverySeed'] as String),
          authenticatorSecret: authenticator == null
              ? null
              : base64.decode(authenticator),
        ),
        vault: Vault.fromJson((json['vault'] as Map).cast<String, dynamic>()),
      );
    } on Object {
      return null;
    }
  }
}
