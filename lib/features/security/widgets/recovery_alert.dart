import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/theme_controller.dart';
import '../controllers/recovery_watch.dart';

bool _asking = false;

/// Asks the person about any device waiting to join their account that they
/// have not answered for yet: somebody used their recovery words and said
/// the authenticator was lost. Either it was them (on a new device, with
/// this one still around), or the words have leaked and the wait must be
/// stopped — on every server, since whoever has the words started it on all.
Future<void> askAboutRecoveries(
  BuildContext context,
  WidgetRef ref,
  List<ServerRecovery> waits,
) async {
  final prefs = ref.read(appPrefsProvider);
  final acknowledged = prefs.acknowledgedRecoveries;
  final fresh = [
    for (final wait in waits)
      if (!acknowledged.contains(recoveryKey(wait))) wait,
  ];
  if (fresh.isEmpty || _asking) return;

  _asking = true;
  try {
    final stop = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _RecoveryAlertDialog(waits: fresh),
    );
    if (stop == null || !context.mounted) return;

    if (!stop) {
      await prefs.setAcknowledgedRecoveries({
        ...acknowledged,
        for (final wait in fresh) recoveryKey(wait),
      });
      return;
    }

    final failed = await cancelAllRecoveries(ref);
    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 10),
        content: Text(
          failed == 0
              ? 'Stopped. Your recovery words are known to someone else: make '
                    'new ones now.'
              : 'Stopped, except on $failed server(s) that could not be '
                    'reached; try again from Identity & devices. Make new '
                    'recovery words now.',
        ),
        action: SnackBarAction(
          label: 'New words',
          onPressed: () => context.push('/settings/identity'),
        ),
      ),
    );
  } finally {
    _asking = false;
  }
}

class _RecoveryAlertDialog extends StatelessWidget {
  const _RecoveryAlertDialog({required this.waits});

  final List<ServerRecovery> waits;

  @override
  Widget build(BuildContext context) {
    final servers = {for (final wait in waits) wait.server.displayName};
    final soonest = waits
        .map((w) => w.recovery.eligibleAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final when = DateFormat.yMMMMd().add_jm().format(soonest.toLocal());

    return AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded),
      title: const Text('Is a new device yours?'),
      content: SizedBox(
        width: 420,
        child: Text(
          'Someone used your recovery words on a new device and said they '
          'lost your authenticator. Unless you stop it, that device joins '
          'your account on ${servers.join(', ')} on $when.\n\n'
          'If it was not you, stop it now and make new recovery words.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('It was me'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Stop it'),
        ),
      ],
    );
  }
}
