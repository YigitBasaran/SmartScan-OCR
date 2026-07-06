import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:smartscanocr/core/errors/app_exception.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_page.dart';
import 'package:smartscanocr/features/pdf_export/domain/entities/pdf_export_mode.dart';
import 'package:smartscanocr/features/pdf_export/domain/services/pdf_export_service.dart';

/// Builds an image-based PDF (one page per image) from the pages' already
/// compressed effective images, optionally overlaying a branding watermark.
class PdfExportServiceImpl implements PdfExportService {
  /// Branding watermark text. ASCII so it renders in the built-in Helvetica;
  /// a localized (e.g. Turkish) string would require an embedded Unicode font.
  static const String watermarkText = 'Scanned with SmartScan OCR';

  @override
  Future<Uint8List> renderPdf(
    List<ScannedPage> pages, {
    PdfExportMode mode = PdfExportMode.watermarked,
  }) async {
    try {
      final doc = pw.Document();

      // Scale each page so the image's longest side maps to A4's long edge (in
      // points), preserving aspect ratio for borderless, undistorted pages.
      final a4LongSide = PdfPageFormat.a4.height;

      for (final page in pages) {
        final bytes = await File(page.effectiveImagePath).readAsBytes();
        final decoded = img.decodeImage(bytes);
        final width = decoded?.width ?? 1;
        final height = decoded?.height ?? 1;
        final scale = a4LongSide / math.max(width, height);
        final provider = pw.MemoryImage(bytes);

        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(width * scale, height * scale),
            margin: pw.EdgeInsets.zero,
            build: (context) => pw.Stack(
              fit: pw.StackFit.expand,
              children: [
                pw.Image(provider, fit: pw.BoxFit.fill),
                // Watermark is drawn ON TOP of the clean image, so it never
                // affects the stored image files or OCR.
                if (mode == PdfExportMode.watermarked)
                  pw.Positioned(
                    bottom: 10,
                    right: 12,
                    child: pw.Opacity(
                      opacity: 0.28,
                      child: pw.Text(
                        watermarkText,
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.black,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }

      return doc.save();
    } on AppException {
      rethrow;
    } catch (e) {
      throw PdfGenerationFailure(e);
    }
  }
}
