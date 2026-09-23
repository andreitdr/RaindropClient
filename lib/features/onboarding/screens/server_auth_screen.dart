import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/users_api.dart';
import '../../../core/widgets/adaptive.dart';
import '../controllers/connect_server_flow.dart';

typedef ConnectHandoff = ({
  ConnectServerFlow flow,
  UserStateResult status,
  String displayName,
});

/// Step 2 of adding a server: register, log in, or rejoin, depending on
/// what `/api/users/status` said about this brand-new GUID. Almost every
/// real connection lands on `unregistered` — the other two branches exist
/// for the rare case where a client re-imports a GUID it already used here.
///
/// An `unregistered` GUID can still belong to somebody who already has an
/// account here: removing a server forgets its GUID, but not the account on
/// the server. "Already have an account?" switches to logging in by
/// username, which hands the account's real UUID back to the flow.
class ServerAuthScreen extends ConsumerStatefulWidget {
  const ServerAuthScreen({super.key, required this.handoff});

  final ConnectHandoff handoff;

  @override
  ConsumerState<ServerAuthScreen> createState() => _ServerAuthScreenState();
}

class _ServerAuthScreenState extends ConsumerState<ServerAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;
  String? _error;

  /// Only meaningful for a GUID the server doesn't know: whether the user is
  /// claiming a new account or signing in to one they already have.
  bool _loginMode = false;

  /// Shown after a username login hit an account that left with its data
  /// preserved — the same offer [ReauthPrompt] makes.
  bool _offerRejoin = false;

  ConnectServerFlow get _flow => widget.handoff.flow;
  String get _state => widget.handoff.status.state;

  /// Whether this screen is deciding between registering and logging in,
  /// rather than acting on an account the GUID is already known to have.
  bool get _isNewGuid => _state == 'unregistered' || _state == 'erased';

  /// Whether the username is something to type rather than something to show.
  bool get _usernameIsInput => _isNewGuid;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    // Only tear down the flow's client if the screen is leaving without
    // ever succeeding — a successful submit keeps it alive as the session's
    // long-lived client.
    if (!_succeeded) _flow.dispose();
    super.dispose();
  }

  bool _succeeded = false;

  Future<void> _submit({bool rejoin = false}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final session = await _authenticate(rejoin: rejoin);
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
        _error = e.message;
        // The account behind this username left with its data preserved:
        // the same password will bring it back, through rejoin.
        _offerRejoin = e.code == 'account_left';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Something went wrong: $e';
      });
    }
  }

  Future<SessionResult> _authenticate({required bool rejoin}) {
    final password = _passwordController.text;
    final username = _usernameController.text.trim();

    if (_isNewGuid) {
      if (rejoin) {
        return _flow.rejoinWithUsername(
          ref,
          username: username,
          password: password,
        );
      }
      return _loginMode
          ? _flow.loginWithUsername(ref, username: username, password: password)
          : _flow.register(username: username, password: password);
    }

    return _state == 'left_preserved'
        ? _flow.rejoin(password: password)
        : _flow.login(password: password);
  }

  void _switchMode() => setState(() {
    _loginMode = !_loginMode;
    _error = null;
    _offerRejoin = false;
  });

  @override
  Widget build(BuildContext context) {
    final title = switch (_state) {
      'active' => 'Log in',
      'left_preserved' => 'Welcome back',
      _ => _loginMode ? 'Log in' : 'Create your account',
    };

    return Scaffold(
      appBar: AppBar(title: Text(title)),
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
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _subtitle(),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      if (_usernameIsInput)
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                          textInputAction: TextInputAction.next,
                        )
                      else
                        InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Username',
                          ),
                          child: Text(widget.handoff.status.username ?? '—'),
                        ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                        obscureText: true,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _submitting ? null : () => _submit(),
                        child: _submitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: AdaptiveActivityIndicator(size: 18),
                              )
                            : Text(_buttonLabel()),
                      ),
                      if (_offerRejoin)
                        TextButton(
                          onPressed: _submitting
                              ? null
                              : () => _submit(rejoin: true),
                          child: const Text('Rejoin instead'),
                        ),
                      if (_isNewGuid && !_offerRejoin)
                        TextButton(
                          onPressed: _submitting ? null : _switchMode,
                          child: Text(
                            _loginMode
                                ? 'New here? Create an account'
                                : 'Already have an account? Log in',
                          ),
                        ),
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
    switch (_state) {
      case 'active':
        return 'This account already exists on this server. Enter its password.';
      case 'left_preserved':
        final expires = widget.handoff.status.dataExpiresAtUtc;
        final until = expires == null
            ? ''
            : ' Data is kept until ${DateFormat.yMMMd().format(expires)}.';
        return 'This account left but its data is still preserved.$until Enter its password to rejoin.';
      default:
        return _loginMode
            ? 'Enter the username and password of your account on this server.'
            : 'Pick a username and password for this server.';
    }
  }

  String _buttonLabel() => switch (_state) {
    'active' => 'Log in',
    'left_preserved' => 'Rejoin',
    _ => _loginMode ? 'Log in' : 'Create account',
  };
}
