import 'dart:convert';
import 'dart:typed_data';

import 'vault.dart';

/// What the platform-synced backup holds (iCloud Keychain, Google Block
/// Store): the identity, and enough of the vault to find the person's
/// servers again.
///
/// - The root and the recovery seed: the identity itself, and what keeps
///   sealing it on servers. Never the authenticator secret — it stays a
///   second factor, exactly as with the recovery words: a device restored
///   from this backup still needs a code, a backup code or the wait.
/// - Servers, with the pins to trust them by. One reachable server is
///   enough (its vault brings the rest), so when the list would not fit,
///   the most recently changed are kept.
///
/// Encoded as a version byte and JSON. [maximumBytes] is Block Store's limit
/// for one entry; iCloud Keychain takes far more, and the same bytes go to
/// both.
class IdentityBackup {
  const IdentityBackup({
    required this.root,
    required this.recoverySeed,
    this.servers = const [],
  });

  static const version = 1;
  static const maximumBytes = 4 * 1024;

  final Uint8List root;
  final Uint8List recoverySeed;
  final List<VaultServer> servers;

  /// The bytes to store, with as many servers as fit in [maximumBytes].
  Uint8List toBytes() {
    final kept = [...servers]
      ..sort((a, b) => b.updatedAtMs.compareTo(a.updatedAtMs));
    while (true) {
      final json = utf8.encode(
        jsonEncode({
          'root': base64.encode(root),
          'seed': base64.encode(recoverySeed),
          'servers': [for (final server in kept) server.toJson()],
        }),
      );
      if (json.length + 1 <= maximumBytes || kept.isEmpty) {
        return Uint8List.fromList([version, ...json]);
      }
      kept.removeLast();
    }
  }

  /// Reads what [toBytes] wrote, or null for anything else — another
  /// version, or something that is not a backup at all.
  static IdentityBackup? tryFromBytes(Uint8List bytes) {
    if (bytes.isEmpty || bytes.first != version) return null;
    try {
      final json =
          jsonDecode(utf8.decode(bytes.sublist(1))) as Map<String, dynamic>;
      final root = base64.decode(json['root'] as String);
      final seed = base64.decode(json['seed'] as String);
      if (root.length != 32 || seed.isEmpty) return null;
      return IdentityBackup(
        root: root,
        recoverySeed: seed,
        servers: [
          for (final server in (json['servers'] as List? ?? const []))
            VaultServer.fromJson((server as Map).cast<String, dynamic>()),
        ],
      );
    } on Object {
      return null;
    }
  }

  /// The servers as a vault, for adding them the way a synced vault is.
  Vault get vault => servers.fold(const Vault(), (v, s) => v.withServer(s));
}
