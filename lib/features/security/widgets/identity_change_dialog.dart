import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/crypto/crypto_engine.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/adaptive.dart';
import '../../servers/controllers/user_lookup.dart';
import '../controllers/device_setup_controller.dart' show identityFingerprint;
import '../controllers/identity_changes.dart';

/// A 60-digit safety number as the person reads it out: groups of five digits,
/// four to a line.
String formatSafetyNumber(String digits) {
  final groups = [
    for (var i = 0; i < digits.length; i += 5)
      digits.substring(i, i + 5 > digits.length ? digits.length : i + 5),
  ];
  return [
    for (var i = 0; i < groups.length; i += 4) groups.skip(i).take(4).join(' '),
  ].join('\n');
}

/// Shows the confirmation for [change] and, only if the person picks "Accept
/// new key", accepts it: the core pins the key and releases the held messages,
/// the channels the change took this device out of are joined again, and the
/// chats are read again. "Not now" (or dismissing) changes nothing; the change
/// stays pending. Returns whether the key was accepted.
///
/// [userName] is how the app shows the user (the caller already resolved it).
Future<bool> reviewIdentityChange(
  BuildContext context, {
  required String serverId,
  required PendingIdentityChange change,
  required String userName,
}) async {
  // Taken before the dialog opens: whatever asked may be gone by the time the
  // person has answered (its banner disappears once the change is accepted).
  final container = ProviderScope.containerOf(context);
  final messenger = ScaffoldMessenger.maybeOf(context);

  final accepted = await showDialog<bool>(
    context: context,
    builder: (_) => IdentityChangeDialog(
      serverId: serverId,
      change: change,
      userName: userName,
    ),
  );
  if (accepted != true) return false;

  try {
    await container
        .read(pendingIdentityChangesProvider(serverId).notifier)
        .accept(change);
    messenger?.showSnackBar(
      SnackBar(content: Text('You now trust $userName\'s new key.')),
    );
    return true;
  } on CryptoException catch (e) {
    messenger?.showSnackBar(
      SnackBar(content: Text('Could not accept the new key: ${e.message}')),
    );
  } on ApiException catch (e) {
    messenger?.showSnackBar(SnackBar(content: Text(e.message)));
  }
  return false;
}

/// The question "do you trust [userName]'s new key?", with what the person
/// needs to answer it: the safety number they would have compared before and
/// the one for the key now presented, and what the server says. Pops `true`
/// for "Accept new key" and `false` for "Not now"; it never accepts anything
/// itself ([reviewIdentityChange] does, on `true`).
class IdentityChangeDialog extends ConsumerWidget {
  const IdentityChangeDialog({
    super.key,
    required this.serverId,
    required this.change,
    required this.userName,
  });

  final String serverId;
  final PendingIdentityChange change;
  final String userName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final evidence = ref.watch(
      identityEvidenceProvider((serverId: serverId, change: change)),
    );
    final data = evidence.valueOrNull;
    final serverDisagrees =
        data?.registeredKey != null &&
        !listEquals(data!.registeredKey, change.presentedKey);

    return AlertDialog(
      icon: Icon(
        Icons.warning_amber_rounded,
        color: serverDisagrees ? scheme.error : null,
      ),
      title: Text('$userName\'s security key changed'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This device trusted one key for $userName since it first saw '
                'them. They now present a different one. That happens when '
                'they reinstall Raindrop or restore from a backup — and it '
                'is also what somebody pretending to be them would look like.',
              ),
              const SizedBox(height: 16),
              evidence.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: AdaptiveActivityIndicator()),
                ),
                error: (e, _) => Text(
                  'The safety numbers could not be worked out: $e',
                  style: TextStyle(color: scheme.error),
                ),
                data: (data) => _Evidence(
                  change: change,
                  evidence: data,
                  userName: userName,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Compare the new safety number with $userName in person or '
                'over a call you trust — or ask them to read you the '
                '"Your identity" line under Encryption in their server '
                'settings, which should match the new key\'s fingerprint.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Text(_consequences(), key: const Key('identity-change-effects')),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Not now'),
        ),
        FilledButton(
          style: serverDisagrees
              ? FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                )
              : null,
          // Never before the numbers are on screen: accepting a key sight
          // unseen is what this dialog exists to prevent.
          onPressed: data == null ? null : () => Navigator.pop(context, true),
          child: const Text('Accept new key'),
        ),
      ],
    );
  }

  /// What each answer does, in plain words.
  String _consequences() {
    final held = change.heldMessages;
    final left = change.leftChannelIds.length;
    final accepting = StringBuffer(
      'Accepting trusts this key for $userName from now on',
    );
    if (held > 0) {
      accepting.write(
        ', shows the $held message${held == 1 ? '' : 's'} from them that '
        '${held == 1 ? 'is' : 'are'} being held',
      );
    }
    if (left > 0) {
      accepting.write(
        ', and puts this device back into $left channel'
        '${left == 1 ? '' : 's'} it was taken out of',
      );
    }
    accepting.write(
      '. Not now changes nothing: their messages stay hidden and '
      'you stay out of those channels until you decide.',
    );
    return accepting.toString();
  }
}

