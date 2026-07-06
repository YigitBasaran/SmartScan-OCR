import 'package:flutter/material.dart';
import 'package:smartscanocr/core/widgets/page_thumbnail.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_page.dart';

/// Horizontal strip of page thumbnails for the document detail screen.
class DocumentPagePreview extends StatelessWidget {
  const DocumentPagePreview({super.key, required this.pages});

  final List<ScannedPage> pages;

  @override
  Widget build(BuildContext context) {
    if (pages.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: pages.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final page = pages[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 0.75,
              child: PageThumbnail(
                path: page.effectiveImagePath,
                quarterTurns: page.displayQuarterTurns,
                filter: page.displayFilter,
                showWatermark: true,
              ),
            ),
          );
        },
      ),
    );
  }
}
