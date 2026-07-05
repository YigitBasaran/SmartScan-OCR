import 'package:smartscanocr/features/documents/domain/entities/ocr_status.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_page.dart';

/// A saved document: its pages, the generated PDF, and the recognized text.
class ScannedDocument {
  const ScannedDocument({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.pages,
    required this.ocrStatus,
    this.pdfPath,
    this.combinedText = '',
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ScannedPage> pages;
  final String? pdfPath;

  /// The concatenated OCR text of all pages, used for search.
  final String combinedText;
  final OcrStatus ocrStatus;

  int get pageCount => pages.length;
  bool get hasText => combinedText.trim().isNotEmpty;
  bool get hasPdf => (pdfPath ?? '').isNotEmpty;
  String? get thumbnailPath => pages.isEmpty ? null : pages.first.imagePath;

  ScannedDocument copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ScannedPage>? pages,
    String? pdfPath,
    String? combinedText,
    OcrStatus? ocrStatus,
  }) {
    return ScannedDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pages: pages ?? this.pages,
      pdfPath: pdfPath ?? this.pdfPath,
      combinedText: combinedText ?? this.combinedText,
      ocrStatus: ocrStatus ?? this.ocrStatus,
    );
  }
}
