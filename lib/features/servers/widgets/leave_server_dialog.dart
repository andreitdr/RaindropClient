import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/server_profile.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/adaptive.dart';
import '../../voice/controllers/voice_call_controller.dart';
import '../controllers/servers_controller.dart';
import '../controllers/session_controller.dart';

/// Leaves [server] for good: asks for the password (the server demands it
/// for a leave) and whether to keep the account, calls
/// `UserService.LeaveServer`, then forgets the server on this device.
///
/// Like the channel-name dialog, it stays open while the request is in
/// flight and when it fails, so a wrong password is shown under the field
/// rather than closing the dialog.
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
  final _password = TextEditingController();
  bool _eraseAccount = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || _password.text.isEmpty) return;
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
                'You are signed out of this server. Sign in again to leave '
                'it, or remove it from this device.';
          });
        }
        return;
      }

      // Hang up first: the voice leave needs the session the server leave
      // is about to end.
      final call = ref.read(voiceCallProvider.notifier);
      if (ref.read(voiceCallProvider).serverId == serverId) await call.leave();

      await ref
          .read(serverSessionProvider(serverId).notifier)
          .leave(password: _password.text, preserveData: !_eraseAccount);
      await ref.read(serversControllerProvider.notifier).remove(serverId);
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = e.code == 'invalid_credentials'
              ? 'That password is not right.'
              : e.message;
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
                  ? 'Your username and password are erased on the server right '
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
            TextField(
              controller: _password,
              autofocus: true,
              obscureText: true,
              enabled: !_submitting,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: 'Password'),
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 8),
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
          onPressed: _submitting || _password.text.isEmpty ? null : _submit,
          child: _submitting
              ? const AdaptiveActivityIndicator(size: 18)
              : const Text('Leave server'),
        ),
      ],
    );
  }
}
