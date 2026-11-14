/// Choosing what to share: a whole screen, or one window — and, for a window,
/// whether its own sound goes with it — and how good to send it.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/platform_info.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/voice/voice_engine.dart';
import '../../../core/widgets/adaptive.dart';
import '../controllers/voice_call_controller.dart';
import '../controllers/voice_settings_controller.dart';
import 'share_quality_selector.dart';

/// Lets the user pick a screen or a window to share, and returns what to share
/// — or null when they cancel. Nothing is captured until this returns.
///
/// A dialog on the desktops, which have screens and windows to choose
/// between. A sheet on a phone or a tablet, which has one thing to share and
/// so nothing to pick: what the sheet is for there is saying what *will* be
/// seen, before the system's own consent sheet asks (see
/// `sharesWholeDeviceOnly`).
///
/// **The sound checkbox is the sharer's agreement.** It starts unticked every
/// time, and again whenever another window is chosen, because agreeing to send
/// one app's sound is not agreeing to send another's. A whole screen never
/// offers it: the host's sound is never sent.
///
/// The quality is the opposite: remembered (`VoiceSettings.shareQuality`),
/// because it is a preference about this device and its connection, not an
/// agreement about what is on screen.
Future<VoiceScreenShareOptions?> showScreenSharePicker(BuildContext context) =>
    sharesWholeDeviceOnly
    ? showModalBottomSheet<VoiceScreenShareOptions>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => const _DeviceSharePicker(),
      )
    : showDialog<VoiceScreenShareOptions>(
        context: context,
        builder: (_) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760, maxHeight: 680),
            child: const _ScreenSharePicker(),
          ),
        ),
      );

/// The phone's version: no list, because there is one thing to share. It says
/// what that is — everything — and what happens next, which on both systems
/// is a sheet of the system's own that this app cannot word.
class _DeviceSharePicker extends ConsumerStatefulWidget {
  const _DeviceSharePicker();

  @override
  ConsumerState<_DeviceSharePicker> createState() => _DeviceSharePickerState();
}

class _DeviceSharePickerState extends ConsumerState<_DeviceSharePicker> {
  late VoiceShareQuality _quality = ref
      .read(voiceSettingsProvider)
      .shareQuality;

