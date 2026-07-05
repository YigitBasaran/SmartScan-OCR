import 'package:smartscanocr/features/documents/domain/entities/scanned_page.dart';
import 'package:smartscanocr/features/ocr/domain/entities/ocr_document_result.dart';

typedef OcrProgressCallback = void Function(int done, int total);

/// On-device OCR over a document's pages. No cloud APIs are used.
abstract class OcrService {
  /// Recognizes text on each page (in order), reporting progress via [onProgress].
  ///
  /// Should not throw for "no text"/per-page failures; instead it returns a
  /// result whose [OcrDocumentResult.status] reflects the outcome.
  Future<OcrDocumentResult> recognizeDocument(
    List<ScannedPage> pages, {
    OcrProgressCallback? onProgress,
  });
}
