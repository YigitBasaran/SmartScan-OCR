import 'package:smartscanocr/features/perspective/domain/services/perspective_correction_service.dart';

/// Default [PerspectiveCorrectionService] that performs no automatic detection.
///
/// It returns the input path unchanged with `corrected: false`, so the pipeline
/// falls back to the original image (and the user's manual crop, if any).
/// Replace with an OpenCV/ML-Kit detector implementation when available.
class NoOpPerspectiveCorrectionService implements PerspectiveCorrectionService {
  const NoOpPerspectiveCorrectionService();

  @override
  Future<PerspectiveCorrectionResult> correct({
    required String inputPath,
    PerspectiveCorrectionOptions options = const PerspectiveCorrectionOptions(),
  }) async {
    // No auto-detection configured: pass the image through unchanged. No
    // warning is surfaced (this is the expected default, not a failure).
    return PerspectiveCorrectionResult(outputPath: inputPath, corrected: false);
  }
}
