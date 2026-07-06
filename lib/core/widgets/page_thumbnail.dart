import 'dart:io';

import 'package:flutter/material.dart';
import 'package:smartscanocr/features/documents/domain/entities/page_filter.dart';
import 'package:smartscanocr/features/documents/presentation/widgets/page_filter_preview.dart';

/// Displays a page image from a file path, applying [quarterTurns] rotation and
/// a live [filter] preview, optionally overlaying the export watermark, and
/// showing a placeholder if the file is missing/unreadable.
class PageThumbnail extends StatelessWidget {
  const PageThumbnail({
    super.key,
    required this.path,
    this.quarterTurns = 0,
    this.filter = PageFilter.none,
    this.showWatermark = false,
    this.fit = BoxFit.cover,
  });

  final String path;
  final int quarterTurns;
  final PageFilter filter;
  final bool showWatermark;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    Widget content = Image.file(
      File(path),
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) => _placeholder(context),
    );
    content = applyFilterPreview(filter, content);
    if (quarterTurns % 4 != 0) {
      content = RotatedBox(quarterTurns: quarterTurns, child: content);
    }
    if (!showWatermark) return content;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        content,
        const Positioned(
          left: 4,
          right: 4,
          bottom: 4,
          child: _WatermarkLabel(),
        ),
      ],
    );
  }

  Widget _placeholder(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.broken_image_outlined, color: scheme.outline),
      ),
    );
  }
}

/// A faint bottom-right "Scanned with SmartScan OCR" label mirroring the PDF
/// watermark, so previews reflect what a free export looks like.
class _WatermarkLabel extends StatelessWidget {
  const _WatermarkLabel();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.bottomRight,
      child: Text(
        'Scanned with SmartScan OCR',
        maxLines: 1,
        overflow: TextOverflow.clip,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          shadows: [Shadow(blurRadius: 2, color: Colors.black87)],
        ),
      ),
    );
  }
}
