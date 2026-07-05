import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:smartscanocr/core/errors/app_exception.dart';
import 'package:smartscanocr/features/pdf_export/domain/entities/pdf_quality.dart';
import 'package:smartscanocr/features/pdf_export/domain/services/image_processor.dart';

/// [ImageProcessor] backed by the `image` package.
class ImageProcessorImpl implements ImageProcessor {
  @override
  Future<ProcessedImage> process(
    String sourcePath, {
    required int rotationQuarterTurns,
    required PdfQuality quality,
  }) async {
    try {
      final bytes = await File(sourcePath).readAsBytes();
      var decoded = img.decodeImage(bytes);
      if (decoded == null) {
        // Unsupported/corrupt image (e.g. HEIC). Surface gracefully instead of
        // crashing the pipeline.
        throw const PdfGenerationFailure();
      }

      // Apply EXIF orientation so imported photos aren't sideways.
      decoded = img.bakeOrientation(decoded);

      // Apply any pending review rotation (quarter turns, clockwise).
      final turns = rotationQuarterTurns % 4;
      if (turns != 0) {
        decoded = img.copyRotate(decoded, angle: turns * 90);
      }

      // Downscale so the longest side fits the quality's max dimension. This is
      // the primary lever for keeping generated PDFs a reasonable size.
      final maxDim = quality.maxDimension;
      if (decoded.width > maxDim || decoded.height > maxDim) {
        if (decoded.width >= decoded.height) {
          decoded = img.copyResize(decoded, width: maxDim);
        } else {
          decoded = img.copyResize(decoded, height: maxDim);
        }
      }

      final jpg = img.encodeJpg(decoded, quality: quality.jpegQuality);
      return ProcessedImage(
        bytes: jpg,
        width: decoded.width,
        height: decoded.height,
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw PdfGenerationFailure(e);
    }
  }
}
