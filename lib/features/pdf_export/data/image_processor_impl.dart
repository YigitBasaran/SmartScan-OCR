import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:smartscanocr/core/errors/app_exception.dart';
import 'package:smartscanocr/features/documents/domain/entities/page_filter.dart';
import 'package:smartscanocr/features/pdf_export/domain/entities/pdf_quality.dart';
import 'package:smartscanocr/features/pdf_export/domain/services/image_processor.dart';
import 'package:smartscanocr/features/perspective/domain/corner_ordering.dart';
import 'package:smartscanocr/features/perspective/domain/entities/document_corner.dart';

/// [ImageProcessor] backed by the `image` package.
class ImageProcessorImpl implements ImageProcessor {
  @override
  Future<ProcessedImage> process(
    String sourcePath, {
    required int rotationQuarterTurns,
    List<DocumentCorner>? cropCorners,
    PageFilter filter = PageFilter.none,
    required PdfQuality quality,
  }) async {
    try {
      final bytes = await File(sourcePath).readAsBytes();
      final source = img.decodeImage(bytes);
      if (source == null) {
        // Unsupported/corrupt image (e.g. HEIC). Surface gracefully instead of
        // crashing the pipeline.
        throw const PdfGenerationFailure();
      }

      // Apply EXIF orientation so imported photos aren't sideways.
      var image = img.bakeOrientation(source);

      // Manual perspective crop (best-effort): warp the document quad to a flat
      // rectangle. Done in the EXIF-baked, un-rotated space so the editor's
      // normalized corners line up. A failure here is non-blocking.
      String? warning;
      if (cropCorners != null && cropCorners.length == 4) {
        try {
          image = _applyCrop(image, cropCorners);
        } catch (_) {
          warning = 'Perspective correction could not be applied to a page.';
        }
      }

      // Apply any pending review rotation (quarter turns, clockwise).
      final turns = rotationQuarterTurns % 4;
      if (turns != 0) {
        image = img.copyRotate(image, angle: turns * 90);
      }

      // Scan-style filter.
      image = _applyFilter(image, filter);

      // Downscale so the longest side fits the quality's max dimension. This is
      // the primary lever for keeping generated PDFs a reasonable size.
      final maxDim = quality.maxDimension;
      if (image.width > maxDim || image.height > maxDim) {
        if (image.width >= image.height) {
          image = img.copyResize(image, width: maxDim);
        } else {
          image = img.copyResize(image, height: maxDim);
        }
      }

      final jpg = img.encodeJpg(image, quality: quality.jpegQuality);
      return ProcessedImage(
        bytes: jpg,
        width: image.width,
        height: image.height,
        warning: warning,
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw PdfGenerationFailure(e);
    }
  }

  /// Warps the document quad (normalized corners) to a flat rectangle whose size
  /// matches the quad's edge lengths, using `copyRectify` (verified param order:
  /// topLeft, topRight, bottomLeft, bottomRight).
  img.Image _applyCrop(img.Image src, List<DocumentCorner> corners) {
    final w = src.width;
    final h = src.height;
    final o = orderCorners(corners);

    img.Point pt(DocumentCorner c) => img.Point(c.x * w, c.y * h);
    double dist(DocumentCorner a, DocumentCorner b) {
      final dx = (a.x - b.x) * w;
      final dy = (a.y - b.y) * h;
      return math.sqrt(dx * dx + dy * dy);
    }

    final outW = math
        .max(dist(o.topLeft, o.topRight), dist(o.bottomLeft, o.bottomRight))
        .round()
        .clamp(1, w);
    final outH = math
        .max(dist(o.topLeft, o.bottomLeft), dist(o.topRight, o.bottomRight))
        .round()
        .clamp(1, h);

    return img.copyRectify(
      src,
      topLeft: pt(o.topLeft),
      topRight: pt(o.topRight),
      bottomLeft: pt(o.bottomLeft),
      bottomRight: pt(o.bottomRight),
      interpolation: img.Interpolation.cubic,
      toImage: img.Image(width: outW, height: outH, numChannels: 3),
    );
  }

  img.Image _applyFilter(img.Image src, PageFilter filter) {
    switch (filter) {
      case PageFilter.none:
        return src;
      case PageFilter.grayscale:
        return img.grayscale(src);
      case PageFilter.blackWhite:
        // High-contrast grayscale approximates a scanned black-and-white page.
        return img.contrast(img.grayscale(src), contrast: 200);
      case PageFilter.enhance:
        return img.adjustColor(
          src,
          contrast: 1.15,
          saturation: 1.1,
          brightness: 1.03,
        );
    }
  }
}
