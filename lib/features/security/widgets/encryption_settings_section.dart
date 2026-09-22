import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/crypto/crypto_engine.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/platform/platform_info.dart';
import '../../../core/widgets/adaptive.dart';
import '../controllers/device_setup_controller.dart';
import 'link_code_scanner.dart';
import 'recovery_words_dialog.dart';

/// The Encryption section of Settings for one server: this device, the
/// account's other devices, linking a new one, and the recovery key.
class EncryptionSettingsSection extends ConsumerWidget {
  const EncryptionSettingsSection({
    super.key,
    required this.serverId,
    required this.serverName,
  });

  final String serverId;
  final String serverName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setup = ref.watch(deviceSetupProvider(serverId));

    return Card(
      margin: EdgeInsets.zero,
      child: setup.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: AdaptiveActivityIndicator()),
        ),
        error: (e, _) => ListTile(
          leading: const Icon(Icons.error_outline),
          title: Text('Encryption on $serverName is unavailable'),
          subtitle: Text('$e'),
        ),
        data: (state) => switch (state) {
          DeviceSetupUnsupported() => ListTile(
            leading: const Icon(Icons.lock_open),
            title: Text('$serverName does not offer end-to-end encryption'),
          ),
          DeviceSetupReady(:final device) => _ReadyBody(
            serverId: serverId,
            serverName: serverName,
            device: device,
          ),
          _ => ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('This device is not set up yet'),
            subtitle: Text('Open $serverName to set it up.'),
          ),
        },
      ),
    );
  }
}

class _ReadyBody extends ConsumerWidget {
  const _ReadyBody({
    required this.serverId,
    required this.serverName,
    required this.device,
  });

  final String serverId;
  final String serverName;
  final DeviceKeys device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(ownDevicesProvider(serverId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: const Icon(Icons.lock),
          title: Text('End-to-end encrypted on $serverName'),
          subtitle: Text(
            'Your identity: ${identityFingerprint(device.userIdentityKey)}',
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
        const Divider(height: 1),
        ...devices.when(
          loading: () => const [
            Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: AdaptiveActivityIndicator()),
            ),
          ],
          error: (e, _) => [
            ListTile(title: Text('Could not list devices: $e')),
          ],
          data: (list) => [
            for (final d in list)
              ListTile(
                leading: const Icon(Icons.devices),
                title: Text(
                  d.deviceId == device.deviceId
                      ? 'This device'
                      : 'Device ${d.deviceId.substring(0, 8)}',
                ),
                subtitle: Text('Added ${_date(d.createdAtUtc)}'),
                trailing: d.deviceId == device.deviceId
                    ? null
                    : IconButton(
                        tooltip: 'Remove',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _revoke(context, ref, d.deviceId),
                      ),
              ),
          ],
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.add_link),
          title: const Text('Link a new device'),
          subtitle: const Text('Enter the code the new device shows'),
          onTap: () => _link(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.key),
          title: const Text('New recovery key'),
          subtitle: const Text('Replaces your current recovery key'),
          onTap: () => _newRecoveryKey(context, ref),
        ),
      ],
    );
  }

  static String _date(DateTime utc) {
    final local = utc.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  Future<void> _revoke(
    BuildContext context,
    WidgetRef ref,
    String deviceId,
  ) async {
    final confirmed = await showAdaptiveConfirm(
      context,
      title: 'Remove this device?',
      message:
          'It will be signed out and lose access to encrypted messages on '
          '$serverName.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await revokeDevice(ref, serverId, deviceId);
    } on ApiException catch (e) {
      if (context.mounted) _snack(context, e.message);
    }
  }

  Future<void> _link(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Link a new device'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              autofocus: !canScanCodes,
              decoration: const InputDecoration(
                labelText: 'Link code',
                hintText: 'RDL1-…',
              ),
            ),
            if (canScanCodes) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan the code'),
                onPressed: () async {
                  final scanned = await scanLinkCode(context);
                  if (scanned != null && context.mounted) {
                    Navigator.pop(context, scanned);
                  }
                },
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Link'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (code == null || code.trim().isEmpty) return;

    try {
      await ref.read(deviceSetupProvider(serverId).notifier).approveLink(code);
      if (context.mounted) _snack(context, 'The new device is being linked.');
      ref.invalidate(ownDevicesProvider(serverId));
    } on CryptoException catch (e) {
      if (!context.mounted) return;
      _snack(
        context,
        e.kind == CryptoErrorKind.verification
            ? 'That code does not match the device asking to link. Do not '
                  'link it: check the code, or start again on the new device.'
            : e.message,
      );
    } on ApiException catch (e) {
      if (context.mounted) _snack(context, e.message);
    }
  }

  Future<void> _newRecoveryKey(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAdaptiveConfirm(
      context,
      title: 'Make a new recovery key?',
      message: 'Your old recovery key will stop working.',
      confirmLabel: 'Continue',
    );
    if (!confirmed) return;
    try {
      final words = await ref
          .read(deviceSetupProvider(serverId).notifier)
          .newRecoveryKey();
      if (context.mounted) await showRecoveryWordsDialog(context, words);
    } on ApiException catch (e) {
      if (context.mounted) _snack(context, e.message);
    }
  }

  static void _snack(BuildContext context, String message) =>
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(message)));
}
