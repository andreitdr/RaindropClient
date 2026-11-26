import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/crypto/crypto_engine.dart';
import '../../../core/crypto/identity_crypto.dart';
import '../../../core/crypto/totp.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/platform/platform_info.dart';
import '../../../core/storage/identity_store.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/adaptive.dart';
import '../../security/controllers/device_setup_controller.dart';
import '../../security/controllers/recovery_watch.dart';
import '../../security/widgets/link_code_scanner.dart';
import '../../security/widgets/recovery_words_dialog.dart';
import '../../servers/controllers/servers_controller.dart';
import '../../servers/controllers/session_controller.dart';
import '../controllers/app_lock.dart';
import '../controllers/cloud_backup.dart';
import '../controllers/identity_controller.dart';
import '../controllers/pairing.dart';
import '../controllers/vault_sync.dart';
import '../emergency_kit.dart';
import '../models/recovery_check.dart';
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
    // The vault learns of a new device only at its next sync; the server's
    // list of this account's devices follows them as they come. Either
    // knowing of another device is enough.
    final otherDeviceOnAServer = ref
        .watch(serversControllerProvider)
        .where((s) => ref.exists(serverSessionProvider(s.id)))
        .any(
          (s) =>
              (ref.watch(ownDevicesProvider(s.id)).valueOrNull?.length ?? 0) >
              1,
        );
    final onlyDevice =
        !otherDeviceOnAServer && devices.every((d) => d.installId == installId);
    final checkDue = ref.watch(recoveryCheckDueProvider);
    final waits = watchKnownRecoveries(ref);

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (waits.isNotEmpty)
            _Nudge(
              icon: Icons.warning_amber_rounded,
              text:
                  'A new device is waiting to join your account on '
                  '${{for (final w in waits) w.server.displayName}.join(', ')}'
                  ' without your authenticator. Not you? Stop it, then make '
                  'new recovery words.',
              action: 'Stop',
              onPressed: () => _stopRecoveries(context, ref),
            ),
          if (checkDue)
            _Nudge(
              icon: Icons.key,
              text:
                  'Do you still have your recovery words? Check them now, '
                  'while this device still works.',
              action: 'Check',
              onPressed: () => _checkRecoveryWords(context, ref),
            ),
          if (onlyDevice)
            _Nudge(
              icon: Icons.devices_other,
              text:
                  'This is your only device. If you lose it, only your '
                  'recovery words get you back in. Pair another device to '
                  'be safe.',
              action: 'Pair',
              onPressed: () => _pair(context, ref),
            ),
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
            leading: const Icon(Icons.fact_check_outlined),
            title: const Text('Check my recovery words'),
            subtitle: const Text(
              'Type them in to make sure what you saved still works. '
              'Nothing is sent anywhere.',
            ),
            onTap: () => _checkRecoveryWords(context, ref),
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
          if (holdsAuthenticator)
            ListTile(
              leading: const Icon(Icons.password),
              title: const Text('New backup codes'),
              subtitle: const Text(
                'Codes that stand in for the authenticator if it is lost '
                'with your devices. Replaces your current ones.',
              ),
              onTap: () => _newBackupCodes(context, ref),
            ),
          const _CloudBackupTile(),
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
          codeSecret: code.codeSecret,
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
    if (context.mounted) {
      await showRecoveryWordsDialog(
        context,
        words,
        servers: _serverAddresses(ref),
      );
    }
    // Each server's copy of the sealed root is replaced with one the new
    // words open, and so is the platform backup's copy of the seed.
    for (final session in await _sessions(ref)) {
      await ref.read(vaultProvider.notifier).sync(session);
    }
    await ref.read(cloudBackupProvider.notifier).refresh();
  }

  /// Every server in the vault, as `host:port`, for the emergency kit.
  static List<String> _serverAddresses(WidgetRef ref) =>
      ref.read(vaultProvider).servers.values.map((s) => s.key).toList()..sort();

  Future<void> _checkRecoveryWords(BuildContext context, WidgetRef ref) async {
    final identity = await ref.read(identityProvider.future);
    if (identity == null || !context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _CheckRecoveryWordsDialog(identity: identity),
    );
    if (ok != true) return;
    await ref.read(recoveryCheckDueProvider.notifier).recordChecked();
    if (context.mounted) {
      _snack(context, 'Those are your current recovery words.');
    }
  }

  Future<void> _stopRecoveries(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAdaptiveConfirm(
      context,
      title: 'Stop the waiting device?',
      message:
          'It will never be let in without a code. If you started it on a '
          'new device yourself, that device then needs a code from your '
          'authenticator, a backup code, or pairing from this one.',
      confirmLabel: 'Stop it',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final failed = await cancelAllRecoveries(ref);
    if (context.mounted) {
      _snack(
        context,
        failed == 0
            ? 'Stopped. Make new recovery words if it was not you.'
            : 'Stopped, except on $failed server(s) that could not be reached.',
      );
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
    final sessions = await _enroll(context, ref, secret, backupCodes);
    if (sessions == null) return;

    await ref.read(identityProvider.notifier).setAuthenticator(secret);
    ref.read(vaultProvider.notifier).markAuthenticator(secret);
    for (final session in sessions) {
      await ref.read(vaultProvider.notifier).sync(session);
    }
    if (context.mounted) await _showBackupCodes(context, ref, backupCodes);
  }

  /// Replaces the backup codes on every server reachable now, keeping the
  /// authenticator itself: this device holds its secret, so it can compute
  /// the current code enrolling asks for.
  Future<void> _newBackupCodes(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAdaptiveConfirm(
      context,
      title: 'Make new backup codes?',
      message:
          'Your current backup codes stop working on every server this '
          'device can reach now. A server that cannot be reached keeps the '
          'old ones until you do this again.',
      confirmLabel: 'Continue',
    );
    if (!confirmed || !context.mounted) return;
    if (!await confirmUnlock(context, ref, reason: 'Make new backup codes')) {
      return;
    }
    final secret = (await ref.read(identityProvider.future))
        ?.authenticatorSecret;
    if (secret == null || !context.mounted) return;

    final backupCodes = Totp.newBackupCodes();
    final sessions = await _enroll(context, ref, secret, backupCodes);
    if (sessions == null || !context.mounted) return;
    if (sessions.isEmpty) {
      _snack(context, 'No server could be reached. Try again when online.');
      return;
    }
    await _showBackupCodes(context, ref, backupCodes);
  }

  /// Enrolls [secret] and [backupCodes] on every server this device is
  /// signed in to now. Returns those servers' sessions, or null — having
  /// said why — when there were some and none took it.
  Future<List<ServerSession>?> _enroll(
    BuildContext context,
    WidgetRef ref,
    Uint8List secret,
    List<String> backupCodes,
  ) async {
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
      return null;
    }
    return sessions;
  }

  Future<void> _showBackupCodes(
    BuildContext context,
    WidgetRef ref,
    List<String> codes,
  ) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        _BackupCodesDialog(codes: codes, servers: _serverAddresses(ref)),
  );

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
              const SizedBox(height: 8),
              Text(
                'If the app is on your phone, losing the phone loses it too. '
                'Keep the backup codes you are shown next somewhere else.',
                style: Theme.of(context).textTheme.bodySmall,
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
  const _BackupCodesDialog({required this.codes, required this.servers});

  final List<String> codes;
  final List<String> servers;

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
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: () =>
                    Clipboard.setData(ClipboardData(text: codes.join('\n'))),
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy'),
              ),
              EmergencyKitButton(
                build: () =>
                    buildEmergencyKit(backupCodes: codes, servers: servers),
              ),
            ],
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

