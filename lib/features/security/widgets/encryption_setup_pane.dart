import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/crypto/crypto_engine.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/adaptive.dart';
import '../controllers/device_setup_controller.dart';

/// Takes the chat pane while this device cannot take part in encryption yet
/// ([DeviceSetupNeedsKeys], [DeviceSetupLinking] or [DeviceSetupReplaced]),
/// the same way `ReauthPrompt` takes it while signed out.
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

enum _Mode { choose, restore, reset }

class _EncryptionSetupPaneState extends ConsumerState<EncryptionSetupPane> {
  final _input = TextEditingController();
  _Mode _mode = _Mode.choose;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  DeviceSetupController get _controller =>
      ref.read(deviceSetupProvider(widget.serverId).notifier);

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on CryptoException catch (e) {
      _error = switch (e.kind) {
        CryptoErrorKind.backupLocked =>
          'Those words do not open your backup. Check each word and try again.',
        CryptoErrorKind.malformed =>
          'That is not a valid recovery key. It is 24 words.',
        _ => e.message,
      };
    } on ApiException catch (e) {
      _error = e.message;
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = switch (widget.state) {
      DeviceSetupLinking(:final code) => _linking(context, code),
      DeviceSetupReplaced(:final revoked) => _replaced(context, revoked),
      _ => switch (_mode) {
        _Mode.choose => _choose(context),
        _Mode.restore => _restore(context),
        _Mode.reset => _reset(context),
      },
    };

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
                                'Set up encryption on this device',
                                style: theme.textTheme.titleLarge,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...content,
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ],
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

  Widget _button(String label, VoidCallback? onPressed, {bool filled = true}) {
    final child = _busy
        ? const SizedBox(
            height: 20,
            width: 20,
            child: AdaptiveActivityIndicator(size: 18),
          )
        : Text(label);
    return filled
        ? FilledButton(onPressed: _busy ? null : onPressed, child: child)
        : OutlinedButton(onPressed: _busy ? null : onPressed, child: child);
  }

  List<Widget> _choose(BuildContext context) => [
    const Text(
      'Your account already uses end-to-end encryption on another device. '
      'Bring your keys to this one to read and send messages here.',
    ),
    const SizedBox(height: 20),
    _button('Link from another device', () => _run(_controller.startLink)),
    const SizedBox(height: 8),
    _button(
      'Use my recovery key',
      () => setState(() => _mode = _Mode.restore),
      filled: false,
    ),
    const SizedBox(height: 8),
    TextButton(
      onPressed: _busy ? null : () => setState(() => _mode = _Mode.reset),
      child: const Text('I lost every device and my recovery key'),
    ),
  ];

  List<Widget> _linking(BuildContext context, DeviceLinkCode code) {
    final text = code.toString();
    return [
      const Text(
        'On a device that is already set up, open Settings → Encryption → '
        'Link a new device, and scan this code or type it in:',
      ),
      const SizedBox(height: 16),
      // The same code as a QR code, for a device with a camera to scan.
      Center(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(8),
          child: QrImageView(
            data: text,
            size: 200,
            backgroundColor: Colors.white,
            errorCorrectionLevel: QrErrorCorrectLevel.M,
          ),
        ),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: SelectableText(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
        ),
      ),
      TextButton.icon(
        onPressed: () => Clipboard.setData(ClipboardData(text: text)),
        icon: const Icon(Icons.copy, size: 18),
        label: const Text('Copy code'),
      ),
      const SizedBox(height: 8),
      const Row(
        children: [
          SizedBox(
            height: 16,
            width: 16,
            child: AdaptiveActivityIndicator(size: 14),
          ),
          SizedBox(width: 8),
          Expanded(child: Text('Waiting for approval…')),
        ],
      ),
      const SizedBox(height: 16),
      _button('Cancel', _controller.cancelLink, filled: false),
    ];
  }

  List<Widget> _restore(BuildContext context) => [
    const Text('Enter the 24 words of your recovery key.'),
    const SizedBox(height: 12),
    TextField(
      controller: _input,
      minLines: 3,
      maxLines: 5,
      autocorrect: false,
      enableSuggestions: false,
      decoration: const InputDecoration(border: OutlineInputBorder()),
    ),
    const SizedBox(height: 16),
    _button(
      'Restore',
      () => _run(() => _controller.restoreWithRecoveryWords(_input.text)),
    ),
    const SizedBox(height: 8),
    _button('Back', () => setState(() => _mode = _Mode.choose), filled: false),
  ];

  List<Widget> _reset(BuildContext context) => [
    const Text(
      'Resetting creates a new encryption identity. Every device of yours is '
      'signed out of encryption, messages sent to you before now stay '
      'unreadable, and everyone you talk to is told your safety number '
      'changed. Enter your password to confirm.',
    ),
    const SizedBox(height: 12),
    TextField(
      controller: _input,
      obscureText: true,
      decoration: const InputDecoration(labelText: 'Password'),
    ),
    const SizedBox(height: 16),
    FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
      onPressed: _busy
          ? null
          : () => _run(() => _controller.resetIdentity(_input.text)),
      child: const Text('Reset my encryption identity'),
    ),
    const SizedBox(height: 8),
    _button('Back', () => setState(() => _mode = _Mode.choose), filled: false),
  ];

  List<Widget> _replaced(BuildContext context, bool revoked) => [
    Text(
      revoked
          ? 'This device was removed from your account, so its encryption keys '
                'no longer work. Set it up again to keep using it.'
          : 'Your encryption identity was reset from another device, so this '
                "device's keys no longer work. Set it up again to keep using it.",
    ),
    const SizedBox(height: 20),
    _button('Set up again', () => _run(_controller.startOver)),
  ];
}
