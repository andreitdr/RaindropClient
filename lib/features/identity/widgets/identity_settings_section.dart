
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/crypto/crypto_engine.dart';
import '../../../core/crypto/identity_crypto.dart';
import '../../../core/crypto/totp.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/platform/platform_info.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/adaptive.dart';
import '../../security/widgets/link_code_scanner.dart';
import '../../security/widgets/recovery_words_dialog.dart';
import '../../servers/controllers/servers_controller.dart';
import '../../servers/controllers/session_controller.dart';
import '../controllers/app_lock.dart';
import '../controllers/identity_controller.dart';
import '../controllers/pairing.dart';
import '../controllers/vault_sync.dart';
import 'lock_gate.dart';

/// Settings → Identity & devices: everything that belongs to the person
/// rather than to one server. Their devices, pairing another, the recovery
/// words, the authenticator, and how this device is unlocked.
class IdentitySettingsSection extends ConsumerWidget {
  const IdentitySettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(identityProvider).valueOrNull;
    final vault = ref.watch(vaultProvider);
    final installId = ref.watch(installIdProvider).valueOrNull;
    if (identity == null) return const SizedBox.shrink();

    final devices = vault.devices.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final holdsAuthenticator = identity.authenticatorSecret != null;
    final accountHasAuthenticator = vault.authenticatorId.isNotEmpty;

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: Icon(_platformIcon(currentPlatform.name)),
            title: Text(deviceName(ref.watch(appPrefsProvider))),
            subtitle: const Text('This device'),
            trailing: IconButton(
              tooltip: 'Rename',
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => _rename(context, ref),
            ),
          ),
          for (final device in devices)
            if (device.installId != installId)
              ListTile(
                leading: Icon(_platformIcon(device.platform)),
                title: Text(device.name),
                subtitle: const Text('Paired'),
              ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.add_link),
            title: const Text('Pair a device'),
            subtitle: const Text('Enter or scan the code the new device shows'),
            onTap: () => _pair(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.key),
            title: const Text('New recovery words'),
            subtitle: const Text(
              'The way back in if every device is lost. Replaces your '
              'current words.',
            ),
            onTap: () => _newRecoveryWords(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Authenticator'),
            subtitle: Text(
              holdsAuthenticator
                  ? 'On. A device added with your recovery words needs a code.'
                  : accountHasAuthenticator
                  ? 'On, but this device does not hold it. Replace it to '
                        'manage it from here.'
                  : 'Off. Anyone who learns your recovery words could add '
                        'a device.',
            ),
            trailing: holdsAuthenticator
                ? TextButton(
                    onPressed: () => _removeAuthenticator(context, ref),
                    child: const Text('Remove'),
                  )
                : null,
            onTap: () => _setUpAuthenticator(context, ref),
          ),
          const _AppLockTile(),
        ],
      ),
    );
  }

  static IconData _platformIcon(String platform) => switch (platform) {
    'ios' || 'android' => Icons.smartphone,
    'macos' || 'windows' || 'linux' => Icons.computer,
    _ => Icons.devices,
  };

  static void _snack(BuildContext context, String message) =>
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(message)));

  /// Every server this device is signed in to right now. A server that does
  /// not answer within a few seconds is left out rather than waited for.
  static Future<List<ServerSession>> _sessions(WidgetRef ref) async {
    final sessions = <ServerSession>[];
    for (final server in ref.read(serversControllerProvider)) {
      try {
        final session = await ref
            .read(serverSessionProvider(server.id).future)
            .timeout(const Duration(seconds: 8));
        if (session != null) sessions.add(session);
      } on Object {
        // Unreachable, or not signed in: it catches up when it next opens.
      }
    }
    return sessions;
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final prefs = ref.read(appPrefsProvider);
    final name = await _ask(
      context,
      title: 'Name this device',
      label: 'Name',
      initial: deviceName(prefs),
      action: 'Save',
    );
    if (name == null || name.trim().isEmpty) return;
    await prefs.setDeviceName(name.trim());
    for (final session in await _sessions(ref)) {
      await ref.read(vaultProvider.notifier).sync(session);
    }
  }

  // ── Pairing ──

  Future<void> _pair(BuildContext context, WidgetRef ref) async {
    final text = await _ask(
      context,
      title: 'Pair a device',
      label: 'Pairing code',
      action: 'Continue',
      scan: canScanCodes
          ? () => scanCode(
              context,
              accepts: (text) => PairingCode.tryParse(text) != null,
            )
          : null,
    );
    if (text == null || !context.mounted) return;
    final code = PairingCode.tryParse(text);
    if (code == null) {
      _snack(context, 'That is not a pairing code.');
      return;
    }

    try {
      // The new device left its offer on one server it was told about; it
      // has to be one this device is on, and the code does not say which.
      ServerSession? relay;
      Uint8List? offer;
      for (final session in await _sessions(ref)) {
        try {
          offer = await session.e2eeApi.pairingOffer(
            session.token,
            code.pairingId,
          );
          relay = session;
          break;
        } on ApiException catch (e) {
          if (e.code != 'pairing_not_found') rethrow;
        }
      }
      if (relay == null || offer == null) {
        if (context.mounted) {
          _snack(
            context,
            'No server you are signed in to has that code. Check it, and '
            'that the new device used one of your servers. Codes last five '
            'minutes.',
          );
        }
        return;
      }

      final asking = await IdentityCrypto.readPairingOffer(
        offer,
        code.commitment,
      );
      if (!context.mounted) return;
      final confirmed = await showAdaptiveConfirm(
        context,
        title: 'Pair "${asking.deviceName}"?',
        message:
            'It will be able to sign in to every server you are on, read '
            'new messages and pair further devices. Only continue if this '
            'is your device and you are looking at the code on its screen.',
        confirmLabel: 'Pair',
      );
      if (!confirmed || !context.mounted) return;
      if (!await confirmUnlock(context, ref, reason: 'Pair a device')) return;

      final identity = await ref.read(identityProvider.future);
      if (identity == null) return;
      final payload = PairingPayload(
        identity: identity,
        vault: await ref.read(vaultProvider.notifier).current(),
      );
      await relay.e2eeApi.approvePairing(
        relay.token,
        code.pairingId,
        await IdentityCrypto.approvePairing(
          offer: offer,
          commitment: code.commitment,
          payload: payload.toBytes(),
        ),
      );
      if (context.mounted) {
        _snack(context, '"${asking.deviceName}" is being paired.');
      }
    } on CryptoException catch (e) {
      if (!context.mounted) return;
      _snack(
        context,
        e.kind == CryptoErrorKind.verification
            ? 'That code does not match the device asking to pair. Do not '
                  'pair it: check the code, or start again on the new device.'
            : e.message,
      );
    } on ApiException catch (e) {
      if (context.mounted) _snack(context, e.message);
    }
  }

  // ── Recovery words ──

  Future<void> _newRecoveryWords(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAdaptiveConfirm(
      context,
      title: 'Make new recovery words?',
      message:
          'Your current words stop working on each server as this device '
          'next reaches it.',
      confirmLabel: 'Continue',
    );
    if (!confirmed || !context.mounted) return;
    if (!await confirmUnlock(context, ref, reason: 'Show recovery words')) {
      return;
    }
    final words = await ref.read(identityProvider.notifier).newRecoveryKey();
    if (context.mounted) await showRecoveryWordsDialog(context, words);
    // Each server's copy of the sealed root is replaced with one the new
    // words open.
    for (final session in await _sessions(ref)) {
      await ref.read(vaultProvider.notifier).sync(session);
    }
  }

  // ── Authenticator ──

  Future<void> _setUpAuthenticator(BuildContext context, WidgetRef ref) async {
    if (!await confirmUnlock(context, ref, reason: 'Set up an authenticator')) {
      return;
    }
    if (!context.mounted) return;
    final secret = await showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _AuthenticatorDialog(),
    );
    if (secret == null || !context.mounted) return;

    final backupCodes = Totp.newBackupCodes();
    final sessions = await _sessions(ref);
    var enrolled = 0;
    ApiException? failure;
    for (final session in sessions) {
      try {
        await session.e2eeApi.enrollAuthenticator(
          session.token,
          secret: secret,
          code: Totp.code(secret),
          backupCodes: backupCodes,
        );
        enrolled++;
      } on ApiException catch (e) {
        failure = e;
      }
    }
    if (enrolled == 0 && sessions.isNotEmpty) {
      if (context.mounted) {
        _snack(context, failure?.message ?? 'No server could be reached.');
      }
      return;
    }

    await ref.read(identityProvider.notifier).setAuthenticator(secret);
    ref.read(vaultProvider.notifier).markAuthenticator(secret);
    for (final session in sessions) {
      await ref.read(vaultProvider.notifier).sync(session);
    }
    if (context.mounted) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _BackupCodesDialog(codes: backupCodes),
      );
    }
  }

  Future<void> _removeAuthenticator(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAdaptiveConfirm(
      context,
      title: 'Remove the authenticator?',
      message:
          'Your recovery words alone will then be enough to add a device '
          'to your accounts.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    if (!await confirmUnlock(
      context,
      ref,
      reason: 'Remove the authenticator',
    )) {
      return;
    }

    final sessions = await _sessions(ref);
    for (final session in sessions) {
      try {
        await session.e2eeApi.disableAuthenticator(session.token);
      } on ApiException {
        // A server that could not be reached keeps asking for a code until
        // an authenticator is set up again and replaces it there.
      }
    }
    await ref.read(identityProvider.notifier).setAuthenticator(null);
    ref.read(vaultProvider.notifier).markAuthenticator(null);
    for (final session in sessions) {
      await ref.read(vaultProvider.notifier).sync(session);
    }
  }
}

