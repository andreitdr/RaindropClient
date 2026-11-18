import 'package:flutter/material.dart';

import '../../identity/widgets/identity_settings_section.dart';
import '../widgets/settings_app_bar.dart';

/// Settings → Identity & devices (`/settings/identity`): what belongs to the
/// person rather than to this device or to one server — their paired
/// devices, pairing another, the recovery words, the authenticator, and how
/// this device is unlocked.
class IdentitySettingsScreen extends StatelessWidget {
  const IdentitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: settingsAppBar(context, title: const Text('Identity & devices')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [IdentitySettingsSection()],
      ),
    );
  }
}
