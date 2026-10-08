/// The app's view of `raindrop.v1.MemberService` (RaindropProto's
/// `members.proto`). The protocol's message is called `Member`; the `Summary`
/// suffix here keeps it distinct from the UI model in
/// `features/members/models/member.dart`, the same split `ChannelSummary`
/// and `Channel` already use.
library;

import 'grpc/protocol.dart' as pb;
import 'grpc/wire.dart';
import 'raindrop_channel.dart';

/// The names for a member's presence. On the wire it is the enum
/// `raindrop.v1.Presence`; a value added on a newer server than this build
/// reads as `unknown`, which is why [MemberSummary.presence] stays a string
/// until the feature layer resolves it.
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

  factory MemberSummary.fromProto(pb.Member m) => MemberSummary(
    userId: m.userId,
    username: m.username,
    presence: Wire.presence(m.presence),
  );
}

/// `raindrop.v1.MemberService`. One instance per connected server, built on
/// that server's [RaindropChannel].
class MembersApi {
  MembersApi(this._channel)
    : _members = pb.MemberServiceClient(_channel.channel);

  final RaindropChannel _channel;
  final pb.MemberServiceClient _members;

  /// Every active member of the server. Members who have left are not
  /// included, whether their data was preserved or erased.
  ///
  /// The server already orders these by presence and then by username; the
  /// roster sorts again for itself rather than depending on that.
  Future<List<MemberSummary>> list(String token) async {
    final response = await _channel.call(
      (o) => _members.listMembers(pb.ListMembersRequest(), options: o),
      token: token,
    );
    return [for (final m in response.members) MemberSummary.fromProto(m)];
  }
}