/// One line of text from the person, with an optional scan button.
Future<String?> _ask(
  BuildContext context, {
  required String title,
  required String label,
  required String action,
  String initial = '',
  Future<String?> Function()? scan,
}) async {
  final controller = TextEditingController(text: initial);
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        autocorrect: false,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: scan == null
              ? null
              : IconButton(
                  tooltip: 'Scan',
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () async {
                    final scanned = await scan();
                    if (scanned != null && context.mounted) {
                      Navigator.pop(context, scanned);
                    }
                  },
                ),
        ),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: Text(action),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

/// Makes a new authenticator secret, shows it for an authenticator app to
/// take, and returns it once the person has typed a code that proves the app
/// has it — so a secret nobody's app holds is never enrolled.
class _AuthenticatorDialog extends StatefulWidget {
  const _AuthenticatorDialog();

  @override
  State<_AuthenticatorDialog> createState() => _AuthenticatorDialogState();
}

class _AuthenticatorDialogState extends State<_AuthenticatorDialog> {
  final _secret = Totp.newSecret();
  final _code = TextEditingController();
  bool _wrong = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    final typed = _code.text.replaceAll(RegExp(r'\s'), '');
    final now = DateTime.now();
    // A code typed just as it changed is still the person's.
    final ok = [
      now,
      now.subtract(const Duration(seconds: Totp.stepSeconds)),
    ].any((at) => Totp.code(_secret, at: at) == typed);
    if (ok) {
      Navigator.pop(context, _secret);
    } else {
      setState(() => _wrong = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final key = Totp.base32(_secret);
    return AlertDialog(
      title: const Text('Set up an authenticator'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Scan this with an authenticator app, or type the key into '
                'it. Then enter the 6-digit code the app shows.',
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(8),
                  child: QrImageView(
                    data: Totp.provisioningUri(_secret).toString(),
                    size: 180,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                key,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              TextButton.icon(
                onPressed: () => Clipboard.setData(ClipboardData(text: key)),
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy key'),
              ),
              TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Code',
                  errorText: _wrong ? 'That code does not match.' : null,
                ),
                onSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Turn on')),
      ],
    );
  }
}

/// Shows the one-time backup codes once.
class _BackupCodesDialog extends StatelessWidget {
  const _BackupCodesDialog({required this.codes});

