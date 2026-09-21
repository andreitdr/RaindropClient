import '../../../core/network/members_api.dart' as api;

/// Whether a member is around right now — as opposed to a user's *state*
/// (`active`, `left_preserved`, `erased`), which is whether they are a member
/// at all.
///
/// Declared in the order the roster shows them, and sorted on that
/// declaration order rather than on a separate ranking. The server does the
/// same, and documents that presence is never persisted, so a new status is
/// added by inserting a value in its rightful place here — between [online]
/// and [offline] for anything meaning "around, but not at the keyboard".
enum PresenceStatus {
  online(api.PresenceStatusNames.online, 'Online'),
  offline(api.PresenceStatusNames.offline, 'Offline');

  const PresenceStatus(this.wireName, this.label);

  /// The name the server uses. Never sent — presence is observed, not set —
  /// so this is only ever read.
  final String wireName;

  /// The section heading this status is shown under.
  final String label;

  /// A status this build has never heard of resolves to [offline]: it is the
  /// one bucket that claims nothing about somebody, which is the honest
  /// answer when the client cannot say what the server meant.
  static PresenceStatus parse(String? wireName) => values.firstWhere(
    (status) => status.wireName == wireName,
    orElse: () => PresenceStatus.offline,
  );
}

/// One member of a server, as the roster renders them.
class Member {
  const Member({
    required this.id,
    required this.username,
    required this.presence,
  });

  final String id;
  final String username;
  final PresenceStatus presence;

  factory Member.fromSummary(api.MemberSummary summary) => Member(
    id: summary.userId,
    username: summary.username,
    presence: PresenceStatus.parse(summary.presence),
  );
}

/// One heading's worth of the roster.
class MemberGroup {
  const MemberGroup({required this.status, required this.members});

  final PresenceStatus status;
  final List<Member> members;
}

/// Splits the roster into its sections: statuses in [PresenceStatus]
/// declaration order, and within each, members by username alphabetically
/// and case-insensitively — so `Zoe` sorts next to `alice`, not after every
/// lower-cased name. Empty sections are dropped.
///
/// Done here rather than trusted from the server because the grouping is
/// what the pane renders, and a list that merely arrived in the right order
/// is one refactor away from arriving in the wrong one.
List<MemberGroup> groupByPresence(List<Member> members) {
  return [
    for (final status in PresenceStatus.values)
      if (members.any((m) => m.presence == status))
        MemberGroup(
          status: status,
          members: members.where((m) => m.presence == status).toList()
            ..sort(
              (a, b) =>
                  a.username.toLowerCase().compareTo(b.username.toLowerCase()),
            ),
        ),
  ];
}
