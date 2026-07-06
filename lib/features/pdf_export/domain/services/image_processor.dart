import 'dart:typed_data';

import 'package:smartscanocr/features/documents/domain/entities/page_filter.dart';
import 'package:smartscanocr/features/pdf_export/domain/entities/pdf_quality.dart';
import 'package:smartscanocr/features/perspective/domain/entities/document_corner.dart';

/// A processed (cropped, oriented, filtered, resized, JPEG-encoded) page image.
class ProcessedImage {
  const ProcessedImage({
    required this.bytes,
    required this.width,
    required this.height,
    this.warning,
  });

  final Uint8List bytes;
  final int width;
  final int height;

  /// Non-blocking note (e.g. perspective crop could not be applied and was
  /// skipped); null when everything applied cleanly.
  final String? warning;
}

/// Prepares a page image for storage + PDF embedding.
///
/// Behind an interface so the heavy `image` decoding can be faked in tests.
abstract class ImageProcessor {
  /// Reads [sourcePath] (the immutable original), then applies, in order:
  /// EXIF orientation → perspective crop ([cropCorners], if 4 given) → rotation
  /// ([rotationQuarterTurns]) → [filter] → resize to [PdfQuality.maxDimension] →
  /// JPEG encode at [PdfQuality.jpegQuality].
  Future<ProcessedImage> process(
    String sourcePath, {
    required int rotationQuarterTurns,
    List<DocumentCorner>? cropCorners,
    PageFilter filter = PageFilter.none,
    required PdfQuality quality,
  });
}
