import 'package:smartscanocr/features/documents/domain/entities/processing_phase.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_document.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_page.dart';
import 'package:smartscanocr/features/pdf_export/domain/entities/pdf_quality.dart';

typedef ProcessingProgress =
    void Function(ProcessingPhase phase, int done, int total);

/// Outcome of [DocumentProcessingService.buildAndSave].
class DocumentBuildResult {
  const DocumentBuildResult({
    required this.document,
    this.warning,
    this.ocrHardFailed = false,
  });

  final ScannedDocument document;

  /// Non-blocking note (e.g. perspective correction could not be applied).
  final String? warning;

  /// True if OCR could not run (e.g. no Play Services); the PDF is still saved.
  final bool ocrHardFailed;
}

/// Builds (or regenerates) a document from a list of edited pages and persists
/// it. Reprocesses only changed pages, re-runs OCR only for changed/new pages,
/// regenerates the PDF, and commits atomically (staged temp files → rename;
/// metadata written last), so a failure never corrupts the previous document.
abstract class DocumentProcessingService {
  Future<DocumentBuildResult> buildAndSave({
    required String documentId,
    required String title,
    required DateTime createdAt,
    required DateTime now,
    required List<ScannedPage> pages,
    ScannedDocument? previous,
    required PdfQuality quality,
    ProcessingProgress? onProgress,
  });
}