class _Evidence extends StatelessWidget {
  const _Evidence({
    required this.change,
    required this.evidence,
    required this.userName,
  });

  final PendingIdentityChange change;
  final IdentityEvidence evidence;
  final String userName;

  @override
  Widget build(BuildContext context) {
    final pinned = change.pinnedKey;
    final pinnedNumber = evidence.pinnedSafetyNumber;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _KeyBlock(
          label: 'Safety number you trusted until now',
          number: pinnedNumber,
          fingerprint: pinned == null ? null : identityFingerprint(pinned),
          missing: 'This device had no key for $userName.',
          numberKey: const Key('pinned-safety-number'),
        ),
        const SizedBox(height: 12),
        _KeyBlock(
          label: 'Safety number with the new key',
          number: evidence.presentedSafetyNumber,
          fingerprint: identityFingerprint(change.presentedKey),
          emphasis: true,
          numberKey: const Key('presented-safety-number'),
        ),
        const SizedBox(height: 12),
        _ServerCheck(
          evidence: evidence,
          presented: change.presentedKey,
          userName: userName,
        ),
      ],
    );
  }
}

class _KeyBlock extends StatelessWidget {
  const _KeyBlock({
    required this.label,
    required this.number,
    required this.fingerprint,
    required this.numberKey,
    this.missing,
    this.emphasis = false,
  });

  final String label;
  final String? number;
  final String? fingerprint;
  final Key numberKey;
  final String? missing;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        if (number == null)
          Text(missing ?? '', style: theme.textTheme.bodyMedium)
        else ...[
          Text(
            formatSafetyNumber(number!),
            key: numberKey,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 15,
              height: 1.4,
              fontWeight: emphasis ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          if (fingerprint != null)
            Text(
              'Key $fingerprint',
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ],
    );
  }
}

/// The server's own opinion of the user's key. The server is the party the
/// check guards against, so it can warn but never reassure on its own.
class _ServerCheck extends StatelessWidget {
  const _ServerCheck({
    required this.evidence,
    required this.presented,
    required this.userName,
  });

  final IdentityEvidence evidence;
  final Uint8List presented;
  final String userName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final registered = evidence.registeredKey;

    final (IconData icon, Color color, String text) = switch (registered) {
      null when evidence.registeredLookupFailed => (
        Icons.help_outline,
        scheme.onSurfaceVariant,
        'The server could not be asked which key it lists for $userName.',
      ),
      null => (
        Icons.help_outline,
        scheme.onSurfaceVariant,
        'The server lists no key for $userName.',
      ),
      final key when listEquals(key, presented) => (
        Icons.info_outline,
        scheme.onSurfaceVariant,
        'The server lists this same key for $userName. That alone proves '
            'nothing: the server could list any key.',
      ),
      final key => (
        Icons.report_gmailerrorred_outlined,
        scheme.error,
        'The server lists a different key for $userName '
            '(${identityFingerprint(key)}). Do not accept this one unless '
            '$userName confirms it to you directly.',
      ),
    };

    return Row(
      key: const Key('identity-server-check'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/// One pending change as a settings row: who, what is waiting, and a tap to
/// review it.
class PendingIdentityChangeTile extends ConsumerWidget {
  const PendingIdentityChangeTile({
    super.key,
    required this.serverId,
    required this.change,
  });

  final String serverId;
  final PendingIdentityChange change;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final name = displayNameFor(ref, (
      serverId: serverId,
      userId: change.userId,
    ));
    final held = change.heldMessages;
    final channels = change.channelIds.length;
    final details = [
      if (held > 0) '$held message${held == 1 ? '' : 's'} waiting',
      if (channels > 0) 'in $channels channel${channels == 1 ? '' : 's'}',
    ].join(' ');
    return ListTile(
      leading: Icon(Icons.warning_amber_rounded, color: scheme.error),
      title: Text('$name\'s security key changed'),
      subtitle: Text(
        details.isEmpty
            ? 'Review the new safety number.'
            : '$details. Review the new safety number.',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => reviewIdentityChange(
        context,
        serverId: serverId,
        change: change,
        userName: name,
      ),
    );
  }
}
