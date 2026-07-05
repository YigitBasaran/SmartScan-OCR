import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartscanocr/core/widgets/page_thumbnail.dart';
import 'package:smartscanocr/features/documents/domain/entities/ocr_status.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_document.dart';

/// A card in the library grid showing a document's thumbnail + metadata.
class DocumentCard extends StatelessWidget {
  const DocumentCard({super.key, required this.document, required this.onTap});

  final ScannedDocument document;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumbnail = document.thumbnailPath;
    final pageLabel =
        '${document.pageCount} page${document.pageCount == 1 ? '' : 's'}';

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: thumbnail == null
                  ? ColoredBox(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.description_outlined,
                        size: 40,
                        color: theme.colorScheme.outline,
                      ),
                    )
                  : PageThumbnail(path: thumbnail),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat.yMMMd().format(document.createdAt)} · $pageLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OcrStatusChip(status: document.ocrStatus),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small chip indicating a document's OCR status.
class OcrStatusChip extends StatelessWidget {
  const OcrStatusChip({super.key, required this.status});

  final OcrStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg, IconData icon) = switch (status) {
      OcrStatus.done => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        Icons.text_fields,
      ),
      OcrStatus.partial => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
        Icons.text_fields,
      ),
      OcrStatus.failed => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        Icons.error_outline,
      ),
      _ => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
        Icons.hourglass_empty,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              status.label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
