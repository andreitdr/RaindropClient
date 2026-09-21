/// Dart mirror of the C# records in `RaindropServer/Members/
/// MemberContracts.cs`. The server's record is called `Member`; the
/// `Summary` suffix here keeps the wire shape distinct from the UI model in
/// `features/members/models/member.dart`, the same split `ChannelSummary`
/// and `Channel` already use.
library;

import 'api_client.dart';

/// The wire names for a member's presence. Anything else is a status added
/// to a newer server than this build, which is why [MemberSummary.presence]
/// stays a string until the feature layer resolves it.
abstract final class PresenceStatusNames {
  static const online = 'online';
  static const offline = 'offline';
}

class MemberSummary {
  const MemberSummary({
    required this.userId,
    required this.username,
    required this.presence,
  });

  /// The UUID this member is known by on this server — the same id messages
  /// carry, and how a client tells which row is the signed-in account.
  final String userId;

  final String username;

  /// Where they are right now, as a [PresenceStatusNames] value.
  ///
  /// Deliberately not called "status": a user's `state` elsewhere in this API
  /// is their membership lifecycle (`active`, `left_preserved`, `erased`),
  /// which is a different question.
  final String presence;

  factory MemberSummary.fromJson(Map<String, dynamic> j) => MemberSummary(
    userId: j['userId'] as String,
    username: j['username'] as String,
    presence: j['presence'] as String,
  );
}

/// Typed wrapper over the `/api/members` surface. One instance per connected
/// server, built from that server's [ApiClient].
class MembersApi {
  MembersApi(this._client);

  final ApiClient _client;

  /// Every active member of the server. Members who have left are not
  /// included, whether their data was preserved or erased.
  ///
  /// The server already orders these by presence and then by username; the
  /// roster sorts again for itself rather than depending on that.
  Future<List<MemberSummary>> list(String token) async {
    final body = await _client.get('/api/members', token: token);
    final members = body['members'] as List? ?? const [];
    return [
      for (final m in members)
        MemberSummary.fromJson(Map<String, dynamic>.from(m as Map)),
    ];
  }
}
