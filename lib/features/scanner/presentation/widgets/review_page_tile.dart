import 'package:flutter/material.dart';
import 'package:smartscanocr/core/widgets/page_thumbnail.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_page.dart';

/// A row in the review list: thumbnail + page number + rotate/delete + drag handle.
class ReviewPageTile extends StatelessWidget {
  const ReviewPageTile({
    super.key,
    required this.page,
    required this.index,
    required this.onRotate,
    required this.onDelete,
    required this.onEdit,
  });

  final ScannedPage page;
  final int index;
  final VoidCallback onRotate;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 52,
                height: 68,
                child: PageThumbnail(
                  path: page.effectiveImagePath,
                  quarterTurns: page.displayQuarterTurns,
                  filter: page.displayFilter,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Page ${index + 1}',
                style: theme.textTheme.titleMedium,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: 'Edit page',
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.rotate_right),
              tooltip: 'Rotate',
              onPressed: onRotate,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.drag_handle,
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
