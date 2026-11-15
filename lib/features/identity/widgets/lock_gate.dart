import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/adaptive.dart';
import '../controllers/app_lock.dart';

/// Shows [child] only once this device has been unlocked (see [AppLock]).
class LockGate extends ConsumerWidget {
  const LockGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(appLockProvider) ? child : const _LockScreen();
}

/// Asks for the device to be unlocked before something that cannot be taken
/// back: pairing a device, showing recovery words, leaving a server. Returns
/// whether the person proved it is them.
Future<bool> confirmUnlock(
  BuildContext context,
  WidgetRef ref, {
  required String reason,
}) async {
  final lock = ref.read(appLockProvider.notifier);
  switch (await lock.method()) {
    case UnlockMethod.system:
      return lock.unlockWithSystem(reason);
    case UnlockMethod.pin:
      if (!context.mounted) return false;
      return await showDialog<bool>(
            context: context,
            builder: (_) => _PinDialog(reason: reason),
          ) ??
          false;
    case UnlockMethod.none:
      // Cannot happen behind a LockGate, which insists on a PIN first.
      return false;
  }
}

class _LockScreen extends ConsumerStatefulWidget {
  const _LockScreen();

  @override
  ConsumerState<_LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<_LockScreen> {
  final _pin = TextEditingController();
  final _again = TextEditingController();
  UnlockMethod? _method;
  bool _busy = false;
  String? _error;

  AppLock get _lock => ref.read(appLockProvider.notifier);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pin.dispose();
    _again.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final method = await _lock.method();
    if (!mounted) return;
    setState(() => _method = method);
    // The system's prompt is the whole screen on these devices: show it
    // without making the person press a button to ask for it.
    if (method == UnlockMethod.system) _system();
  }

  Future<void> _system() async {
    setState(() => _busy = true);
    final ok = await _lock.unlockWithSystem('Unlock Raindrop');
    if (mounted && !ok) setState(() => _busy = false);
  }

  Future<void> _submitPin() async {
    final creating = _method == UnlockMethod.none;
    if (creating) {
      final problem = validatePin(_pin.text);
      if (problem != null || _pin.text != _again.text) {
        setState(() => _error = problem ?? 'The two do not match.');
        return;
      }
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    if (creating) {
      await _lock.setPin(_pin.text);
      return;
    }
    final ok = await _lock.unlockWithPin(_pin.text);
    if (mounted && !ok) {
      setState(() {
        _busy = false;
        _error = 'That PIN is not right.';
        _pin.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final method = _method;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.lock_outline, size: 40, color: theme.hintColor),
                const SizedBox(height: 16),
                Text(
                  method == UnlockMethod.none
                      ? 'Choose a PIN for Raindrop'
                      : 'Raindrop is locked',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (method == null)
                  const Center(child: AdaptiveActivityIndicator())
                else if (method == UnlockMethod.system)
                  FilledButton(
                    onPressed: _busy ? null : _system,
                    child: const Text('Unlock'),
                  )
                else ...[
                  Text(
                    method == UnlockMethod.none
                        ? 'This device has no fingerprint, face or system '
                              'lock Raindrop can use, so the app asks for a '
                              'PIN of its own each time it opens.'
                        : 'Enter your PIN.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _pin,
                    autofocus: true,
                    obscureText: true,
                    enabled: !_busy,
                    decoration: const InputDecoration(labelText: 'PIN'),
                    onSubmitted: method == UnlockMethod.pin
                        ? (_) => _submitPin()
                        : null,
                  ),
                  if (method == UnlockMethod.none) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _again,
                      obscureText: true,
                      enabled: !_busy,
                      decoration: const InputDecoration(labelText: 'PIN again'),
                      onSubmitted: (_) => _submitPin(),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy ? null : _submitPin,
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: AdaptiveActivityIndicator(size: 18),
                          )
                        : Text(
                            method == UnlockMethod.none ? 'Set PIN' : 'Unlock',
                          ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PinDialog extends ConsumerStatefulWidget {
  const _PinDialog({required this.reason});

  final String reason;

  @override
  ConsumerState<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends ConsumerState<_PinDialog> {
  final _pin = TextEditingController();
  bool _busy = false;
  bool _wrong = false;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final ok = await ref
        .read(appLockProvider.notifier)
        .unlockWithPin(_pin.text);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _busy = false;
        _wrong = true;
        _pin.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.reason),
    content: TextField(
      controller: _pin,
      autofocus: true,
      obscureText: true,
      enabled: !_busy,
      decoration: InputDecoration(
        labelText: 'PIN',
        errorText: _wrong ? 'That PIN is not right.' : null,
      ),
      onSubmitted: (_) => _submit(),
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.pop(context, false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _busy ? null : _submit,
        child: const Text('Confirm'),
      ),
    ],
  );
}
