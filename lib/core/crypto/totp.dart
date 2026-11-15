/// Authenticator codes, computed the way every authenticator app does:
/// RFC 6238 with HMAC-SHA1, a 30-second step and six digits. The server
/// checks the same thing (`RaindropServer/Security/Totp.cs`).
///
/// This device computes codes itself only for its own account's secret, which
/// it holds because it was paired: that is what lets it join a new server, or
/// enrol the authenticator there, without asking the person to type anything.
library;

import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

abstract final class Totp {
  static const stepSeconds = 30;

  /// A new 20-byte secret.
  static Uint8List newSecret() {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(20, (_) => random.nextInt(256)));
  }

  /// The six digits for [at] (now, by default).
  static String code(Uint8List secret, {DateTime? at}) {
    final seconds =
        (at ?? DateTime.now()).toUtc().millisecondsSinceEpoch ~/ 1000;
    final counter = ByteData(8)..setInt64(0, seconds ~/ stepSeconds);
    final mac = Hmac(sha1, secret).convert(counter.buffer.asUint8List()).bytes;

    final offset = mac.last & 0x0f;
    final binary =
        ((mac[offset] & 0x7f) << 24) |
        (mac[offset + 1] << 16) |
        (mac[offset + 2] << 8) |
        mac[offset + 3];
    return (binary % 1000000).toString().padLeft(6, '0');
  }

  /// How long until the code changes: a code about to lapse is worth waiting
  /// out rather than sending.
  static Duration untilNextStep({DateTime? at}) {
    final ms = (at ?? DateTime.now()).toUtc().millisecondsSinceEpoch;
    return Duration(
      milliseconds: stepSeconds * 1000 - ms % (stepSeconds * 1000),
    );
  }

  static const _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  /// RFC 4648 base32 without padding: how an authenticator app is given a
  /// secret by hand.
  static String base32(Uint8List bytes) {
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

  /// The `otpauth://` link an authenticator app scans as a QR code.
  static Uri provisioningUri(Uint8List secret, {String label = 'Raindrop'}) =>
      Uri(
        scheme: 'otpauth',
        host: 'totp',
        path: '/$label',
        queryParameters: {'secret': base32(secret), 'issuer': 'Raindrop'},
      );

  /// Ten one-time backup codes, shaped `XXXX-XXXX-XXXX` from an alphabet with
  /// no look-alike characters: 60 bits each.
  static List<String> newBackupCodes() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    String group() => List.generate(
      4,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
    return List.generate(10, (_) => '${group()}-${group()}-${group()}');
  }
}
