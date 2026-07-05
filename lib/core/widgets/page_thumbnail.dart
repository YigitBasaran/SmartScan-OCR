import 'dart:io';

import 'package:flutter/material.dart';

/// Displays a page image from a file path, applying [quarterTurns] rotation and
/// showing a placeholder if the file is missing/unreadable.
class PageThumbnail extends StatelessWidget {
  const PageThumbnail({
    super.key,
    required this.path,
    this.quarterTurns = 0,
    this.fit = BoxFit.cover,
  });

  final String path;
  final int quarterTurns;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final image = Image.file(
      File(path),
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) => _placeholder(context),
    );
    if (quarterTurns % 4 == 0) return image;
    return RotatedBox(quarterTurns: quarterTurns, child: image);
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
