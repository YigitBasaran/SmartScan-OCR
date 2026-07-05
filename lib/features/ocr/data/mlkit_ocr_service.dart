import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:smartscanocr/features/documents/domain/entities/ocr_status.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_page.dart';
import 'package:smartscanocr/features/ocr/domain/entities/ocr_document_result.dart';
import 'package:smartscanocr/features/ocr/domain/entities/ocr_page_result.dart';
import 'package:smartscanocr/features/ocr/domain/services/ocr_service.dart';

/// On-device OCR via ML Kit text recognition (Latin script). No cloud calls.
///
/// A single [TextRecognizer] is reused across pages and closed in `finally`.
/// Per-page failures are tolerated so a bad image never aborts the whole run.
class MlKitOcrService implements OcrService {
  @override
  Future<OcrDocumentResult> recognizeDocument(
    List<ScannedPage> pages, {
    OcrProgressCallback? onProgress,
  }) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final results = <OcrPageResult>[];
    var anyFailed = false;
    var anySucceeded = false;

    try {
      for (var i = 0; i < pages.length; i++) {
        onProgress?.call(i, pages.length);
        try {
          final input = InputImage.fromFilePath(pages[i].imagePath);
          final recognized = await recognizer.processImage(input);
          results.add(
            OcrPageResult(
              pageId: pages[i].id,
              text: recognized.text,
              blockCount: recognized.blocks.length,
            ),
          );
          anySucceeded = true;
        } catch (_) {
          anyFailed = true;
          results.add(
            OcrPageResult(pageId: pages[i].id, text: '', blockCount: 0),
          );
        }
      }
      onProgress?.call(pages.length, pages.length);
    } finally {
      await recognizer.close();
    }

    final combinedText = results
        .map((r) => r.text.trim())
        .where((t) => t.isNotEmpty)
        .join('\n\n');

    final OcrStatus status;
    if (anyFailed && !anySucceeded) {
      status = OcrStatus.failed;
    } else if (anyFailed) {
      status = OcrStatus.partial;
    } else {
      status = OcrStatus.done;
    }

    return OcrDocumentResult(
      pages: results,
      combinedText: combinedText,
      status: status,
    );
  }
}
