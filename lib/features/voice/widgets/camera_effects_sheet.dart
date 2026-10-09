/// Picking a camera and an effect, with a live preview, **before** any of it is
/// sent anywhere.
///
/// Joining a call stays one tap — selecting a channel never joins it, and
/// joining is the button. This opens when the camera is turned *on* instead, so
/// nobody is made to walk past a device check to join a call they only want to
/// listen to. The choice is remembered, so turning the camera on is one tap
/// after the first time.
///
/// Nothing here is published: the preview is a camera of its own, and the sheet
/// can be opened from Settings with no call in progress at all.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/platform_info.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/voice/voice_engine.dart';
import '../../../core/voice/voice_video_view.dart';
import '../../../core/widgets/adaptive.dart';
import 'device_tile.dart';

/// Shows the sheet, returning the chosen options or null if it was cancelled.
///
/// [confirmLabel] is what the button says — "Turn camera on" from a call,
/// "Done" from Settings, where there is nothing to turn on.
Future<VoiceCameraOptions?> showCameraEffectsSheet(
  BuildContext context, {
  required VoiceCameraOptions initial,
  required String confirmLabel,
}) {
  final sheet = _CameraEffectsSheet(
    initial: initial,
    confirmLabel: confirmLabel,
  );

  // The same split as the member menu: a dialog where there is a pointer, a
  // bottom sheet where there is a thumb.
  if (isDesktopPlatform) {
    return showDialog<VoiceCameraOptions>(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: sheet,
        ),
      ),
    );
  }

  return showModalBottomSheet<VoiceCameraOptions>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => sheet,
  );
}

class _CameraEffectsSheet extends ConsumerStatefulWidget {
  const _CameraEffectsSheet({required this.initial, required this.confirmLabel});

  final VoiceCameraOptions initial;
  final String confirmLabel;

  @override
  ConsumerState<_CameraEffectsSheet> createState() =>
      _CameraEffectsSheetState();
}

class _CameraEffectsSheetState extends ConsumerState<_CameraEffectsSheet> {
  late VoiceCameraOptions _options = widget.initial;
  VoiceCameraPreview? _preview;
  List<VideoDevice>? _cameras;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    // The preview holds a real camera; it has to be released even if the sheet
    // is dismissed by a back gesture rather than either button.
    unawaitedDispose(_preview);
    super.dispose();
  }

  Future<void> _start() async {
    try {
      final cameras = await videoInputDevices();
      if (!mounted) return;
      setState(() => _cameras = cameras);

      final preview = await openCameraPreview(_options);
      if (!mounted) {
        await preview.dispose();
        return;
      }
      setState(() => _preview = preview);
    } on Object catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _change(VoiceCameraOptions next) async {
    setState(() => _options = next);

    // Every change is applied to the preview at once — the preview *is* the
    // confirmation, so there is nothing to apply on the way out.
    try {
      await _preview?.apply(next);
      if (mounted) setState(() {});
    } on Object catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectsAvailable = canUseCameraEffects;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Camera', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _Preview(preview: _preview, error: _error),
            const SizedBox(height: 8),
            if (canChooseCamera)
              DeviceTile(
                title: 'Camera',
                icon: Icons.videocam_outlined,
                defaultLabel: 'Default camera',
                devices: _cameras
                    ?.map((c) => DeviceChoice(id: c.id, label: c.label))
                    .toList(),
                selectedId: _options.deviceId,
                onChanged: (id) =>
                    _change(_options.copyWith(deviceId: () => id)),
              ),
            ListTile(
              leading: const Icon(Icons.hd_outlined),
              title: const Text('Quality'),
              subtitle: const Text('Higher costs everybody more bandwidth'),
              trailing: DropdownButton<VoiceVideoQuality>(
                value: _options.quality,
                underline: const SizedBox.shrink(),
                items: [
                  for (final quality in VoiceVideoQuality.values)
                    DropdownMenuItem(
                      value: quality,
                      child: Text(quality.label),
                    ),
                ],
                onChanged: (quality) => quality == null
                    ? null
                    : _change(_options.copyWith(quality: quality)),
              ),
            ),
            const Divider(height: 24),
            Text('Background', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _EffectPicker(
              effect: _options.effect,
              available: effectsAvailable,
              onChanged: (effect) =>
                  _change(_options.copyWith(effect: effect)),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _error != null
                      ? null
                      : () => Navigator.of(context).pop(_options),
                  child: Text(widget.confirmLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Releases a preview without making [State.dispose] async.
void unawaitedDispose(VoiceCameraPreview? preview) {
  if (preview != null) preview.dispose().ignore();
}

class _Preview extends StatelessWidget {
  const _Preview({required this.preview, required this.error});

  final VoiceCameraPreview? preview;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: context.surfaces.raised,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: switch ((error, preview)) {
            (final String reason, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.videocam_off_outlined,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your camera could not be opened.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reason,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            (null, final VoiceCameraPreview live) => VoiceVideoView(
              feed: live.feed,
            ),
            _ => const Center(child: AdaptiveActivityIndicator()),
          },
        ),
      ),
    );
  }
}

class _EffectPicker extends StatelessWidget {
  const _EffectPicker({
    required this.effect,
    required this.available,
    required this.onChanged,
  });

  final VoiceCameraEffect effect;
  final bool available;
  final ValueChanged<VoiceCameraEffect> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<VoiceCameraEffectKind>(
          segments: const [
            ButtonSegment(
              value: VoiceCameraEffectKind.none,
              label: Text('None'),
              icon: Icon(Icons.block_outlined),
            ),
            ButtonSegment(
              value: VoiceCameraEffectKind.blur,
              label: Text('Blur'),
              icon: Icon(Icons.blur_on_outlined),
            ),
            ButtonSegment(
              value: VoiceCameraEffectKind.replace,
              label: Text('Picture'),
              icon: Icon(Icons.image_outlined),
            ),
          ],
          selected: {effect.kind},
          // Disabled rather than hidden, and with the reason below: somebody
          // looking for background blur should find out it is not available
          // here, not be left wondering where it went.
          onSelectionChanged: available
              ? (selected) => onChanged(effect.copyWith(kind: selected.first))
              : null,
        ),
        if (!available) ...[
          const SizedBox(height: 6),
          Text(
            'Background blur and background replacement are not available on '
            'this platform yet. Your camera still works.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (available && effect.kind == VoiceCameraEffectKind.blur) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.blur_linear_outlined, size: 18),
              Expanded(
                child: Slider.adaptive(
                  value: effect.strength,
                  divisions: 20,
                  label: '${(effect.strength * 100).round()}%',
                  onChanged: (strength) =>
                      onChanged(effect.copyWith(strength: strength)),
                ),
              ),
              const Icon(Icons.blur_on, size: 18),
            ],
          ),
        ],
      ],
    );
  }
}
