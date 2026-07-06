import 'package:smartscanocr/features/perspective/domain/entities/document_corner.dart';

/// Options controlling automatic perspective correction.
class PerspectiveCorrectionOptions {
  const PerspectiveCorrectionOptions({
    this.enabled = true,
    this.preferAuto = true,
    this.allowManualFallback = true,
    this.minConfidence = 0.5,
  });

  final bool enabled;
  final bool preferAuto;
  final bool allowManualFallback;
  final double minConfidence;
}

/// Result of an automatic perspective-correction attempt.
class PerspectiveCorrectionResult {
  const PerspectiveCorrectionResult({
    required this.outputPath,
    required this.corrected,
    this.confidence = 0,
    this.corners,
    this.warning,
  });

  /// Path to use downstream — the corrected image when [corrected], else the
  /// original [outputPath] passed through unchanged.
  final String outputPath;

  /// Whether a correction was actually applied.
  final bool corrected;

  /// Detector confidence in `[0..1]`.
  final double confidence;

  /// Detected document corners (normalized), if any — for manual review/adjust.
  final List<DocumentCorner>? corners;

  /// Non-blocking note when correction was skipped.
  final String? warning;
}

/// Detects a document quad and returns a perspective-corrected image.
///
/// This is the extension point for a future automatic detector (e.g. OpenCV or
/// an ML-Kit corner detector). The default [NoOpPerspectiveCorrectionService]
/// performs no auto-detection; manual correction is delivered through the page
/// editor's crop corners instead. Implementations must never throw or block the
/// OCR/PDF pipeline — a failure returns `corrected: false` with the input path.
abstract class PerspectiveCorrectionService {
  Future<PerspectiveCorrectionResult> correct({
    required String inputPath,
    PerspectiveCorrectionOptions options,
  });
}
