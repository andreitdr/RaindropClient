import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/adaptive.dart';
import '../models/channel_name.dart';

/// Asks for a channel name — to create a channel, or to rename one when
/// [initialName] is given — and runs [onSubmit] with it. [icon] marks which
/// kind of channel it is: `#` for text, a speaker for voice.
///
/// The dialog stays open while the request is in flight and when it fails:
/// a name the server refuses (`channel_name_taken` is the usual one, and only
/// the server can know it) is shown under the field so it can be corrected,
/// rather than closing the dialog on the way to an error banner. It closes
/// only when [onSubmit] returns.
Future<void> showChannelNameDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  required Future<void> Function(String name) onSubmit,
  String? initialName,
  IconData icon = Icons.tag,
}) => showDialog<void>(
  context: context,
  builder: (_) => _ChannelNameDialog(
    title: title,
    confirmLabel: confirmLabel,
    initialName: initialName,
    onSubmit: onSubmit,
    icon: icon,
  ),
);

class _ChannelNameDialog extends StatefulWidget {
  const _ChannelNameDialog({
    required this.title,
    required this.confirmLabel,
    required this.onSubmit,
    required this.icon,
    this.initialName,
  });

  final IconData icon;
  final String title;
  final String confirmLabel;
  final String? initialName;
  final Future<void> Function(String name) onSubmit;

  @override
  State<_ChannelNameDialog> createState() => _ChannelNameDialogState();
}

class _ChannelNameDialogState extends State<_ChannelNameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: widget.initialName);
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.onSubmit(_controller.text.trim());
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _controller,
                autofocus: true,
                enabled: !_submitting,
                maxLength: kChannelNameMaxLength,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Channel name',
                  prefixIcon: Icon(widget.icon, size: 18),
                  helperText: 'Letters, digits and _ . - only',
                  // The rule messages are full sentences; the default of one
                  // line cut them off mid-word.
                  errorMaxLines: 3,
                  counterText: '',
                ),
                // Checked as they type once they have started, so a message
                // about the last edit does not linger after it is fixed.
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: validateChannelName,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onFieldSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: scheme.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const AdaptiveActivityIndicator(size: 18)
              : Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
