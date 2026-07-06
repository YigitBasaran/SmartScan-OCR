import 'package:smartscanocr/features/documents/domain/entities/ocr_status.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_document.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_page.dart';

/// Test factory for a [ScannedPage].
ScannedPage makePage({
  String id = 'p1',
  String originalImagePath = 'p.jpg',
  String? processedImagePath,
  int order = 0,
  int rotation = 0,
  String? ocrText,
}) => ScannedPage(
  id: id,
  originalImagePath: originalImagePath,
  processedImagePath: processedImagePath,
  order: order,
  rotationQuarterTurns: rotation,
  ocrText: ocrText,
);

/// Test factory for a [ScannedDocument].
ScannedDocument makeDocument({
  required String id,
  String title = 'Document',
  String text = '',
  DateTime? createdAt,
  List<ScannedPage>? pages,
  OcrStatus status = OcrStatus.done,
  String? pdfPath = 'export.pdf',
}) {
  final now = createdAt ?? DateTime(2026, 1, 1);
  return ScannedDocument(
    id: id,
    title: title,
    createdAt: now,
    updatedAt: now,
    pages:
        pages ??
        [
          ScannedPage(
            id: '${id}_p1',
            originalImagePath: '$id.jpg',
            processedImagePath: '$id.jpg',
            order: 0,
            ocrText: text,
          ),
        ],
    pdfPath: pdfPath,
    combinedText: text,
    ocrStatus: status,
  );
}
