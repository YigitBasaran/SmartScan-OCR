import 'package:smartscanocr/core/constants/app_constants.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_document.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_page.dart';

/// The single source of truth for assembling OCR text. No other code should
/// concatenate page text directly — this keeps `combinedText`, the on-screen
/// text, and the shared text consistent and page-ordered.
class OcrTextFormatter {
  const OcrTextFormatter._();

  static List<ScannedPage> _ordered(List<ScannedPage> pages) =>
      [...pages]..sort((a, b) => a.order.compareTo(b.order));

  /// Deterministic internal/search representation: ordered page texts joined,
  /// without page headers (so substring search stays meaningful).
  static String rebuildCombinedText(List<ScannedPage> pages) {
    return _ordered(pages)
        .map((p) => (p.ocrText ?? '').trim())
        .where((t) => t.isNotEmpty)
        .join('\n\n');
  }

  /// Human-facing text with the document title and per-page headers, used for
  /// on-screen display, copy, and sharing.
  static String formatForDisplay(ScannedDocument document) => _titled(document);

  static String formatForSharing(ScannedDocument document) => _titled(document);

  static String _titled(ScannedDocument document) {
    final buffer = StringBuffer()
      ..writeln('${AppConstants.appName} - ${document.title}');
    final pages = _ordered(document.pages);
    for (var i = 0; i < pages.length; i++) {
      buffer
        ..writeln()
        ..writeln('Page ${i + 1}');
      final text = (pages[i].ocrText ?? '').trim();
      buffer.writeln(text.isEmpty ? 'No text detected.' : text);
    }
    return buffer.toString().trimRight();
  }
}
