import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/users_api.dart';
import '../../../core/widgets/adaptive.dart';
import '../../identity/device_sign_in.dart';
import '../controllers/connect_server_flow.dart';
import '../models/claim_code.dart';

typedef ConnectHandoff = ({
  ConnectServerFlow flow,
  UserStateResult status,
  String displayName,
});

/// Step 2 of adding a server: signing this device in. There is no password.
///
/// - The server has no account for this person (`unregistered`, `erased`):
///   they pick a username, and the account is made.
/// - It has one (`active`, or `left_preserved`, which signing in restores):
///   nothing is asked at all, and this screen signs in as soon as it opens —
///   this is the person adding a server one of their other devices already
///   joined, or adding back one they removed.
///
/// The one other thing that can be asked for is an authenticator code, when
/// the account has an authenticator and this device does not hold its secret
/// (it was set up from the recovery words rather than paired).
class ServerAuthScreen extends ConsumerStatefulWidget {
  const ServerAuthScreen({super.key, required this.handoff});

  final ConnectHandoff handoff;

  @override
  ConsumerState<ServerAuthScreen> createState() => _ServerAuthScreenState();
}

class _ServerAuthScreenState extends ConsumerState<ServerAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _codeController = TextEditingController();
  final _claimController = TextEditingController();
  bool _submitting = false;

  /// Taking an account over with a claim code from the server's owner,
  /// rather than joining under a new username.
  bool _claiming = false;
  bool _needsCode = false;
  bool _succeeded = false;
  String? _error;

  ConnectServerFlow get _flow => widget.handoff.flow;
  String get _state => widget.handoff.status.state;

  /// Whether the account has to be made, and so named.
  bool get _isNew => _state == 'unregistered' || _state == 'erased';

  /// The app's container, captured while mounted: [dispose] hands it to the
  /// flow, and by then this screen's `ref` can no longer be used.
  late final ProviderContainer _container;

  @override
  void initState() {
    super.initState();
    _container = ProviderScope.containerOf(context, listen: false);
    if (!_isNew) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _submit());
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _codeController.dispose();
    _claimController.dispose();
    // A flow that never signed in takes the keys it made with it; one that
    // did keeps its client alive as the session's.
    if (!_succeeded) _flow.dispose(_container);
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? true)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      if (_claiming) {
        final claim = ClaimCode.tryParse(_claimController.text);
        if (claim == null) {
          setState(() {
            _submitting = false;
            _error = 'That is not a claim code. It starts with RDC1-.';
          });
          return;
        }
        await _flow.useClaim(_container, claim);
      }
      final session = await _flow.signIn(
        ref,
        username: _isNew && !_claiming ? _usernameController.text.trim() : null,
        authenticatorCode: _needsCode ? _codeController.text.trim() : null,
      );
      _succeeded = true;
      await _flow.persist(
        ref,
        session: session,
        displayName: widget.handoff.displayName,
      );
      if (!mounted) return;
      context.go('/');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        if (needsAuthenticatorCode(e.code)) {
          // The first refusal is only the server saying a code is wanted.
          _error = _needsCode ? e.message : null;
          _needsCode = true;
          _codeController.clear();
        } else {
          _error = e.message;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Something went wrong: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final waiting = _submitting && !_isNew && !_needsCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Join this server' : 'Signing you in'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.handoff.displayName,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(_subtitle(), style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 20),
                      if (waiting)
                        const Center(child: AdaptiveActivityIndicator()),
                      if (_isNew && _claiming)
                        TextFormField(
                          controller: _claimController,
                          autofocus: true,
                          enabled: !_submitting,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Claim code',
                            helperText: 'From whoever runs this server',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                      if (_isNew && !_claiming)
                        TextFormField(
                          controller: _usernameController,
                          autofocus: true,
                          enabled: !_submitting,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                      if (_needsCode) ...[
                        if (_isNew) const SizedBox(height: 12),
                        TextFormField(
                          controller: _codeController,
                          autofocus: true,
                          enabled: !_submitting,
                          decoration: const InputDecoration(
                            labelText: 'Authenticator code',
                            helperText: 'Or one of your backup codes',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
                      if (!waiting) ...[
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _submitting ? null : _submit,
                          child: _submitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: AdaptiveActivityIndicator(size: 18),
                                )
                              : Text(
                                  _isNew && _claiming
                                      ? 'Take my account back'
                                      : _isNew
                                      ? 'Join'
                                      : _needsCode
                                      ? 'Sign in'
                                      : 'Try again',
                                ),
                        ),
                        if (_isNew && !_needsCode) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _submitting
                                ? null
                                : () => setState(() {
                                    _claiming = !_claiming;
                                    _error = null;
                                  }),
                            child: Text(
                              _claiming
                                  ? 'Join with a new username instead'
                                  : 'I have a claim code from the owner',
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _subtitle() {
    if (_needsCode) {
      return 'Your account has an authenticator, and this device is new to '
          'it. Enter a code from your authenticator app.';
    }
    if (_isNew && _claiming) {
      return 'Lost everything — every device, your recovery words? Whoever '
          'runs this server can give you a claim code to take your account '
          'back with this identity. Your username and roles stay; messages '
          'from before cannot be read, and other members see that your '
          'identity changed.';
    }
    if (_isNew) {
      return 'Pick the name you go by on this server. There is no password: '
          'this device signs you in.';
    }
    final name = widget.handoff.status.username;
    return name == null
        ? 'You already have an account on this server.'
        : 'You are $name on this server.';
  }
}
