import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/platform_info.dart';
import '../../../core/voice/voice_engine.dart';
import '../../../core/widgets/adaptive.dart';
import '../controllers/voice_settings_controller.dart';
import '../models/voice_settings.dart';

/// The audio devices this machine has, read when the settings screen opens.
final _audioDevicesProvider =
    FutureProvider.autoDispose<
      ({List<AudioDevice> inputs, List<AudioDevice> outputs})
    >((ref) async {
      if (!canChooseAudioDevices) {
        return (inputs: const <AudioDevice>[], outputs: const <AudioDevice>[]);
      }
      return (
        inputs: await audioInputDevices(),
        outputs: await audioOutputDevices(),
      );
    });

/// The "Voice & audio" settings: which devices to use, how loud everybody is,
/// and how the microphone is cleaned up. Changes reach a call in progress
/// immediately.
///
/// There is no microphone volume: the voice library offers no input gain on
/// desktop, so automatic gain control is the way to even a quiet microphone
/// out.
class VoiceSettingsSection extends ConsumerWidget {
  const VoiceSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(voiceSettingsProvider);
    final controller = ref.read(voiceSettingsProvider.notifier);
    final devices = ref.watch(_audioDevicesProvider).valueOrNull;
    final theme = Theme.of(context);

    void update(VoiceSettings Function(VoiceSettings s) change) =>
        controller.update(change);

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          if (canChooseAudioDevices) ...[
            _DeviceTile(
              title: 'Microphone',
              icon: Icons.mic_none,
              devices: devices?.inputs,
              selectedId: settings.inputDeviceId,
              onChanged: (id) =>
                  update((s) => s.copyWith(inputDeviceId: () => id)),
            ),
            const Divider(height: 1),
            _DeviceTile(
              title: 'Speakers',
              icon: Icons.volume_up_outlined,
              devices: devices?.outputs,
              selectedId: settings.outputDeviceId,
              onChanged: (id) =>
                  update((s) => s.copyWith(outputDeviceId: () => id)),
            ),
            const Divider(height: 1),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.headphones_outlined, size: 20),
                const SizedBox(width: 16),
                Text('Output volume', style: theme.textTheme.bodyLarge),
                const Spacer(),
                Text('${(settings.outputVolume * 100).round()}%'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Slider.adaptive(
              value: settings.outputVolume,
              max: maximumVolume,
              divisions: (maximumVolume * 20).round(),
              onChanged: (value) =>
                  update((s) => s.copyWith(outputVolume: value)),
            ),
          ),
          const Divider(height: 1),
          _SwitchTile(
            title: 'Echo cancellation',
            subtitle:
                'Keeps others from hearing themselves through your speakers',
            value: settings.echoCancellation,
            onChanged: (v) => update((s) => s.copyWith(echoCancellation: v)),
          ),
          const Divider(height: 1),
          _SwitchTile(
            title: 'Noise suppression',
            subtitle: 'Filters out steady background noise',
            value: settings.noiseSuppression,
            onChanged: (v) => update((s) => s.copyWith(noiseSuppression: v)),
          ),
          const Divider(height: 1),
          _SwitchTile(
            title: 'Automatic gain control',
            subtitle: 'Evens out how loud your microphone is',
            value: settings.autoGainControl,
            onChanged: (v) => update((s) => s.copyWith(autoGainControl: v)),
          ),
        ],
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({
    required this.title,
    required this.icon,
    required this.devices,
    required this.selectedId,
    required this.onChanged,
  });

  final String title;
  final IconData icon;

  /// Null while the list is still being read.
  final List<AudioDevice>? devices;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final list = devices ?? const <AudioDevice>[];
    // A device that was chosen and has since been unplugged still shows as
    // chosen, rather than silently reading as the default.
    final known = selectedId == null || list.any((d) => d.id == selectedId);

    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: devices == null
          ? const AdaptiveActivityIndicator(size: 16)
          : DropdownButton<String?>(
              value: selectedId,
              underline: const SizedBox.shrink(),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('System default'),
                ),
                for (final device in list)
                  DropdownMenuItem(
                    value: device.id,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Text(
                        device.label.isEmpty ? 'Unnamed device' : device.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                if (!known)
                  DropdownMenuItem(
                    value: selectedId,
                    child: const Text('Disconnected device'),
                  ),
              ],
              onChanged: onChanged,
            ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
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
