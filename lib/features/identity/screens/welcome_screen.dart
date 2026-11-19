import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/adaptive.dart';
import '../../security/widgets/recovery_words_dialog.dart';
import '../controllers/cloud_backup.dart';
import '../controllers/identity_controller.dart';
import '../models/identity_backup.dart';
import '../widgets/identity_settings_section.dart';
import 'pair_new_device_screen.dart';
import 'recover_screen.dart';

/// The first thing a fresh install shows: this device needs the person's
/// identity before it can sign in anywhere. Either they are new and it is
/// made here, or they have one already and it comes from another of their
/// devices, or — with every device gone — from their recovery words. When
/// iCloud Keychain or Google's Block Store holds a backup of it, restoring
/// that comes first.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _create() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    // The identity is about to exist, so the shell replaces this screen: what
    // comes after the words goes on the navigator, which outlives it.
    final navigator = Navigator.of(context);
    try {
      final words = await ref.read(identityProvider.notifier).create();
      if (!mounted) return;
      // The providers outlive this screen too; its ref does not.
      final container = ProviderScope.containerOf(context);
      await showRecoveryWordsDialog(context, words);
      if (container.read(cloudBackupStoreProvider) != null &&
          navigator.mounted) {
        await _offerBackup(navigator.context, container);
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not set this device up: $e';
        });
      }
    }
  }

  /// Offered once, right after the words: the person decides now, while it
  /// is in front of them, and can change it in Identity & devices later.
  static Future<void> _offerBackup(
    BuildContext context,
    ProviderContainer container,
  ) async {
    final current = await container.read(cloudBackupProvider.future);
    final store = current.storeName;
    if (current.status == CloudBackupStatus.unavailable || !context.mounted) {
      return;
    }
    final yes = await showAdaptiveConfirm(
      context,
      title: 'Also back up to $store?',
      message: cloudBackupExplanation(
        store,
        replacing: current.status == CloudBackupStatus.otherIdentity,
      ),
      confirmLabel: 'Back up',
    );
    if (yes) await container.read(cloudBackupProvider.notifier).enable();
  }

  Future<void> _restore(IdentityBackup backup) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await restoreFromBackup(ref, backup);
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not restore your identity: $e';
        });
      }
    }
  }

  void _open(Widget screen) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final restorable = ref.watch(restorableBackupProvider).valueOrNull;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Welcome to Raindrop',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'There are no passwords here. You are recognised by '
                      'your devices: this one is unlocked with your '
                      'fingerprint, face or PIN, and signs in to your servers '
                      'for you.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    if (restorable != null) ...[
                      Text(
                        'Your Raindrop identity is backed up in '
                        '${restorable.storeName}.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: _busy
                            ? null
                            : () => _restore(restorable.backup),
                        child: Text('Restore from ${restorable.storeName}'),
                      ),
                      const SizedBox(height: 16),
                    ],
                    FilledButton(
                      onPressed: _busy ? null : _create,
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: AdaptiveActivityIndicator(size: 18),
                            )
                          : const Text("I'm new to Raindrop"),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => _open(const PairNewDeviceScreen()),
                      child: const Text('I use Raindrop on another device'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => _open(const RecoverScreen()),
                      child: const Text('Use my recovery words'),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
