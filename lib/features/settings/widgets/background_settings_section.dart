import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/app_residency.dart';
import '../../../core/platform/platform_info.dart';
import '../../../core/widgets/adaptive.dart';
import '../../voice/controllers/voice_call_controller.dart';
import '../controllers/background_settings_controller.dart';
import 'settings_section_label.dart';

/// Device settings' **Background** section: whether closing the window keeps
/// Raindrop running (desktops), and whether a call is shown outside the app
/// (phones).
///
/// Each row appears only where this build can honour it — a residency that
/// is [AppResidency.available], a call host that
/// `CallSessionHost.showsCallOutsideApp` — and the section, heading
/// included, is not drawn at all where neither can.
class BackgroundSettingsSection extends ConsumerWidget {
  const BackgroundSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final residency = ref.watch(appResidencyProvider).available;
    final callSurface = ref.watch(callSessionHostProvider).showsCallOutsideApp;
    if (!residency && !callSurface) return const SizedBox.shrink();

    final settings = ref.watch(backgroundSettingsProvider);
    final controller = ref.read(backgroundSettingsProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        const SettingsSectionLabel('Background'),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              if (residency)
                _SwitchRow(
                  title: keepRunningSettingTitle,
                  subtitle: settings.keepRunningWhenClosed
                      ? keepRunningSettingDetail
                      : 'Closing the window quits Raindrop, and leaves any '
                            'call you are in.',
                  value: settings.keepRunningWhenClosed,
                  onChanged: controller.setKeepRunningWhenClosed,
                ),
              if (residency && callSurface) const Divider(height: 1),
              if (callSurface)
                _SwitchRow(
                  title: showCallSettingTitle,
                  subtitle:
                      'The call, its timer, and mute and hang-up, while '
                      'you are in another app.',
                  value: settings.showCallOutsideApp,
                  onChanged: controller.setShowCallOutsideApp,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: AdaptiveSwitch(value: value, onChanged: onChanged),
    onTap: () => onChanged(!value),
  );
}
