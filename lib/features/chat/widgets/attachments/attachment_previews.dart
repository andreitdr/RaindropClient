import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../../core/crypto/crypto_engine.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/attachments_api.dart';
import '../../controllers/attachment_transfers.dart';
import '../../models/message.dart';
import 'file_card.dart';

/// Everything a preview needs: which file, on which server, and whether the
/// server's owner wants it loaded without being asked.
class AttachmentPreviewContext {
  const AttachmentPreviewContext({
    required this.serverId,
    required this.attachment,
    required this.autoLoad,
  });

  final String serverId;
  final ChatAttachment attachment;

  /// Small enough (`preview.autoLoadMaximumMegabytes`) to fetch and show by
  /// itself; otherwise the preview waits for a tap.
  final bool autoLoad;
}

typedef AttachmentPreviewBuilder = Widget Function(
  BuildContext context,
  AttachmentPreviewContext preview,
);

/// Which files the chat shows inline, and how — by extension. The built-in
/// previews cover images, video and audio; a plugin registers a builder for
/// its own types (a PDF page, a code snippet) with [register]. A file is
/// previewed only when a builder here knows its extension **and** the server's
/// owner lists it in `preview.extensions`; anything else is a [FileCard].
abstract final class AttachmentPreviewRegistry {
  static final _builders = <String, AttachmentPreviewBuilder>{
    for (final e in ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp'])
      e: (context, preview) => ImagePreview(preview: preview),
    for (final e in ['mp4', 'webm', 'mov', 'mkv', 'm4v'])
      e: (context, preview) => VideoPreview(preview: preview),
    for (final e in ['mp3', 'm4a', 'ogg', 'oga', 'wav', 'flac', 'opus', 'aac'])
      e: (context, preview) => AudioPreview(preview: preview),
  };

  /// Shows files with any of [extensions] (lower case, no dot) with [builder],
  /// replacing a built-in preview for the same extension.
  static void register(
    Iterable<String> extensions,
    AttachmentPreviewBuilder builder,
  ) {
    for (final extension in extensions) {
      _builders[extension.toLowerCase()] = builder;
    }
  }

  static AttachmentPreviewBuilder? builderFor(String extension) =>
      _builders[extension];
}

/// Loads the decrypted file behind a preview when asked, tracking progress and
/// failure — the part every preview shares.
mixin _LoadsAttachment<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  AttachmentPreviewContext get preview;

  File? file;
  double? progress;
  Object? error;

  bool get loading => progress != null && file == null && error == null;

  Future<File?> load() async {
    if (file != null) return file;
    setState(() {
      progress = 0;
      error = null;
    });
    try {
      final opened = await ref
          .read(attachmentTransfersProvider(preview.serverId))
          .open(
            preview.attachment,
            onProgress: (p) {
              if (mounted) setState(() => progress = p);
            },
          );
      if (mounted) setState(() => file = opened);
      return opened;
    } on Object catch (e) {
      if (mounted) setState(() => error = e);
      return null;
    }
  }
}

/// The sender's preview image of a file, decrypted in memory; null while it
/// loads, when there is none, or when it cannot be opened.
class _Thumbnail extends ConsumerWidget {
  const _Thumbnail({required this.serverId, required this.attachment});

  final String serverId;
  final ChatAttachment attachment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbnail = attachment.descriptor?.thumbnail;
    if (thumbnail == null) return const SizedBox.shrink();
    return FutureBuilder<Uint8List>(
      future: ref
          .read(attachmentTransfersProvider(serverId))
          .thumbnail(thumbnail),
      builder: (context, snapshot) => snapshot.hasData
          ? Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            )
          : const SizedBox.shrink(),
    );
  }
}

/// A frame the size the media will be, so the timeline does not jump when it
/// loads: the sender's pixel size scaled into 360 × 320 at most.
Size _frameFor(
  ChatAttachment attachment, {
  Size fallback = const Size(320, 200),
}) {
  final w = attachment.descriptor?.width;
  final h = attachment.descriptor?.height;
  if (w == null || h == null || w <= 0 || h <= 0) return fallback;
  final scale = [360 / w, 320 / h, 1.0].reduce((a, b) => a < b ? a : b);
  return Size((w * scale).clamp(80, 360), (h * scale).clamp(60, 320));
}

class _MediaFrame extends StatelessWidget {
  const _MediaFrame({required this.size, required this.child});

