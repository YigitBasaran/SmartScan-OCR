import 'package:flutter/material.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_document.dart';

/// Shows recognized OCR text grouped per page.
class OcrTextSection extends StatelessWidget {
  const OcrTextSection({super.key, required this.document});

  final ScannedDocument document;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (document.pages.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < document.pages.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Page ${i + 1}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                if (document.pages[i].hasText)
                  SelectableText(
                    document.pages[i].ocrText!,
                    style: theme.textTheme.bodyMedium,
                  )
                else
                  Text(
                    'No text found on this page.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
