import 'package:smartscanocr/core/errors/error_presenter.dart';
import 'package:smartscanocr/core/sharing/sharing_service.dart';
import 'package:smartscanocr/core/storage/file_storage_service.dart';
import 'package:smartscanocr/core/utils/filename_util.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_document.dart';
import 'package:smartscanocr/features/pdf_export/domain/entities/pdf_export_mode.dart';
import 'package:smartscanocr/features/pdf_export/domain/services/pdf_export_service.dart';

enum ExportOutcomeKind { shared, error }

class ExportOutcome {
  const ExportOutcome(this.kind, {this.message});
  final ExportOutcomeKind kind;
  final String? message;
}

/// Shares a document's PDF, either the stored watermarked file (free) or a
/// freshly rendered watermark-free copy. Rewarded-ad gating for the
/// watermark-free path is handled by the caller (the UI); this service only
/// renders and shares. The watermark-free path renders to a temp file and
/// **never** overwrites the stored `export.pdf`, re-runs OCR, or changes
/// document metadata.
class DocumentExporter {
  DocumentExporter({
    required this.pdfService,
    required this.storage,
    required this.sharing,
  });

  final PdfExportService pdfService;
  final FileStorageService storage;
  final SharingService sharing;

  /// Free export: shares the stored watermarked `export.pdf` under a title name.
  Future<ExportOutcome> exportWithWatermark(ScannedDocument document) async {
    if (!document.hasPdf) {
      return const ExportOutcome(
        ExportOutcomeKind.error,
        message: 'No PDF is available for this document.',
      );
    }
    try {
      final fileName = buildShareFileName(document.title, document.createdAt);
      final path = await storage.stagePdfForShare(document.id, fileName);
      await sharing.sharePdf(path: path, fileName: fileName);
      return const ExportOutcome(ExportOutcomeKind.shared);
    } catch (e) {
      return ExportOutcome(
        ExportOutcomeKind.error,
        message: describeError(e).message,
      );
    }
  }

  /// Watermark-free export (call only after a reward has been earned). Renders a
  /// fresh watermark-free PDF to a temp file and shares it.
  Future<ExportOutcome> exportWatermarkFree(ScannedDocument document) async {
    if (document.pages.isEmpty) {
      return const ExportOutcome(
        ExportOutcomeKind.error,
        message: 'No pages to export.',
      );
    }
    try {
      final bytes = await pdfService.renderPdf(
        document.pages,
        mode: PdfExportMode.watermarkFree,
      );
      final fileName = buildShareFileName(document.title, document.createdAt);
      final path = await storage.writeTempShareFile(fileName, bytes);
      await sharing.sharePdf(path: path, fileName: fileName);
      return const ExportOutcome(
        ExportOutcomeKind.shared,
        message: 'Watermark removed for this export.',
      );
    } catch (e) {
      return ExportOutcome(
        ExportOutcomeKind.error,
        message: describeError(e).message,
      );
    }
  }
}
