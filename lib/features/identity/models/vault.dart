import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// One server the person is on, as every device of theirs needs to know it:
/// where it is, and the keys to trust it by. The account there is not
/// listed — each device derives it from the root.
class VaultServer {
  const VaultServer({
    required this.host,
    required this.port,
    required this.displayName,
    required this.fingerprint,
    required this.identityKey,
    required this.updatedAtMs,
  });

  final String host;
  final int port;
  final String displayName;

  /// The server's pinned TLS fingerprint and identity key. A device that
  /// learns of a server from the vault trusts these rather than whatever the
  /// address answers with — the same pins the first device made.
  final String fingerprint;
  final Uint8List identityKey;
  final int updatedAtMs;

  String get key => '$host:$port';

  Map<String, dynamic> toJson() => {
    'host': host,
    'port': port,
    'name': displayName,
    'fingerprint': fingerprint,
    'identityKey': base64.encode(identityKey),
    'updatedAt': updatedAtMs,
  };

  factory VaultServer.fromJson(Map<String, dynamic> j) => VaultServer(
    host: j['host'] as String,
    port: j['port'] as int,
    displayName: j['name'] as String,
    fingerprint: j['fingerprint'] as String,
    identityKey: base64.decode(j['identityKey'] as String),
    updatedAtMs: j['updatedAt'] as int,
  );
}

/// One of the person's paired devices, for the device list. Names live here
/// and nowhere else: no server is told what a device is called.
class VaultDevice {
  const VaultDevice({
    required this.installId,
    required this.name,
    required this.platform,
    required this.updatedAtMs,
  });

  final String installId;
  final String name;
  final String platform;
  final int updatedAtMs;

  Map<String, dynamic> toJson() => {
    'id': installId,
    'name': name,
    'platform': platform,
    'updatedAt': updatedAtMs,
  };

  factory VaultDevice.fromJson(Map<String, dynamic> j) => VaultDevice(
    installId: j['id'] as String,
    name: j['name'] as String,
    platform: j['platform'] as String,
    updatedAtMs: j['updatedAt'] as int,
  );
}

/// What follows a person from device to device: the servers they are on and
/// the devices they have paired. Every server they are on holds a copy,
/// sealed under their root, so a device that reaches any one of them learns
/// of all the others.
///
/// It only grows: merging keeps the newer of two entries and never drops
/// one, because two devices editing apart must not lose each other's
/// additions. Removing a server from one device is that device's business
/// (`AppPrefs.hiddenServers`); it is not recorded here.
class Vault {
  const Vault({
    this.servers = const {},
    this.devices = const {},
    this.authenticatorId = '',
    this.authenticatorUpdatedAtMs = 0,
  });

  /// By `host:port`.
  final Map<String, VaultServer> servers;

  /// By install id.
  final Map<String, VaultDevice> devices;

  /// Which authenticator the person has, as a short fingerprint of its
  /// secret ([authenticatorIdOf]) — never the secret, which must not be
  /// anywhere the recovery words can reach. Empty when they have none. It is
  /// how a device learns that the authenticator was replaced or removed on
  /// another one, and so that the secret it holds is no longer the one.
  final String authenticatorId;
  final int authenticatorUpdatedAtMs;

  bool get isEmpty => servers.isEmpty && devices.isEmpty;

  Vault withAuthenticator(String id, int updatedAtMs) => Vault(
    servers: servers,
    devices: devices,
    authenticatorId: id,
    authenticatorUpdatedAtMs: updatedAtMs,
  );

  Vault merge(Vault other) {
    final mergedServers = {...servers};
    for (final entry in other.servers.entries) {
      final mine = mergedServers[entry.key];
      if (mine == null || entry.value.updatedAtMs > mine.updatedAtMs) {
        mergedServers[entry.key] = entry.value;
      }
    }
    final mergedDevices = {...devices};
    for (final entry in other.devices.entries) {
      final mine = mergedDevices[entry.key];
      if (mine == null || entry.value.updatedAtMs > mine.updatedAtMs) {
        mergedDevices[entry.key] = entry.value;
      }
    }
    final theirsIsNewer =
        other.authenticatorUpdatedAtMs > authenticatorUpdatedAtMs;
    return Vault(
      servers: mergedServers,
      devices: mergedDevices,
      authenticatorId: theirsIsNewer ? other.authenticatorId : authenticatorId,
      authenticatorUpdatedAtMs: theirsIsNewer
          ? other.authenticatorUpdatedAtMs
          : authenticatorUpdatedAtMs,
    );
  }

  Vault _with({
    Map<String, VaultServer>? servers,
    Map<String, VaultDevice>? devices,
  }) => Vault(
    servers: servers ?? this.servers,
    devices: devices ?? this.devices,
    authenticatorId: authenticatorId,
    authenticatorUpdatedAtMs: authenticatorUpdatedAtMs,
  );

  Vault withServer(VaultServer server) =>
      _with(servers: {...servers, server.key: server});

  Vault withDevice(VaultDevice device) =>
      _with(devices: {...devices, device.installId: device});

  Map<String, dynamic> toJson() => {
    'v': 1,
    'servers': [
      for (final key in servers.keys.toList()..sort()) servers[key]!.toJson(),
    ],
    'devices': [
      for (final key in devices.keys.toList()..sort()) devices[key]!.toJson(),
    ],
    'authenticator': {
      'id': authenticatorId,
      'updatedAt': authenticatorUpdatedAtMs,
    },
  };

  factory Vault.fromJson(Map<String, dynamic> j) {
    final servers = [
      for (final s in (j['servers'] as List? ?? const []))
        VaultServer.fromJson((s as Map).cast<String, dynamic>()),
    ];
    final devices = [
      for (final d in (j['devices'] as List? ?? const []))
        VaultDevice.fromJson((d as Map).cast<String, dynamic>()),
    ];
    final authenticator = (j['authenticator'] as Map?) ?? const {};
    return Vault(
      servers: {for (final s in servers) s.key: s},
      devices: {for (final d in devices) d.installId: d},
      authenticatorId: authenticator['id'] as String? ?? '',
      authenticatorUpdatedAtMs: authenticator['updatedAt'] as int? ?? 0,
    );
  }

  /// The bytes that are sealed. Entries are written in key order, so two
  /// vaults holding the same things encode the same.
  Uint8List toBytes() => Uint8List.fromList(utf8.encode(jsonEncode(toJson())));

  /// Null for bytes that are not a vault this build understands.
  static Vault? tryFromBytes(Uint8List bytes) {
    try {
      final json = jsonDecode(utf8.decode(bytes));
      if (json is! Map || json['v'] != 1) return null;
      return Vault.fromJson(json.cast<String, dynamic>());
    } on Object {
      return null;
    }
  }

  bool sameAs(Vault other) =>
      jsonEncode(toJson()) == jsonEncode(other.toJson());
}

/// A short fingerprint of an authenticator secret, for [Vault.authenticatorId].
/// One-way, and sixteen hex characters of it: enough to tell two secrets
/// apart, nothing somebody holding the vault can use.
String authenticatorIdOf(Uint8List? secret) => secret == null
    ? ''
    : sha256
          .convert([
            ...utf8.encode('raindrop/authenticator-id/v1\n'),
            ...secret,
          ])
          .toString()
          .substring(0, 16);
