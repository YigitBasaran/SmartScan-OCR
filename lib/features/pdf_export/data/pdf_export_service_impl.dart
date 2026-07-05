import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:smartscanocr/core/errors/app_exception.dart';
import 'package:smartscanocr/core/storage/file_storage_service.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_page.dart';
import 'package:smartscanocr/features/pdf_export/domain/entities/pdf_quality.dart';
import 'package:smartscanocr/features/pdf_export/domain/services/pdf_export_service.dart';

/// Builds an image-based PDF (one page per image) from already-saved,
/// already-compressed page JPEGs, and writes it via [FileStorageService].
class PdfExportServiceImpl implements PdfExportService {
  PdfExportServiceImpl(this._storage);

  final FileStorageService _storage;

  @override
  Future<String> createPdf({
    required String documentId,
    required List<ScannedPage> pages,
    required PdfQuality quality,
  }) async {
    try {
      final doc = pw.Document();

      // Scale each page so the image's longest side maps to A4's long edge (in
      // points), preserving aspect ratio for borderless, undistorted pages.
      final a4LongSide = PdfPageFormat.a4.height;

      for (final page in pages) {
        final bytes = await File(page.imagePath).readAsBytes();
        final decoded = img.decodeImage(bytes);
        final width = decoded?.width ?? 1;
        final height = decoded?.height ?? 1;
        final scale = a4LongSide / math.max(width, height);
        final provider = pw.MemoryImage(bytes);

        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(width * scale, height * scale),
            margin: pw.EdgeInsets.zero,
            build: (context) => pw.Image(provider, fit: pw.BoxFit.fill),
          ),
        );
      }

      final pdfBytes = await doc.save();
      return _storage.writePdf(documentId, pdfBytes);
    } on AppException {
      rethrow;
    } catch (e) {
      throw PdfGenerationFailure(e);
    }
  }
}
