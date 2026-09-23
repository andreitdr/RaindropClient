import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/adaptive.dart';
import '../../../core/widgets/panel.dart';
import '../controllers/members_controller.dart';
import '../models/member.dart';

/// The rightmost pane: everyone on this server, grouped by presence and
/// alphabetical within each group.
///
/// [currentUserId] is the caller's UUID, which is how the signed-in account
/// is marked — the roster is the same list for everybody, so the "you" is
/// found rather than passed in separately.
class MemberList extends ConsumerWidget {
  const MemberList({
    super.key,
    required this.serverId,
    required this.currentUserId,
    this.width = 240,
  });

  final String serverId;
  final String currentUserId;

  /// Set by the layout.
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(membersProvider(serverId));

    return SizedBox(
      width: width,
      child: Panel(
        color: context.surfaces.sidebar,
        child: SafeArea(
          left: false,
          right: false,
          child: membersAsync.when(
            loading: () => const Center(child: AdaptiveActivityIndicator()),
            error: (err, _) => _RosterError(
              error: err,
              onRetry: () =>
                  ref.read(membersProvider(serverId).notifier).refresh(),
            ),
            data: (members) => _Roster(
              groups: groupByPresence(members),
              currentUserId: currentUserId,
            ),
          ),
        ),
      ),
    );
  }
}

class _Roster extends StatelessWidget {
  const _Roster({required this.groups, required this.currentUserId});

  final List<MemberGroup> groups;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No members yet.'),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        for (final group in groups) ...[
          _GroupHeading(status: group.status, count: group.members.length),
          for (final member in group.members)
            _MemberTile(
              member: member,
              isCurrentUser: member.id == currentUserId,
            ),
        ],
      ],
    );
  }
}

class _GroupHeading extends StatelessWidget {
  const _GroupHeading({required this.status, required this.count});

  final PresenceStatus status;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        '${status.label.toUpperCase()} — $count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, required this.isCurrentUser});

  final Member member;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Offline members are dimmed rather than hidden, which is what makes the
    // two groups readable at a glance without a second colour in the theme.
    final offline = member.presence == PresenceStatus.offline;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        children: [
          _Avatar(member: member, dimmed: offline),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              member.username,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: offline
                    ? scheme.onSurfaceVariant.withValues(alpha: 0.7)
                    : scheme.onSurface,
              ),
            ),
          ),
          if (isCurrentUser)
            Text(
              'you',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.member, required this.dimmed});

  final Member member;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: dimmed
              ? scheme.primary.withValues(alpha: 0.4)
              : scheme.primary,
          child: Text(
            member.username.characters.first.toUpperCase(),
            style: TextStyle(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _dotColor(context, member.presence),
              shape: BoxShape.circle,
              border: Border.all(color: context.surfaces.sidebar, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  /// Online has a themed colour of its own (`AppSurfaces.onlineIndicator`);
  /// every other status reads as "not here" and borrows a muted foreground
  /// rather than adding a colour every theme file would have to define.
  static Color _dotColor(BuildContext context, PresenceStatus status) =>
      switch (status) {
        PresenceStatus.online => context.surfaces.onlineIndicator,
        PresenceStatus.offline => Theme.of(
          context,
        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      };
}

class _RosterError extends StatelessWidget {
  const _RosterError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            error is ApiException
                ? (error as ApiException).message
                : 'Could not load the member list.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: scheme.error),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
