import 'package:flutter/material.dart';

/// The host and port of a server, as two form fields. Used wherever the app
/// has to be told where a server is: adding one, and finding the person's
/// identity on one when pairing or recovering.
///
/// An address is not prose: no autocorrect (iOS would turn `localhost` into
/// "local host"), no suggestions, no smart punctuation, and the URL keyboard.
class ServerAddressFields extends StatelessWidget {
  const ServerAddressFields({
    super.key,
    required this.host,
    required this.port,
    this.enabled = true,
  });

  final TextEditingController host;
  final TextEditingController port;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextFormField(
        controller: host,
        enabled: enabled,
        decoration: const InputDecoration(
          labelText: 'Host',
          hintText: 'raindrop.example.com',
        ),
        autocorrect: false,
        enableSuggestions: false,
        smartDashesType: SmartDashesType.disabled,
        smartQuotesType: SmartQuotesType.disabled,
        keyboardType: TextInputType.url,
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        textInputAction: TextInputAction.next,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: port,
        enabled: enabled,
        decoration: const InputDecoration(labelText: 'Port'),
        keyboardType: TextInputType.number,
        validator: (v) {
          final n = int.tryParse(v?.trim() ?? '');
          return (n == null || n <= 0 || n > 65535)
              ? 'Enter a valid port'
              : null;
        },
        textInputAction: TextInputAction.next,
      ),
    ],
  );
}
