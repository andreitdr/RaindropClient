import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/server_profile.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/adaptive.dart';
import '../../identity/widgets/lock_gate.dart';
import '../../voice/controllers/voice_call_controller.dart';
import '../controllers/servers_controller.dart';
import '../controllers/session_controller.dart';

/// Leaves [server] for good: asks whether to keep the account, has the
/// person unlock this device (there is no password to confirm with; the
/// server takes the session being bound to one of their devices), calls
/// `UserService.LeaveServer`, then forgets the server on this device.
///
/// Like the channel-name dialog, it stays open while the request is in
/// flight and when it fails, so a refusal is shown rather than closing the
/// dialog.
Future<void> showLeaveServerDialog(
  BuildContext context,
  ServerProfile server,
) => showDialog<void>(
  context: context,
  builder: (_) => _LeaveServerDialog(server: server),
);

class _LeaveServerDialog extends ConsumerStatefulWidget {
  const _LeaveServerDialog({required this.server});

  final ServerProfile server;

  @override
  ConsumerState<_LeaveServerDialog> createState() => _LeaveServerDialogState();
}

class _LeaveServerDialogState extends ConsumerState<_LeaveServerDialog> {
  bool _eraseAccount = false;
  bool _submitting = false;
  String? _error;

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final serverId = widget.server.id;
    try {
      // The menu offers this for any server, including one whose session has
      // not been restored yet (only the active server's has) — so wait for
      // it here rather than hiding the option behind a session that is one
      // round trip away.
      if (await ref.read(serverSessionProvider(serverId).future) == null) {
        if (mounted) {
          setState(() {
            _submitting = false;
            _error =
                'This device is not signed in to this server. Sign in to leave '
                'it, or remove it from this device.';
          });
        }
        return;
      }

      if (!mounted ||
          !await confirmUnlock(
            context,
            ref,
            reason: 'Leave ${widget.server.displayName}',
          )) {
        if (mounted) setState(() => _submitting = false);
        return;
      }

      // Hang up first: the voice leave needs the session the server leave
      // is about to end.
      final call = ref.read(voiceCallProvider.notifier);
      if (ref.read(voiceCallProvider).serverId == serverId) await call.leave();

      await ref
          .read(serverSessionProvider(serverId).notifier)
          .leave(preserveData: !_eraseAccount);
      await ref.read(serversControllerProvider.notifier).remove(serverId);
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text('Leave ${widget.server.displayName}?'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _eraseAccount
                  ? 'Your username is erased on the server right '
                        'away. Messages you sent stay, shown as from an unknown '
                        'member.'
                  : 'The server keeps your account, inactive, for as long as '
                        'its owner retains data, then erases it. Your username '
                        'stays reserved until then.',
            ),
            const SizedBox(height: 4),
            Text(
              'The server is removed from this device either way.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            SwitchListTile.adaptive(
              value: _eraseAccount,
              onChanged: _submitting
                  ? null
                  : (value) => setState(() => _eraseAccount = value),
              title: const Text('Erase my account'),
              contentPadding: EdgeInsets.zero,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: scheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: scheme.error),
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const AdaptiveActivityIndicator(size: 18)
              : const Text('Leave server'),
        ),
      ],
    );
  }
}
