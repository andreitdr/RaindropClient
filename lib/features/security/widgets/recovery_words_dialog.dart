import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shows a recovery key's 24 words once. They are the only way back into the
/// account's encryption if every device is lost, and they are never shown
/// again, so the dialog cannot be dismissed without confirming they were
/// saved.
Future<void> showRecoveryWordsDialog(BuildContext context, String words) =>
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _RecoveryWordsDialog(words: words),
    );

class _RecoveryWordsDialog extends StatefulWidget {
  const _RecoveryWordsDialog({required this.words});

  final String words;

  @override
  State<_RecoveryWordsDialog> createState() => _RecoveryWordsDialogState();
}

class _RecoveryWordsDialogState extends State<_RecoveryWordsDialog> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final words = widget.words.split(' ');
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Save your recovery key'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your messages are end-to-end encrypted. If you lose every '
                'device signed in to this server, these 24 words are the only '
                'way to get your encryption keys back. Write them down and keep '
                'them somewhere safe. Nobody else, including the server owner, '
                'can recover them for you, and they will not be shown again.',
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
                    for (var i = 0; i < words.length; i++)
                      SizedBox(
                        width: 120,
                        child: SelectableText(
                          '${i + 1}. ${words[i]}',
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () =>
                    Clipboard.setData(ClipboardData(text: widget.words)),
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy'),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _saved,
                onChanged: (v) => setState(() => _saved = v ?? false),
                title: const Text('I have saved my recovery key'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: _saved ? () => Navigator.of(context).pop() : null,
          child: const Text('Done'),
        ),
      ],
    );
  }
}
