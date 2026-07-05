import 'package:smartscanocr/features/documents/domain/entities/ocr_status.dart';
import 'package:smartscanocr/features/ocr/domain/entities/ocr_page_result.dart';

/// The OCR result for a whole document (all pages).
class OcrDocumentResult {
  const OcrDocumentResult({
    required this.pages,
    required this.combinedText,
    required this.status,
  });

  final List<OcrPageResult> pages;
  final String combinedText;
  final OcrStatus status;
}
