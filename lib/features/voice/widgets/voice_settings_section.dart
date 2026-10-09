import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/platform_info.dart';
import '../../../core/voice/voice_engine.dart';
import 'camera_effects_sheet.dart';
import 'device_tile.dart';
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
///
/// The camera's row opens the same sheet the camera button does, so a choice
/// can be made and seen before there is any call to use it in.
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
          // Shown on every platform, unlike the audio devices: a phone's
          // front and back cameras are two devices, and the effect is a
          // choice everywhere even where it cannot yet be applied.
          ListTile(
            leading: const Icon(Icons.videocam_outlined),
            title: const Text('Camera & effects'),
            subtitle: Text(_cameraSummary(settings)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final chosen = await showCameraEffectsSheet(
                context,
                initial: settings.camera,
                confirmLabel: 'Done',
              );
              if (chosen != null) update((s) => s.withCamera(chosen));
            },
          ),
          const Divider(height: 1),
          if (canChooseAudioDevices) ...[
            DeviceTile(
              title: 'Microphone',
              icon: Icons.mic_none,
              devices: devices?.inputs.map(_choice).toList(),
              selectedId: settings.inputDeviceId,
              onChanged: (id) =>
                  update((s) => s.copyWith(inputDeviceId: () => id)),
            ),
            const Divider(height: 1),
            DeviceTile(
              title: 'Speakers',
              icon: Icons.volume_up_outlined,
              devices: devices?.outputs.map(_choice).toList(),
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

/// The remembered camera choice in words, for the settings row's subtitle.
String _cameraSummary(VoiceSettings settings) {
  final quality = settings.videoQuality.label;
  if (!canUseCameraEffects) return '$quality · effects not available here';
  return '$quality · ${settings.cameraEffect.label.toLowerCase()}';
}

/// The engine's device types are two different classes with the same shape;
/// [DeviceTile] takes one so it can serve cameras too.
DeviceChoice _choice(AudioDevice device) =>
    DeviceChoice(id: device.id, label: device.label);

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
