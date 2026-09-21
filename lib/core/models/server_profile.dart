/// A server the user has connected to, stored locally. Raindrop is
/// decentralised — there is no central directory — so this is entirely
/// client-side bookkeeping: which servers exist, and which GUID/fingerprint
/// belongs to each. [id] is a locally generated key, independent of the
/// account UUID, so the same server can be re-added if it's ever removed.
class ServerProfile {
  const ServerProfile({
    required this.id,
    required this.host,
    required this.port,
    required this.displayName,
  });

  final String id;
  final String host;
  final int port;
  final String displayName;

  ServerProfile copyWith({String? displayName}) => ServerProfile(
    id: id,
    host: host,
    port: port,
    displayName: displayName ?? this.displayName,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'host': host,
    'port': port,
    'displayName': displayName,
  };

  factory ServerProfile.fromJson(Map<String, dynamic> j) => ServerProfile(
    id: j['id'] as String,
    host: j['host'] as String,
    port: j['port'] as int,
    displayName: j['displayName'] as String,
  );

  @override
  bool operator ==(Object other) => other is ServerProfile && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