  final Size size;
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: SizedBox.fromSize(size: size, child: child),
    ),
  );
}

/// "Click to load 12 MB", a progress ring, or what went wrong — laid over a
/// preview that is not showing the file itself yet.
class _LoadOverlay extends StatelessWidget {
  const _LoadOverlay({
    required this.size,
    required this.progress,
    required this.error,
    required this.icon,
  });

  final int size;
  final double? progress;
  final Object? error;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Widget content = switch ((progress, error)) {
      (_, final Object e) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: scheme.error),
          const SizedBox(height: 4),
          Text(
            describeAttachmentError(e),
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurface),
          ),
        ],
      ),
      (final double p, _) => CircularProgressIndicator(value: p > 0 ? p : null),
      _ => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: scheme.onSurface),
          const SizedBox(height: 4),
          Text(formatBytes(size), style: TextStyle(color: scheme.onSurface)),
        ],
      ),
    };
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(padding: const EdgeInsets.all(12), child: content),
      ),
    );
  }
}

/// What went wrong opening a file, in words for the member.
String describeAttachmentError(Object error) => switch (error) {
  AttachmentRefused(:final message) => message,
  ApiException(code: 'attachment_not_found') =>
    'This file is no longer on the server.',
  ApiException(:final message) => message,
  CryptoException() =>
    'This file is not the one the message sent, so it was not opened.',
  _ => 'Could not open this file.',
};

// ── Images ────────────────────────────────────────────────────────────────

class ImagePreview extends ConsumerStatefulWidget {
  const ImagePreview({super.key, required this.preview});

  final AttachmentPreviewContext preview;

