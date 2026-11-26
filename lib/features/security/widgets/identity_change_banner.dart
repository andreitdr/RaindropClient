import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/crypto/crypto_engine.dart';
import '../../servers/controllers/user_lookup.dart';
import '../controllers/identity_changes.dart';
import 'identity_change_dialog.dart';

/// The changed identity keys that touch one channel, above its messages: who,
/// what it costs here (their messages hidden, this device out of the
/// channel's encryption) and a way to review the new key. Nothing when none
/// does. It never goes away by itself — only by the person's decision, which
/// the pending list then reflects.
class IdentityChangeBanner extends ConsumerWidget {
  const IdentityChangeBanner({
    super.key,
    required this.serverId,
    required this.channelId,
  });

  final String serverId;
  final String channelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final changes =
        ref.watch(pendingIdentityChangesProvider(serverId)).valueOrNull ??
        const <PendingIdentityChange>[];
    final here = [
      for (final change in changes)
        if (change.channelIds.contains(channelId)) change,
    ];
    if (here.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (final change in here)
          _BannerRow(serverId: serverId, channelId: channelId, change: change),
      ],
    );
  }
}

class _BannerRow extends ConsumerWidget {
  const _BannerRow({
    required this.serverId,
    required this.channelId,
    required this.change,
  });

  final String serverId;
  final String channelId;
  final PendingIdentityChange change;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final name = displayNameFor(ref, (
      serverId: serverId,
      userId: change.userId,
    ));
    final held = change.heldChannelIds.contains(channelId);
    final left = change.leftChannelIds.contains(channelId);
    final effect = switch ((held, left)) {
      (true, true) =>
        'Their messages are hidden and this device is out of the channel\'s '
            'encryption',
      (false, true) => 'This device is out of the channel\'s encryption',
      _ => 'Their messages are hidden',
    };

    return Container(
      key: Key('identity-banner-${change.userId}'),
      width: double.infinity,
      color: scheme.errorContainer,
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: scheme.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$name\'s security key changed. $effect until you confirm the '
              'new key.',
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: scheme.onErrorContainer,
            ),
            onPressed: () => reviewIdentityChange(
              context,
              serverId: serverId,
              change: change,
              userName: name,
            ),
            child: const Text('Review'),
          ),
        ],
      ),
    );
  }
}