  final List<String> codes;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Save your backup codes'),
    content: SizedBox(
      width: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Each works once in place of an authenticator code, if you lose '
            'the authenticator and every device. They are not shown again. '
            'Keep them apart from your recovery words.',
          ),
          const SizedBox(height: 12),
          SelectableText(
            codes.join('\n'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'monospace', height: 1.5),
          ),
          TextButton.icon(
            onPressed: () =>
                Clipboard.setData(ClipboardData(text: codes.join('\n'))),
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy'),
          ),
        ],
      ),
    ),
    actions: [
      FilledButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('I saved them'),
      ),
    ],
  );
}

/// How this device is unlocked, and changing the PIN where it is a PIN.
class _AppLockTile extends ConsumerStatefulWidget {
  const _AppLockTile();

  @override
  ConsumerState<_AppLockTile> createState() => _AppLockTileState();
}

class _AppLockTileState extends ConsumerState<_AppLockTile> {
  UnlockMethod? _method;

  @override
  void initState() {
    super.initState();
    ref.read(appLockProvider.notifier).method().then((method) {
      if (mounted) setState(() => _method = method);
    });
  }

  Future<void> _changePin() async {
    if (!await confirmUnlock(context, ref, reason: 'Change your PIN')) return;
    if (!mounted) return;
    final pin = await _ask(
      context,
      title: 'New PIN',
      label: 'At least 6 characters',
      action: 'Set PIN',
    );
    if (pin == null || !mounted) return;
    final problem = validatePin(pin);
    if (problem != null) {
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(problem)));
      return;
    }
    await ref.read(appLockProvider.notifier).setPin(pin);
  }

  @override
  Widget build(BuildContext context) => ListTile(
    leading: const Icon(Icons.lock_outline),
    title: const Text('App lock'),
    subtitle: Text(switch (_method) {
      UnlockMethod.system =>
        "Unlocked with this device's fingerprint, face or passcode.",
      UnlockMethod.pin => 'Unlocked with your Raindrop PIN.',
      _ => 'Checking…',
    }),
    trailing: _method == UnlockMethod.pin
        ? TextButton(onPressed: _changePin, child: const Text('Change PIN'))
        : null,
  );
}