  @override
  ConsumerState<ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends ConsumerState<ImagePreview>
    with _LoadsAttachment {
  @override
  AttachmentPreviewContext get preview => widget.preview;

  @override
  void initState() {
    super.initState();
    // After the first frame: loading reports its progress through setState.
    if (preview.autoLoad || preview.attachment.outgoing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(load());
      });
    }
  }

  Future<void> _open() async {
    final opened = file ?? await load();
    if (opened == null || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                maxScale: 8,
                child: Center(child: Image.file(opened)),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attachment = preview.attachment;
    final shown = file;
    return Tooltip(
      message: attachment.name,
      child: InkWell(
        onTap: _open,
        borderRadius: BorderRadius.circular(8),
        child: _MediaFrame(
          size: _frameFor(attachment),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (shown != null)
                Image.file(shown, fit: BoxFit.cover, gaplessPlayback: true)
              else
                _Thumbnail(serverId: preview.serverId, attachment: attachment),
              if (shown == null)
                _LoadOverlay(
                  size: attachment.size,
                  progress: progress,
                  error: error,
                  icon: Icons.image_outlined,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Video ─────────────────────────────────────────────────────────────────

class VideoPreview extends ConsumerStatefulWidget {
  const VideoPreview({super.key, required this.preview});

  final AttachmentPreviewContext preview;

  @override
  ConsumerState<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends ConsumerState<VideoPreview>
    with _LoadsAttachment {
  Player? _player;
  VideoController? _controller;

  @override
  AttachmentPreviewContext get preview => widget.preview;

  /// Videos never play by themselves: the first tap fetches and decrypts, and
  /// only then is a player made.
  Future<void> _play() async {
    final opened = await load();
    if (opened == null || !mounted) return;
    final player = Player();
    final controller = VideoController(player);
    setState(() {
      _player = player;
      _controller = controller;
    });
    await player.open(Media(Uri.file(opened.path).toString()));
  }

  @override
  void dispose() {
    unawaited(_player?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attachment = preview.attachment;
    final controller = _controller;
    final duration = attachment.descriptor?.duration;
    return _MediaFrame(
      size: _frameFor(attachment, fallback: const Size(360, 202)),
      child: controller != null
          ? Video(controller: controller)
          : InkWell(
              onTap: loading ? null : _play,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _Thumbnail(
                    serverId: preview.serverId,
                    attachment: attachment,
                  ),
                  if (loading || error != null)
                    _LoadOverlay(
                      size: attachment.size,
                      progress: progress,
                      error: error,
                      icon: Icons.movie_outlined,
                    )
                  else
                    const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        size: 56,
                        color: Colors.white,
                      ),
                    ),
                  Positioned(
                    left: 8,
                    bottom: 6,
                    child: Text(
                      [
                        if (duration != null) _clock(duration),
                        formatBytes(attachment.size),
                      ].join(' · '),
                      style: const TextStyle(
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 4)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ── Audio ─────────────────────────────────────────────────────────────────

class AudioPreview extends ConsumerStatefulWidget {
  const AudioPreview({super.key, required this.preview});

  final AttachmentPreviewContext preview;

  @override
  ConsumerState<AudioPreview> createState() => _AudioPreviewState();
}

class _AudioPreviewState extends ConsumerState<AudioPreview>
    with _LoadsAttachment {
  Player? _player;
  final _subscriptions = <StreamSubscription<Object?>>[];
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  AttachmentPreviewContext get preview => widget.preview;

  Future<void> _toggle() async {
    if (_player case final player?) {
      await player.playOrPause();
      return;
    }
    final opened = await load();
    if (opened == null || !mounted) return;
    final player = Player();
    _subscriptions.addAll([
      player.stream.playing.listen(
        (v) => mounted ? setState(() => _playing = v) : null,
      ),
      player.stream.position.listen(
        (v) => mounted ? setState(() => _position = v) : null,
      ),
      player.stream.duration.listen(
        (v) => mounted ? setState(() => _duration = v) : null,
      ),
    ]);
    _player = player;
    await player.open(Media(Uri.file(opened.path).toString()));
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      unawaited(s.cancel());
    }
    unawaited(_player?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final attachment = preview.attachment;
    final total = _duration > Duration.zero
        ? _duration
        : (attachment.descriptor?.duration ?? Duration.zero);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
          child: Row(
            children: [
              loading
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(
                          value: (progress ?? 0) > 0 ? progress : null,
                        ),
                      ),
                    )
                  : IconButton(
                      icon: Icon(
                        _playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      color: scheme.primary,
                      tooltip: _playing ? 'Pause' : 'Play',
                      onPressed: _toggle,
                    ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(attachment.name, overflow: TextOverflow.ellipsis),
                    if (error != null)
                      Text(
                        describeAttachmentError(error!),
                        style: TextStyle(color: scheme.error, fontSize: 12),
                      )
                    else
                      Slider(
                        value: total > Duration.zero
                            ? (_position.inMilliseconds / total.inMilliseconds)
                                  .clamp(0, 1)
                                  .toDouble()
                            : 0,
                        onChanged: _player == null || total == Duration.zero
                            ? null
                            : (v) => _player!.seek(total * v),
                      ),
                  ],
                ),
              ),
              Text(
                total > Duration.zero
                    ? '${_clock(_position)} / ${_clock(total)}'
                    : formatBytes(attachment.size),
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _clock(Duration d) {
  final minutes = d.inMinutes;
  final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
  return d.inHours > 0
      ? '${d.inHours}:${(minutes % 60).toString().padLeft(2, '0')}:$seconds'
      : '$minutes:$seconds';
}

/// Every file of a message, stacked under its text: a preview when the chat
/// knows the type and the server's owner wants it shown, a [FileCard]
/// otherwise — always a file card for one whose declared extension does not
/// match its name.
class MessageAttachments extends ConsumerWidget {
  const MessageAttachments({
    super.key,
    required this.serverId,
    required this.attachments,
  });

  final String serverId;
  final List<ChatAttachment> attachments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policy = ref.watch(attachmentPolicyProvider(serverId)).valueOrNull;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final attachment in attachments)
            _tileFor(context, attachment, policy),
        ],
      ),
    );
  }

  Widget _tileFor(
    BuildContext context,
    ChatAttachment attachment,
    AttachmentPolicy? policy,
  ) {
    if (attachment.outgoing && (attachment.progress ?? 0) < 1) {
      return UploadingCard(attachment: attachment);
    }
    final builder = AttachmentPreviewRegistry.builderFor(attachment.extension);
    final wanted =
        attachment.outgoing ||
        (policy?.previews(attachment.extension) ?? false);
    if (builder == null ||
        !wanted ||
        attachment.unavailable ||
        attachment.extensionMismatch) {
      return FileCard(serverId: serverId, attachment: attachment);
    }
    return builder(
      context,
      AttachmentPreviewContext(
        serverId: serverId,
        attachment: attachment,
        autoLoad: attachment.size <= (policy?.previewAutoLoadMaximumBytes ?? 0),
      ),
    );
  }
}
