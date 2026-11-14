/// Choosing how good a shared screen is sent: automatic, or a maximum.
///
/// The same control wherever a share's quality is chosen — the desktop
/// picker, the phone's sheet, and the menu on a running share — so the words
/// for it and the rules about what may be picked live in one place.
library;

import 'package:flutter/material.dart';

import '../../../core/platform/platform_info.dart';
import '../../../core/voice/voice_engine.dart';

/// What [quality] comes to in words, for the line under the control: what
/// will really be aimed for, and that it is a ceiling rather than a promise.
String shareQualityExplanation(
  VoiceShareQuality quality,
  VoiceShareLimit limit,
) {
  final resolved = resolveShareQuality(quality, limit: limit);
  final top =
      '${resolved.resolution.label} at ${resolved.frameRate.fps} '
      'frames a second';
  return quality.isAuto
      ? 'Up to $top, as your connection allows. Anybody on a slower '
            'connection is sent a smaller version, without it costing the '
            'others theirs.'
      : 'At most $top. Anybody on a slower connection is still sent a '
            'smaller version.';
}

/// Why a share cannot be sent any better than [limit] here, or null when
/// nothing is holding it below the most a share can be.
String? shareLimitExplanation(VoiceShareLimit limit) {
  if (limit == VoiceShareLimit.none) return null;

  // Which of the two ceilings is the one that bites decides who to name.
  final platform = VoiceShareLimit.of(frameRate: maximumShareFrameRate);
  if (limit == platform) {
    return 'This device can share at up to ${limit.frameRate.fps} frames a '
        'second.';
  }
  return 'This server allows sharing at up to ${limit.resolution.label}, '
      '${limit.frameRate.fps} frames a second.';
}

/// Two menus: the size (or Auto), and — once a size is picked — the frame
/// rate. Anything above [limit] is listed but cannot be chosen, so a sharer
/// sees that it exists and that it is not theirs to have here.
class ShareQualitySelector extends StatelessWidget {
  const ShareQualitySelector({
    super.key,
    required this.quality,
    required this.limit,
    required this.onChanged,
    this.enabled = true,
  });

  final VoiceShareQuality quality;
  final VoiceShareLimit limit;
  final ValueChanged<VoiceShareQuality> onChanged;
  final bool enabled;

  /// The frame rate a newly picked size starts at: the one already chosen, or
  /// thirty — which is what Auto aims for — brought down to the limit.
  VoiceShareFrameRate get _rate =>
      VoiceShareLimit(frameRate: quality.frameRate ?? autoShareFrameRate)
          .and(limit)
          .frameRate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final faded = theme.textTheme.bodyMedium?.copyWith(
      color: theme.disabledColor,
    );

    return Wrap(
      spacing: 12,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Quality', style: theme.textTheme.bodyMedium),
        DropdownButton<VoiceShareResolution?>(
          value: quality.resolution,
          isDense: true,
          onChanged: !enabled
              ? null
              : (resolution) => onChanged(
                  resolution == null
                      ? const VoiceShareQuality.auto()
                      : VoiceShareQuality.fixed(resolution, _rate),
                ),
          items: [
            const DropdownMenuItem(value: null, child: Text('Auto')),
            for (final resolution in VoiceShareResolution.values)
              DropdownMenuItem(
                value: resolution,
                enabled: limit.allowsResolution(resolution),
                child: Text(
                  resolution.label,
                  style: limit.allowsResolution(resolution) ? null : faded,
                ),
              ),
          ],
        ),
        if (quality.resolution case final resolution?)
          DropdownButton<VoiceShareFrameRate>(
            value: quality.frameRate,
            isDense: true,
            onChanged: !enabled
                ? null
                : (rate) {
                    if (rate == null) return;
                    onChanged(VoiceShareQuality.fixed(resolution, rate));
                  },
            items: [
              for (final rate in VoiceShareFrameRate.values)
                DropdownMenuItem(
                  value: rate,
                  enabled: limit.allowsFrameRate(rate),
                  child: Text(
                    rate.label,
                    style: limit.allowsFrameRate(rate) ? null : faded,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// [ShareQualitySelector] with its two lines of explanation underneath: what
/// the choice comes to, and — when something caps it — what does.
class ShareQualityField extends StatelessWidget {
  const ShareQualityField({
    super.key,
    required this.quality,
    required this.limit,
    required this.onChanged,
  });

  final VoiceShareQuality quality;
  final VoiceShareLimit limit;
  final ValueChanged<VoiceShareQuality> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final small = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final capped = shareLimitExplanation(limit);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ShareQualitySelector(
          quality: quality,
          limit: limit,
          onChanged: onChanged,
        ),
        const SizedBox(height: 4),
        Text(shareQualityExplanation(quality, limit), style: small),
        if (capped != null) Text(capped, style: small),
      ],
    );
  }
}
