import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/adaptive.dart';
import '../../identity/controllers/identity_controller.dart';
import '../controllers/connect_server_flow.dart';

/// Step 1 of adding a server: host, port, and a local nickname. Submitting
/// probes the server (`ServerService.GetServerInfo`), derives this person's
/// account there, and asks what the server knows of it
/// (`UserService.GetUserStatus`) before handing off to [ServerAuthScreen],
/// which signs this device in — asking for a username only when the account
/// is new.
class ConnectServerScreen extends ConsumerStatefulWidget {
  const ConnectServerScreen({super.key});

  @override
  ConsumerState<ConnectServerScreen> createState() =>
      _ConnectServerScreenState();
}

class _ConnectServerScreenState extends ConsumerState<ConnectServerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '5001');
  final _nameController = TextEditingController();
  bool _connecting = false;
  String? _error;

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _connecting = true;
      _error = null;
    });

    final host = _hostController.text.trim();
    final port = int.parse(_portController.text.trim());
    final displayName = _nameController.text.trim().isEmpty
        ? host
        : _nameController.text.trim();
    final identity = await ref.read(identityProvider.future);
    if (identity == null) return;
    final flow = ConnectServerFlow(host: host, port: port, identity: identity);

    try {
      await flow.probe();
      if (flow.alreadyAdded(ref)) {
        throw const ApiException(
          409,
          'already_added',
          'This server is already in your list. Pick it from the server rail.',
        );
      }
      final status = await flow.checkStatus();
      if (!mounted) return;
      await context.push(
        '/connect/auth',
        extra: (flow: flow, status: status, displayName: displayName),
      );
      if (!mounted) return;
      setState(() => _connecting = false);
    } on ApiException catch (e) {
      await flow.dispose(ref);
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _error = e.message;
      });
    } catch (e) {
      await flow.dispose(ref);
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _error = 'Could not connect: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add a server')),
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
                        'Connect to a Raindrop server',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Raindrop servers are self-hosted. Enter the address someone gave you.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _hostController,
                        decoration: const InputDecoration(
                          labelText: 'Host',
                          hintText: 'raindrop.example.com',
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _portController,
                        decoration: const InputDecoration(labelText: 'Port'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final n = int.tryParse(v?.trim() ?? '');
                          if (n == null || n <= 0 || n > 65535) {
                            return 'Enter a valid port';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nickname (optional)',
                        ),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _connect(),
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
                        onPressed: _connecting ? null : _connect,
                        child: _connecting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: AdaptiveActivityIndicator(size: 18),
                              )
                            : const Text('Connect'),
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
}
