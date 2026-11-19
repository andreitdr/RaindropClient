import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/crypto/crypto_engine.dart';
import '../../../core/crypto/identity_crypto.dart';
import '../../../core/models/server_profile.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/e2ee_api.dart';
import '../../../core/network/raindrop_channel.dart';
import '../../../core/network/server_trust.dart';
import '../../../core/network/users_api.dart';
import '../../../core/storage/identity_store.dart';
import '../../../core/storage/secure_store.dart';
import '../../../core/widgets/adaptive.dart';
import '../../servers/controllers/servers_controller.dart';
import '../controllers/identity_controller.dart';
import '../controllers/vault_sync.dart';
import '../models/vault.dart';
import '../models/recovery_check.dart';
import '../widgets/server_address_fields.dart';

/// Getting an identity back when every device is gone: one server the person
/// was on, and their 24 recovery words. The server hands over the root it
/// holds sealed under those words — it could never open it — and this device
/// becomes theirs. If they set up an authenticator, the server then asks for
/// a code before it lets the device in; the words alone are not the account.
class RecoverScreen extends ConsumerStatefulWidget {
  const RecoverScreen({super.key});

  @override
  ConsumerState<RecoverScreen> createState() => _RecoverScreenState();
}

class _RecoverScreenState extends ConsumerState<RecoverScreen> {
  final _formKey = GlobalKey<FormState>();
  final _host = TextEditingController();
  final _port = TextEditingController(text: '5001');
  final _words = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    _words.dispose();
    super.dispose();
  }

  Future<void> _recover() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final host = _host.text.trim();
    final port = int.parse(_port.text.trim());
    final client = RaindropChannel.forServer(host: host, port: port);

    try {
      final info = await UsersApi(client).serverInfo();
      final presented = client.pinner.observedFingerprint;
      final serverKey = info.identityKey;
      if (presented == null ||
          serverKey == null ||
          !ServerTrust.isConsistent(info, presented)) {
        throw ApiException.certificateMismatch();
      }

      final seed = await IdentityCrypto.seedFromWords(
        normalizeRecoveryWords(_words.text),
      );
      final sealed = await E2eeApi(client)
          .sealedRoot(await IdentityCrypto.lookupId(seed, serverKey));
      final root = await IdentityCrypto.openRoot(
        seed: seed,
        serverKey: serverKey,
        blob: sealed.sealedRoot,
      );

      // The server goes into the list with the pins this connection made;
      // its session then opens by itself, asking for an authenticator code
      // if the account has one, and its vault brings the other servers.
      final id = await IdentityCrypto.accountId(root, serverKey);
      const secure = SecureStore();
      await secure.pinFingerprint(id, presented);
      await secure.pinIdentityKey(id, serverKey);
      await ref
          .read(identityProvider.notifier)
          .adopt(ClientIdentity(root: root, recoverySeed: seed));
      ref
          .read(serversControllerProvider.notifier)
          .add(
            ServerProfile(id: id, host: host, port: port, displayName: host),
          );
      // Every other server the person is on, from the vault that came with
      // the root: they all start signing in now, so a device that has to
      // wait out a lost authenticator waits on all of them at once.
      await _addVaultServers(root, seed, serverKey, sealed.vault);
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on ApiException catch (e) {
      _fail(
        e.code == 'vault_not_found'
            ? 'Nothing is stored for those words on this server. Check the '
                  'words, and that this is a server you were on.'
            : e.message,
      );
    } on CryptoException catch (e) {
      _fail(switch (e.kind) {
        CryptoErrorKind.malformed =>
          'Those are not 24 valid recovery words. Check for a typo.',
        CryptoErrorKind.backupLocked =>
          'Those words do not open what this server holds.',
        _ => e.message,
      });
    } finally {
      client.close();
    }
  }

  Future<void> _addVaultServers(
    Uint8List root,
    Uint8List seed,
    Uint8List serverKey,
    Uint8List? sealedVault,
  ) async {
    if (sealedVault == null) return;
    try {
      final vault = Vault.tryFromBytes(
        await IdentityCrypto.openVault(
          root: root,
          serverKey: serverKey,
          blob: sealedVault,
        ),
      );
      if (vault == null) return;
      await ref
          .read(vaultProvider.notifier)
          .adoptServers(vault, ClientIdentity(root: root, recoverySeed: seed));
    } on CryptoException {
      // Sealed under an older root: the first sync with this server brings
      // the servers instead.
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Recover your identity')),
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
                        'Enter one server you were on and the 24 words you '
                        'saved when you set Raindrop up.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      ServerAddressFields(
                        host: _host,
                        port: _port,
                        enabled: !_busy,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _words,
                        enabled: !_busy,
                        minLines: 3,
                        maxLines: 5,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: const InputDecoration(
                          labelText: 'Recovery words',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            normalizeRecoveryWords(v ?? '').split(' ').length !=
                                24
                            ? 'Enter all 24 words'
                            : null,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _busy ? null : _recover,
                        child: _busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: AdaptiveActivityIndicator(size: 18),
                              )
                            : const Text('Recover'),
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