/// Asks for all 24 recovery words and pops true once they are the current
/// ones. Compared on this device against the seed it keeps; nothing is sent.
class _CheckRecoveryWordsDialog extends StatefulWidget {
  const _CheckRecoveryWordsDialog({required this.identity});

  final ClientIdentity identity;

  @override
  State<_CheckRecoveryWordsDialog> createState() =>
      _CheckRecoveryWordsDialogState();
}

class _CheckRecoveryWordsDialogState extends State<_CheckRecoveryWordsDialog> {
  final _words = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _words.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final words = normalizeRecoveryWords(_words.text);
    if (words.split(' ').length != 24) {
      setState(() => _error = 'Enter all 24 words.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    String? error;
    try {
      if (await recoveryWordsMatch(widget.identity, words)) {
        if (mounted) Navigator.pop(context, true);
        return;
      }
      error =
          'These are not your current recovery words. If you made new ones '
          'since, use those. If you have lost them, make new ones now.';
    } on CryptoException {
      error = 'Those are not 24 valid recovery words. Check for a typo.';
    }
    if (mounted) {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Check my recovery words'),
    content: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Type the 24 words you saved. They are checked on this device '
            'only.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _words,
            enabled: !_busy,
            autofocus: true,
            minLines: 3,
            maxLines: 5,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'Recovery words',
              border: const OutlineInputBorder(),
              errorText: _error,
              errorMaxLines: 3,
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _busy ? null : _check,
        child: const Text('Check'),
      ),
    ],
  );
}