  void _share() {
    ref
        .read(voiceSettingsProvider.notifier)
        .update((settings) => settings.copyWith(shareQuality: _quality));
    Navigator.of(context).pop(
      VoiceScreenShareOptions(source: deviceScreenSource, quality: _quality),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final limit = ref.watch(voiceShareLimitProvider);
    final faded = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Share your screen', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              currentPlatform == RaindropPlatform.ios
                  ? 'Everybody in the call who chooses to watch will see '
                        'everything on your screen — other apps, '
                        'notifications, and anything you type that is not '
                        'hidden as you type it. Sound is not shared.'
                  : 'Everybody in the call who chooses to watch will see '
                        'what you share. Sharing your whole screen shows '
                        'everything on it — other apps, notifications, and '
                        'anything you type that is not hidden as you type '
                        'it. Sound is not shared.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              currentPlatform == RaindropPlatform.ios
                  ? 'Next, choose Raindrop and tap Start Broadcast. To stop, '
                        'come back here or tap the red indicator at the top '
                        'of the screen.'
                  : 'Next, Android asks what to share — one app, where it '
                        'offers that, or your whole screen. To stop, come '
                        'back here or use the notification.',
              style: faded,
            ),
            const SizedBox(height: 16),
            ShareQualityField(
              quality: _quality,
              limit: limit,
              onChanged: (quality) => setState(() => _quality = quality),
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
                FilledButton.icon(
                  onPressed: _share,
                  icon: const Icon(Icons.screen_share),
                  label: const Text('Continue'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScreenSharePicker extends ConsumerStatefulWidget {
  const _ScreenSharePicker();

  @override
  ConsumerState<_ScreenSharePicker> createState() => _ScreenSharePickerState();
}

class _ScreenSharePickerState extends ConsumerState<_ScreenSharePicker> {
  /// How good to send it: what was picked last time, until changed here.
  late VoiceShareQuality _quality = ref
      .read(voiceSettingsProvider)
      .shareQuality;

  VoiceScreenSources? _sources;
  StreamSubscription<List<VoiceScreenSource>>? _subscription;
  List<VoiceScreenSource> _listed = const [];
  String? _error;

  VoiceScreenSourceKind _kind = VoiceScreenSourceKind.screen;
  VoiceScreenSource? _chosen;

  /// Whether the chosen window's sound goes too. Reset to false whenever the
  /// choice changes.
  bool _withAudio = false;

  /// Why the chosen window's sound cannot be shared, or null when it can.
  /// Worked out once per choice: on Windows it asks the system which process
  /// owns the window and walks this process's ancestry, which is not
  /// something to redo on every frame.
  String? _audioRefusal;

  @override
  void initState() {
    super.initState();
    unawaited(_open());
  }

  Future<void> _open() async {
    try {
      final sources = await openScreenSources();
      if (!mounted) {
        await sources.dispose();
        return;
      }
      _sources = sources;
      _subscription = sources.sources.listen(_onSources);
      _onSources(sources.current);
    } on Object catch (e) {
      if (mounted) {
        setState(() => _error = 'Could not list what to share ($e).');
      }
    }
  }

  void _onSources(List<VoiceScreenSource> listed) {
    if (!mounted) return;
    setState(() {
      // Raindrop's own windows are left out: sharing one is pointless, and on
      // Windows its sound would send the call back into itself.
      _listed = [
        for (final source in listed)
          if (source.kind == VoiceScreenSourceKind.screen ||
              !isThisAppsWindow(source.id))
            source,
      ];
      // A chosen window that has gone is no longer a choice.
      if (_chosen case final chosen?
          when !_listed.any((source) => source.id == chosen.id)) {
        _choose(null);
      }
    });
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_sources?.dispose());
    super.dispose();
  }

  void _choose(VoiceScreenSource? source) {
    // The same choice again — a double click on it — keeps the box as it is.
    if (source != null && source.id == _chosen?.id) return;
    _chosen = source;
    _withAudio = false;
    _audioRefusal =
        source == null || source.kind != VoiceScreenSourceKind.window
        ? null
        : windowAudioUnavailableReason(source.id);
  }

  void _share() {
    final chosen = _chosen;
    if (chosen == null) return;

    // Checked again at the last moment. On Windows, a window that closed
    // between choosing and sharing would have its sound capture fall back to
    // everything else's — the opposite of what was agreed to.
    if (chosen.kind == VoiceScreenSourceKind.window &&
        !isWindowStillOpen(chosen.id)) {
      setState(() {
        _error = 'That window has closed. Choose something else to share.';
        _choose(null);
      });
      return;
    }

    ref
        .read(voiceSettingsProvider.notifier)
        .update((settings) => settings.copyWith(shareQuality: _quality));
    Navigator.of(context).pop(
      VoiceScreenShareOptions(
        source: chosen,
        withAudio: _withAudio && _audioRefusal == null,
        quality: _quality,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shown = [
      for (final source in _listed)
        if (source.kind == _kind) source,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Share your screen', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          SegmentedButton<VoiceScreenSourceKind>(
            segments: const [
              ButtonSegment(
                value: VoiceScreenSourceKind.screen,
                icon: Icon(Icons.desktop_windows_outlined),
                label: Text('Screens'),
              ),
              ButtonSegment(
                value: VoiceScreenSourceKind.window,
                icon: Icon(Icons.web_asset_outlined),
                label: Text('Windows'),
              ),
            ],
            selected: {_kind},
            onSelectionChanged: (selected) => setState(() {
              _kind = selected.single;
              _error = null;
              if (_chosen?.kind != _kind) _choose(null);
            }),
          ),
          const SizedBox(height: 12),
          Flexible(child: _body(context, shown)),
          const SizedBox(height: 12),
          if (_kind == VoiceScreenSourceKind.window)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _withAudio,
              onChanged: _chosen == null || _audioRefusal != null
                  ? null
                  : (value) => setState(() => _withAudio = value ?? false),
              title: const Text("Also share this window's sound"),
              subtitle: Text(
                _audioRefusal ??
                    "Only this app's sound is sent — not your other apps or "
                        'system sounds.',
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'A whole screen is shared without sound.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          if (_error case final error?)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                error,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          const SizedBox(height: 8),
          ShareQualityField(
            quality: _quality,
            limit: ref.watch(voiceShareLimitProvider),
            onChanged: (quality) => setState(() => _quality = quality),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _chosen == null ? null : _share,
                icon: const Icon(Icons.screen_share),
                label: const Text('Share'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, List<VoiceScreenSource> shown) {
    final theme = Theme.of(context);
    final sources = _sources;

    Widget message(String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );

    if (sources == null) {
      return _error == null
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: AdaptiveActivityIndicator()),
            )
          : message('Nothing can be shared right now.');
    }

    if (!sources.captureAllowed) {
      return message(
        'Raindrop is not allowed to record the screen. Allow it in System '
        'Settings → Privacy & Security → Screen & System Audio Recording, then '
        'try again.',
      );
    }

    if (shown.isEmpty) {
      return message(
        _kind == VoiceScreenSourceKind.screen
            ? 'No screens to share.'
            : 'No windows to share.',
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 16 / 12,
      ),
      itemCount: shown.length,
      itemBuilder: (context, index) {
        final source = shown[index];
        return _SourceTile(
          source: source,
          selected: _chosen?.id == source.id,
          onTap: () => setState(() {
            _error = null;
            _choose(source);
          }),
          onShare: () {
            setState(() => _choose(source));
            _share();
          },
        );
      },
    );
  }
}

/// One screen or window: what it shows, and its name.
class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.source,
    required this.selected,
    required this.onTap,
    required this.onShare,
  });

  final VoiceScreenSource source;
  final bool selected;
  final VoidCallback onTap;

  /// A double click shares it straight away, the way pickers usually work.
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumbnail = source.thumbnail;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      onDoubleTap: onShare,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: ColoredBox(
                  color: context.surfaces.rail,
                  child: thumbnail != null && thumbnail.isNotEmpty
                      ? Image.memory(
                          thumbnail,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                          errorBuilder: (_, _, _) => _placeholder(context),
                        )
                      : _placeholder(context),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              source.name.isEmpty ? 'Untitled window' : source.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) => Center(
    child: Icon(
      source.kind == VoiceScreenSourceKind.screen
          ? Icons.desktop_windows_outlined
          : Icons.web_asset_outlined,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}
