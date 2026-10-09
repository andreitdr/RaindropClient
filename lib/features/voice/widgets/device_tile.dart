/// A dropdown of media devices, shared by Settings and the camera sheet.
///
/// Extracted from the voice settings section when the camera sheet needed the
/// same row, unchanged: the "System default" entry, the clamped labels, and —
/// the part worth keeping — a synthetic row for a device that was chosen and
/// has since been unplugged, so it still reads as chosen rather than silently
/// becoming the default.
library;

import 'package:flutter/material.dart';

import '../../../core/widgets/adaptive.dart';

/// One device in a [DeviceTile], whichever kind it is.
///
/// A plain pair rather than the engine's `AudioDevice`/`VideoDevice`, so one
/// widget serves both without knowing which it is looking at.
class DeviceChoice {
  const DeviceChoice({required this.id, required this.label});

  final String id;
  final String label;
}

class DeviceTile extends StatelessWidget {
  const DeviceTile({
    super.key,
    required this.title,
    required this.icon,
    required this.devices,
    required this.selectedId,
    required this.onChanged,
    this.defaultLabel = 'System default',
  });

  final String title;
  final IconData icon;

  /// Null while the list is still being read.
  final List<DeviceChoice>? devices;
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final String defaultLabel;

  @override
  Widget build(BuildContext context) {
    final list = devices ?? const <DeviceChoice>[];
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
                DropdownMenuItem(value: null, child: Text(defaultLabel)),
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