/// A highlighted line at the top of the section asking the person to do
/// something that keeps their identity recoverable.
class _Nudge extends StatelessWidget {
  const _Nudge({
    required this.icon,
    required this.text,
    required this.action,
    required this.onPressed,
  });

  final IconData icon;
  final String text;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.tertiaryContainer,
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Icon(icon, color: scheme.onTertiaryContainer),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: scheme.onTertiaryContainer),
            ),
          ),
          TextButton(onPressed: onPressed, child: Text(action)),
        ],
      ),
    );
  }
}

/// The opt-in copy of the identity in iCloud Keychain or Google's Block
/// Store. Turning it on is a trade the person makes knowingly: no words
/// needed on a new device, in exchange for trusting that account.
class _CloudBackupTile extends ConsumerWidget {
  const _CloudBackupTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backup = ref.watch(cloudBackupProvider).valueOrNull;
    if (backup == null) return const SizedBox.shrink();
    final store = backup.storeName;

    if (backup.status == CloudBackupStatus.unsupported) {
      return const ListTile(
        leading: Icon(Icons.cloud_off_outlined),
        title: Text('Cloud backup'),
        subtitle: Text(
          'Not available on Windows or Linux. Your recovery words, and the '
          'emergency kit, are the way back in here.',
        ),
      );
    }

    final on = backup.status == CloudBackupStatus.on;
    return ListTile(
      leading: const Icon(Icons.cloud_outlined),
      title: Text('Back up to $store'),
      subtitle: Text(switch (backup.status) {
        CloudBackupStatus.on =>
          'On. A new device signed in to the same account gets your '
              'identity back without the recovery words.',
        CloudBackupStatus.otherIdentity =>
          'A different Raindrop identity is backed up there. Turning this '
              'on replaces it with this one.',
        CloudBackupStatus.needsScreenLock =>
          'Set a screen lock on this phone first: without one, Google cannot '
              'encrypt the backup end to end, so none is kept.',
        CloudBackupStatus.unavailable =>
          '$store is not available to Raindrop here'
              '${backup.problem == null ? '' : ': ${backup.problem}'}.',
        _ =>
          'Off. With it on, a new device signed in to the same account gets '
              'your identity back without the recovery words.',
      }),
      trailing: AdaptiveSwitch(
        value: on,
        onChanged: (value) => value
            ? enableCloudBackup(context, ref)
            : _disable(context, ref, store),
      ),
    );
  }

  Future<void> _disable(
    BuildContext context,
    WidgetRef ref,
    String store,
  ) async {
    final confirmed = await showAdaptiveConfirm(
      context,
      title: 'Delete the backup?',
      message:
          'Your identity is removed from $store, on this device and the '
          'others signed in to it. Your recovery words still work.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed) await ref.read(cloudBackupProvider.notifier).disable();
  }
}

/// Asks the person to agree to the trade, unlocks, and turns the backup on.
Future<void> enableCloudBackup(BuildContext context, WidgetRef ref) async {
  final current = await ref.read(cloudBackupProvider.future);
  final store = current.storeName;
  if (!context.mounted) return;
  final confirmed = await showAdaptiveConfirm(
    context,
    title: 'Back up to $store?',
    message: cloudBackupExplanation(
      store,
      replacing: current.status == CloudBackupStatus.otherIdentity,
    ),
    confirmLabel: 'Back up',
  );
  if (!confirmed || !context.mounted) return;
  if (!await confirmUnlock(context, ref, reason: 'Back up your identity')) {
    return;
  }
  await ref.read(cloudBackupProvider.notifier).enable();
}

/// What the person is agreeing to, said the same way wherever it is offered.
String cloudBackupExplanation(String store, {bool replacing = false}) =>
    'A copy of your identity is kept in $store, end-to-end encrypted, and a '
    'new phone or computer signed in to the same account can restore it — '
    'no recovery words needed. That makes your Raindrop accounts as safe as '
    'that account: anyone who gets into it can restore your identity too. '
    'An authenticator, if you set one up, still guards adding the device.'
    '${replacing ? '\n\nA different Raindrop identity is backed up there now; this replaces it.' : ''}';

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
