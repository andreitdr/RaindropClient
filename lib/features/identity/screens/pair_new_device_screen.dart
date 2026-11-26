import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/crypto/crypto_engine.dart';
import '../../../core/crypto/identity_crypto.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/e2ee_api.dart';
import '../../../core/network/raindrop_channel.dart';
import '../../../core/network/server_trust.dart';
import '../../../core/network/users_api.dart';
import '../../../core/platform/platform_info.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/adaptive.dart';
import '../controllers/identity_controller.dart';
import '../controllers/pairing.dart';
import '../controllers/vault_sync.dart';
import '../widgets/server_address_fields.dart';

/// The new device's side of pairing. It has no account anywhere, so it is
/// told one server the person is on, leaves a pairing offer there, and shows
/// a code. A device the person already uses takes the code — scanned or
/// typed, so neither needs a camera — and sends back their identity sealed to
/// this device. Every server they are on then appears here by itself.
class PairNewDeviceScreen extends ConsumerStatefulWidget {
  const PairNewDeviceScreen({super.key});

  @override
  ConsumerState<PairNewDeviceScreen> createState() =>
      _PairNewDeviceScreenState();
}

class _PairNewDeviceScreenState extends ConsumerState<PairNewDeviceScreen> {
  static const _pollInterval = Duration(seconds: 2);
  static const _lifetime = Duration(minutes: 5);

  final _formKey = GlobalKey<FormState>();
  final _host = TextEditingController();
  final _port = TextEditingController(text: '5001');

  RaindropChannel? _client;
  Timer? _poll;
  PairingCode? _code;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _poll?.cancel();
    _client?.close();
    _host.dispose();
    _port.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    _client?.close();
    final client = _client = RaindropChannel.forServer(
      host: _host.text.trim(),
      port: int.parse(_port.text.trim()),
    );
    final api = E2eeApi(client);

    try {
      // Nothing is pinned yet, so at least check the server's story holds
      // together. What protects the pairing itself is the code's commitment
      // and code secret, and the seal: this server only carries bytes it
      // cannot read or forge.
      final info = await UsersApi(client).serverInfo();
      final presented = client.pinner.observedFingerprint;
      if (presented != null && !ServerTrust.isConsistent(info, presented)) {
        throw ApiException.certificateMismatch();
      }

      final begun = await IdentityCrypto.beginPairing(
        deviceName: deviceName(ref.read(appPrefsProvider)),
        platform: currentPlatform.name,
      );
      final started = await api.startPairing(begun.offer);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _code = PairingCode(
          pairingId: started.pairingId,
          commitment: begun.commitment,
          codeSecret: begun.codeSecret,
        );
      });

      final deadline = DateTime.now().add(_lifetime);
      _poll?.cancel();
      _poll = Timer.periodic(_pollInterval, (timer) async {
        if (DateTime.now().isAfter(deadline)) {
          timer.cancel();
          if (mounted) {
            setState(() {
              _code = null;
              _error = 'The code expired. Start again for a new one.';
            });
          }
          return;
        }
        try {
          final approval = await api.takePairingApproval(
            started.pairingId,
            started.takeToken,
          );
          if (approval == null) return;
          timer.cancel();
          await _finish(
            await IdentityCrypto.completePairing(
              approval: approval,
              offer: begun.offer,
              exchangeSecret: begun.exchangeSecret,
              codeSecret: begun.codeSecret,
            ),
          );
        } on ApiException {
          // A dropped connection: try again on the next tick.
        } on CryptoException catch (e) {
          timer.cancel();
          if (mounted) {
            setState(() {
              _code = null;
              _error = 'The approval could not be opened: ${e.message}';
            });
          }
        }
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    } on CryptoException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    }
  }

  Future<void> _finish(Uint8List bytes) async {
    final payload = PairingPayload.tryFromBytes(bytes);
    if (payload == null) {
      if (mounted) {
        setState(() {
          _code = null;
          _error = 'The other device sent something this app cannot read.';
        });
      }
      return;
    }
    await ref.read(identityProvider.notifier).adopt(payload.identity);
    await ref
        .read(vaultProvider.notifier)
        .adoptServers(payload.vault, payload.identity);
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _cancel() {
    _poll?.cancel();
    setState(() => _code = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final code = _code?.toString();
    return Scaffold(
      appBar: AppBar(title: const Text('Pair this device')),
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
                    children: code == null
                        ? [
                            Text(
                              'Enter one server you already use on your '
                              'other device. The rest follow once the two '
                              'are paired.',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 20),
                            ServerAddressFields(
                              host: _host,
                              port: _port,
                              enabled: !_busy,
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: _busy ? null : _start,
                              child: _busy
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: AdaptiveActivityIndicator(
                                        size: 18,
                                      ),
                                    )
                                  : const Text('Show pairing code'),
                            ),
                          ]
                        : [
                            const Text(
                              'On a device you already use, open Settings → '
                              'Identity & devices → Pair a device, and scan '
                              'this code or type it in:',
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Container(
                                color: Colors.white,
                                padding: const EdgeInsets.all(8),
                                child: QrImageView(
                                  data: code,
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
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: SelectableText(
                                code,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () =>
                                  Clipboard.setData(ClipboardData(text: code)),
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
                                Expanded(
                                  child: Text('Waiting for your other device…'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: _cancel,
                              child: const Text('Cancel'),
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
