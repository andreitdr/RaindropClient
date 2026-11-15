import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/crypto/crypto_store.dart';
import '../../../core/models/server_profile.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/adaptive.dart';
import '../../identity/device_sign_in.dart';
import '../../security/controllers/device_setup_controller.dart';
import '../controllers/session_controller.dart';
import 'remove_server.dart';

/// Takes the chat pane's place for a server this device could not sign in to
/// by itself. That is rare — a lapsed session is renewed without a word — and
/// each case asks for the one thing that is missing:
///
/// - an **authenticator code**, for a device that is new to an account with
///   an authenticator and does not hold its secret;
/// - a **username**, when the server no longer has the account at all (its
///   database was reset, or the account was erased) and it has to be made
///   again;
/// - nothing but a go-ahead, when this device was **removed** from the
///   account by another of the person's devices and has to set itself up
///   afresh.
class SignInPane extends ConsumerStatefulWidget {
  const SignInPane({super.key, required this.profile});

  final ServerProfile profile;

  @override
  ConsumerState<SignInPane> createState() => _SignInPaneState();
}

enum _Need { code, username, freshDevice, retry }

class _SignInPaneState extends ConsumerState<SignInPane> {
  final _input = TextEditingController();
  bool _busy = false;
  String? _error;

  String get _serverId => widget.profile.id;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  _Need _need(ApiException? failure) => switch (failure?.code) {
    final code? when needsAuthenticatorCode(code) => _Need.code,
    'authenticator_locked' => _Need.code,
    'invalid_username' => _Need.username,
    'invalid_credentials' || 'device_exists' => _Need.freshDevice,
    _ => _Need.retry,
  };

  Future<void> _submit(_Need need) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final session = ref.read(serverSessionProvider(_serverId).notifier);
    try {
      switch (need) {
        case _Need.code:
          await session.signInWith(authenticatorCode: _input.text.trim());
        case _Need.username:
          await session.signInWith(username: _input.text.trim());
        case _Need.freshDevice:
          // This device's keys for the server are refused for good; new ones
          // are made on the way back in.
          (await ref.read(cryptoEngineProvider(_serverId).future)).dispose();
          ref.invalidate(cryptoEngineProvider(_serverId));
          await const CryptoStores().delete(_serverId);
          await session.signInWith();
        case _Need.retry:
          ref.read(signInFailureProvider(_serverId).notifier).state = null;
          ref.invalidate(serverSessionProvider(_serverId));
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      // What is wanted may have changed (a fresh device now needs a code).
      ref.read(signInFailureProvider(_serverId).notifier).state = e;
      setState(() => _error = e.message);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _input.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final failure = ref.watch(signInFailureProvider(_serverId));
    final need = _need(failure);
    final name = widget.profile.displayName;

    final (String message, String? label, String action) = switch (need) {
      _Need.code => (
        'Your account on $name has an authenticator, and this device is new '
            'to it. Enter a code from your authenticator app, or a backup '
            'code.',
        'Authenticator code',
        'Sign in',
      ),
      _Need.username => (
        '$name no longer has your account — it may have been reset. Pick a '
            'username to join it again.',
        'Username',
        'Join again',
      ),
      _Need.freshDevice => (
        'This device can no longer sign in to $name: it was removed from '
            'your account, or the account was reset. Set it up again to '
            'keep using it here. Messages already on this device for $name '
            'will be gone.',
        null,
        'Set this device up again',
      ),
      _Need.retry => (
        failure?.message ?? 'Could not sign in to $name.',
        null,
        'Try again',
      ),
    };

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Sign in to $name', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(message, style: theme.textTheme.bodyMedium),
                  if (label != null) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _input,
                      autofocus: true,
                      enabled: !_busy,
                      decoration: InputDecoration(labelText: label),
                      onSubmitted: (_) => _submit(need),
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
                    onPressed: _busy ? null : () => _submit(need),
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: AdaptiveActivityIndicator(size: 18),
                          )
                        : Text(action),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () =>
                              confirmRemoveServer(context, ref, widget.profile),
                    child: const Text('Remove from this device'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
