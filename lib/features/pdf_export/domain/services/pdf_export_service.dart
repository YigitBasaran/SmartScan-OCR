import 'package:smartscanocr/features/documents/domain/entities/scanned_page.dart';
import 'package:smartscanocr/features/pdf_export/domain/entities/pdf_quality.dart';

/// Builds an image-based PDF from a document's (already saved) page images.
abstract class PdfExportService {
  /// Creates `export.pdf` for [documentId] from [pages] and returns its path.
  ///
  /// [quality] is accepted for API stability; page images are already
  /// compressed to this quality when saved, so the PDF simply embeds them.
  Future<String> createPdf({
    required String documentId,
    required List<ScannedPage> pages,
    required PdfQuality quality,
  });
}
