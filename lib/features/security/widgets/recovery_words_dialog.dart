import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../identity/controllers/identity_controller.dart';
import '../../identity/emergency_kit.dart';
import '../../identity/models/recovery_check.dart';

/// Shows a recovery key's 24 words once. They are the only way back in if
/// every device is lost, and they are never shown again, so the dialog
/// cannot be closed until the person has typed back a few of them — proof
/// they were written down, not just glanced at.
///
/// [servers] (`host:port`) go on the emergency kit, since recovering needs
/// one server's address.
Future<void> showRecoveryWordsDialog(
  BuildContext context,
  String words, {
  List<String> servers = const [],
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (context) => _RecoveryWordsDialog(words: words, servers: servers),
);

class _RecoveryWordsDialog extends ConsumerStatefulWidget {
  const _RecoveryWordsDialog({required this.words, required this.servers});

  final String words;
  final List<String> servers;

  @override
  ConsumerState<_RecoveryWordsDialog> createState() =>
      _RecoveryWordsDialogState();
}

class _RecoveryWordsDialogState extends ConsumerState<_RecoveryWordsDialog> {
  late final List<String> _words = widget.words.split(' ');
  late final List<int> _positions = confirmationPositions(_words.length);
  late final List<TextEditingController> _answers = [
    for (final _ in _positions) TextEditingController(),
  ];
  bool _confirming = false;
  bool _wrong = false;

  @override
  void dispose() {
    for (final answer in _answers) {
      answer.dispose();
    }
    super.dispose();
  }

  Future<void> _confirm() async {
    final right = [
      for (var i = 0; i < _positions.length; i++)
        normalizeRecoveryWord(_answers[i].text) == _words[_positions[i]],
    ].every((ok) => ok);
    if (!right) {
      setState(() => _wrong = true);
      return;
    }
    await ref.read(recoveryCheckDueProvider.notifier).recordWordsSet();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      _confirming ? 'Check you saved them' : 'Save your recovery words',
    ),
    content: SizedBox(
      width: 460,
      child: SingleChildScrollView(
        child: _confirming ? _confirmStep(context) : _wordsStep(context),
      ),
    ),
    actions: _confirming
        ? [
            TextButton(
              onPressed: () => setState(() {
                _confirming = false;
                _wrong = false;
              }),
              child: const Text('Show the words again'),
            ),
            FilledButton(onPressed: _confirm, child: const Text('Done')),
          ]
        : [
            FilledButton(
              onPressed: () => setState(() => _confirming = true),
              child: const Text('I wrote them down'),
            ),
          ],
  );

  Widget _wordsStep(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'If you lose every device you use Raindrop on, these 24 words are '
          'the only way back into your accounts. Write them down, or save '
          'and print the emergency kit, and keep them somewhere safe. Nobody '
          'else, including the owners of your servers, can recover them for '
          'you, and they will not be shown again.',
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _words.length; i++)
                SizedBox(
                  width: 120,
                  child: SelectableText(
                    '${i + 1}. ${_words[i]}',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            TextButton.icon(
              onPressed: () =>
                  Clipboard.setData(ClipboardData(text: widget.words)),
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copy'),
            ),
            EmergencyKitButton(
              build: () =>
                  buildEmergencyKit(words: _words, servers: widget.servers),
            ),
          ],
        ),
      ],
    );
  }

  Widget _confirmStep(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text('Type these words from what you saved.'),
      const SizedBox(height: 12),
      for (var i = 0; i < _positions.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextField(
            controller: _answers[i],
            autofocus: i == 0,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: i == _positions.length - 1
                ? TextInputAction.done
                : TextInputAction.next,
            decoration: InputDecoration(labelText: 'Word ${_positions[i] + 1}'),
            onSubmitted: i == _positions.length - 1 ? (_) => _confirm() : null,
          ),
        ),
      if (_wrong)
        Text(
          'Not all of those match. Check what you wrote down, or show the '
          'words again.',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
    ],
  );
}
