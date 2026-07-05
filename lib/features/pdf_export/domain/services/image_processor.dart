import 'dart:typed_data';

import 'package:smartscanocr/features/pdf_export/domain/entities/pdf_quality.dart';

/// A processed (oriented, resized, JPEG-encoded) page image.
class ProcessedImage {
  const ProcessedImage({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;
}

/// Prepares a page image for storage + PDF embedding.
///
/// Behind an interface so the heavy `image` decoding can be faked in tests.
abstract class ImageProcessor {
  /// Reads [sourcePath], bakes EXIF orientation, applies [rotationQuarterTurns],
  /// resizes to [PdfQuality.maxDimension] and JPEG-encodes at [PdfQuality.jpegQuality].
  Future<ProcessedImage> process(
    String sourcePath, {
    required int rotationQuarterTurns,
    required PdfQuality quality,
  });
}
