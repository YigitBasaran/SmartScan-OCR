import 'dart:typed_data';

import 'package:smartscanocr/features/documents/domain/entities/scanned_page.dart';
import 'package:smartscanocr/features/pdf_export/domain/entities/pdf_export_mode.dart';

/// Builds an image-based PDF from a document's page images.
abstract class PdfExportService {
  /// Renders one page per image (using each page's effective image, in list
  /// order) and returns the PDF bytes. When [mode] is
  /// [PdfExportMode.watermarked] a branding watermark is drawn as an overlay on
  /// top of each page image (never baked into the image). Writing/staging is the
  /// caller's job so regeneration can be made transaction-like.
  Future<Uint8List> renderPdf(
    List<ScannedPage> pages, {
    PdfExportMode mode = PdfExportMode.watermarked,
  });
}
