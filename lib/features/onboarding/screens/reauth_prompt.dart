import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/server_profile.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/adaptive.dart';
import '../controllers/connect_server_flow.dart';

/// Shown in the chat pane (beside the server rail, so the app still opens on
/// its normal layout) when a server's stored session token is
/// missing or has expired (idle timeout, or a restart of an in-memory
/// session store on the server side) but the server itself is still known
/// locally. Just asks for the password again — the GUID and pinned
/// fingerprint are already on file.
class ReauthPrompt extends ConsumerStatefulWidget {
  const ReauthPrompt({super.key, required this.profile});

  final ServerProfile profile;

  @override
  ConsumerState<ReauthPrompt> createState() => _ReauthPromptState();
}

class _ReauthPromptState extends ConsumerState<ReauthPrompt> {
  final _passwordController = TextEditingController();
  bool _submitting = false;
  String? _error;
  bool _offerRejoin = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit({bool rejoin = false}) async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    final flow = await ConnectServerFlow.forExisting(widget.profile);
    try {
      final session = rejoin
          ? await flow.rejoin(password: _passwordController.text)
          : await flow.login(password: _passwordController.text);
      await flow.persist(
        ref,
        session: session,
        displayName: widget.profile.displayName,
      );
    } on ApiException catch (e) {
      flow.dispose();
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.message;
        _offerRejoin = e.code == 'account_left';
      });
      return;
    } catch (e) {
      flow.dispose();
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Something went wrong: $e';
      });
      return;
    }
    if (!mounted) return;
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
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
                  Text(
                    'Reconnect to ${widget.profile.displayName}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your session on ${widget.profile.displayName} expired. Enter your password to continue.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    onSubmitted: (_) => _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _submitting ? null : () => _submit(),
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: AdaptiveActivityIndicator(size: 18),
                          )
                        : const Text('Log in'),
                  ),
                  if (_offerRejoin) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _submitting
                          ? null
                          : () => _submit(rejoin: true),
                      child: const Text('Rejoin instead'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
