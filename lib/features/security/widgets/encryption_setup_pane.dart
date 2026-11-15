import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/adaptive.dart';
import '../controllers/device_setup_controller.dart';

/// Takes the chat pane when this device's keys for the server no longer
/// belong to the account ([DeviceSetupReplaced]): it was removed from another
/// of the person's devices, or the account's devices were reset. Starting
/// again makes new keys and signs in with them — nothing is typed, because
/// the account is still theirs by their identity.
class EncryptionSetupPane extends ConsumerStatefulWidget {
  const EncryptionSetupPane({
    super.key,
    required this.serverId,
    required this.state,
    this.leading,
  });

  final String serverId;
  final DeviceSetupState state;
  final Widget? leading;

  @override
  ConsumerState<EncryptionSetupPane> createState() =>
      _EncryptionSetupPaneState();
}

class _EncryptionSetupPaneState extends ConsumerState<EncryptionSetupPane> {
  bool _busy = false;
  String? _error;

  Future<void> _startOver() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(deviceSetupProvider(widget.serverId).notifier).startOver();
    } on ApiException catch (e) {
      _error = e.message;
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        if (widget.leading != null)
          Align(alignment: Alignment.centerLeft, child: widget.leading),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lock_outline,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Set this device up again',
                                style: theme.textTheme.titleLarge,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'This device was removed from your account on this '
                          'server, so its encryption keys no longer work '
                          'here. Setting it up again makes new ones. Messages '
                          'already stored on this device for this server '
                          'will be gone.',
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _busy ? null : _startOver,
                          child: _busy
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: AdaptiveActivityIndicator(size: 18),
                                )
                              : const Text('Set up again'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
