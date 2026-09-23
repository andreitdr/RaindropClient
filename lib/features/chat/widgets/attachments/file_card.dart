import 'dart:io';

import 'package:file_picker/file_picker.dart' as picker;
import 'package:file_selector/file_selector.dart' as selector;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/attachments_api.dart';
import '../../../../core/platform/platform_info.dart';
import '../../../../core/storage/attachment_cache.dart';
import '../../controllers/attachment_transfers.dart';
import '../../models/message.dart';
import 'attachment_previews.dart';

/// A file shown as what it is — icon, name, size — with a Save button. Every
/// type the chat does not preview looks like this, and so does any file whose
/// declared extension does not match its name, with a warning.
///
/// Received files are never opened or run by the app: saving writes the
/// decrypted file where the member chose, and what happens to it then is theirs.
class FileCard extends ConsumerStatefulWidget {
  const FileCard({super.key, required this.serverId, required this.attachment});

  final String serverId;
  final ChatAttachment attachment;

  @override
  ConsumerState<FileCard> createState() => _FileCardState();
}

class _FileCardState extends ConsumerState<FileCard> {
  double? _progress;

  Future<void> _save() async {
    final attachment = widget.attachment;
    final messenger = ScaffoldMessenger.of(context);
    final name = safeFileName(attachment.name);
    setState(() => _progress = 0);
    try {
      if (isDesktopPlatform) {
        // Asked first, so a large file is fetched only for somebody who wants it.
        final location = await selector.getSaveLocation(suggestedName: name);
        if (location == null) return;
        final file = await ref
            .read(attachmentTransfersProvider(widget.serverId))
            .open(
              attachment,
              onProgress: (p) => mounted ? setState(() => _progress = p) : null,
            );
        await file.copy(location.path);
      } else {
        // Phones save through the system's own dialog, which takes the bytes.
        final file = await ref
            .read(attachmentTransfersProvider(widget.serverId))
            .open(
              attachment,
              onProgress: (p) => mounted ? setState(() => _progress = p) : null,
            );
        final saved = await picker.FilePicker.saveFile(
          fileName: name,
          bytes: await file.readAsBytes(),
          mimeType: attachment.mimeType,
        );
        if (saved == null) return;
      }
      messenger.showSnackBar(SnackBar(content: Text('Saved $name.')));
    } on Object catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(describeAttachmentError(e))),
      );
    } finally {
      if (mounted) setState(() => _progress = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final attachment = widget.attachment;
    final unavailable = attachment.unavailable;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          child: Row(
            children: [
              Icon(
                iconForFile(attachment.extension, attachment.mimeType),
                color: scheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(attachment.name, overflow: TextOverflow.ellipsis),
                    Text(
                      unavailable
                          ? 'Not available'
                          : formatBytes(attachment.size),
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    if (attachment.extensionMismatch)
                      Text(
                        'Its type does not match its name — be careful opening it.',
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: scheme.error),
                      ),
                  ],
                ),
              ),
              if (_progress != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      value: _progress! > 0 ? _progress : null,
                    ),
                  ),
                )
              else if (!unavailable && !attachment.outgoing)
                IconButton(
                  icon: const Icon(Icons.download_rounded),
                  tooltip: 'Save',
                  onPressed: _save,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An outgoing file while it is encrypted and uploaded.
class UploadingCard extends StatelessWidget {
  const UploadingCard({super.key, required this.attachment});

  final ChatAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = attachment.progress;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                iconForFile(attachment.extension, attachment.mimeType),
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(attachment.name, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 4),
                    Text(
                      progress == null
                          ? 'Encrypting…'
                          : '${(progress * 100).round()}% of ${formatBytes(attachment.size)}',
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A file awaiting sending, as a chip above the composer.
class PendingFileChip extends StatelessWidget {
  const PendingFileChip({
    super.key,
    required this.attachment,
    required this.onRemove,
  });

  final ChatAttachment attachment;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final path = attachment.localPath;
    final isImage =
        previewKindOf(attachment.extension) == PreviewKind.image &&
        path != null;
    return InputChip(
      avatar: isImage
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.file(
                File(path),
                width: 24,
                height: 24,
                fit: BoxFit.cover,
                cacheWidth: 48,
              ),
            )
          : Icon(
              iconForFile(attachment.extension, attachment.mimeType),
              size: 18,
            ),
      label: Text(
        '${attachment.name} · ${formatBytes(attachment.size)}',
        overflow: TextOverflow.ellipsis,
      ),
      onDeleted: onRemove,
      deleteButtonTooltipMessage: 'Remove',
    );
  }
}

IconData iconForFile(String extension, String mimeType) {
  switch (previewKindOf(extension)) {
    case PreviewKind.image:
      return Icons.image_outlined;
    case PreviewKind.video:
      return Icons.movie_outlined;
    case PreviewKind.audio:
      return Icons.audiotrack_outlined;
    case PreviewKind.none:
      break;
  }
  if (mimeType.startsWith('text/')) return Icons.description_outlined;
  return switch (extension) {
    'pdf' => Icons.picture_as_pdf_outlined,
    'zip' ||
    'rar' ||
    '7z' ||
    'tar' ||
    'gz' ||
    'xz' => Icons.folder_zip_outlined,
    'doc' ||
    'docx' ||
    'odt' ||
    'rtf' ||
    'md' ||
    'txt' => Icons.description_outlined,
    'xls' || 'xlsx' || 'ods' || 'csv' => Icons.table_chart_outlined,
    'ppt' || 'pptx' || 'odp' => Icons.slideshow_outlined,
    _ => Icons.insert_drive_file_outlined,
  };
}
