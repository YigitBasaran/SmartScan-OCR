import 'dart:typed_data';

import 'package:smartscanocr/core/storage/file_storage_service.dart';
import 'package:smartscanocr/features/documents/domain/document_search.dart';
import 'package:smartscanocr/features/documents/domain/entities/ocr_status.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_document.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_page.dart';
import 'package:smartscanocr/features/documents/domain/repositories/document_repository.dart';
import 'package:smartscanocr/features/ocr/domain/entities/ocr_document_result.dart';
import 'package:smartscanocr/features/ocr/domain/entities/ocr_page_result.dart';
import 'package:smartscanocr/features/ocr/domain/services/ocr_service.dart';
import 'package:smartscanocr/features/pdf_export/domain/entities/pdf_quality.dart';
import 'package:smartscanocr/features/pdf_export/domain/services/image_processor.dart';
import 'package:smartscanocr/features/pdf_export/domain/services/pdf_export_service.dart';
import 'package:smartscanocr/features/scanner/domain/services/document_scanner_service.dart';
import 'package:smartscanocr/features/settings/domain/entities/app_settings.dart';
import 'package:smartscanocr/features/settings/domain/repositories/settings_repository.dart';

/// A scanner that returns canned image paths (or throws a configured error).
class FakeDocumentScannerService implements DocumentScannerService {
  FakeDocumentScannerService({
    this.scanResult = const ['a.jpg', 'b.jpg'],
    this.importResult = const ['c.jpg'],
    this.scanError,
    this.importError,
  });

  final List<String> scanResult;
  final List<String> importResult;
  final Object? scanError;
  final Object? importError;

  @override
  Future<List<String>> scanDocuments({int maxPages = 30}) async {
    if (scanError != null) throw scanError!;
    return scanResult;
  }

  @override
  Future<List<String>> importImages() async {
    if (importError != null) throw importError!;
    return importResult;
  }
}

/// An OCR service that returns configurable text/status (or throws).
class FakeOcrService implements OcrService {
  FakeOcrService({
    this.textPerPage = 'Sample text',
    this.status = OcrStatus.done,
    this.throwError = false,
  });

  final String textPerPage;
  final OcrStatus status;
  final bool throwError;
  int calls = 0;

  @override
  Future<OcrDocumentResult> recognizeDocument(
    List<ScannedPage> pages, {
    OcrProgressCallback? onProgress,
  }) async {
    calls++;
    if (throwError) throw const OcrFailureForTest();
    onProgress?.call(pages.length, pages.length);
    final results = [
      for (final p in pages) OcrPageResult(pageId: p.id, text: textPerPage),
    ];
    final combined = results
        .map((r) => r.text.trim())
        .where((t) => t.isNotEmpty)
        .join('\n\n');
    return OcrDocumentResult(
      pages: results,
      combinedText: combined,
      status: status,
    );
  }
}

/// A distinct error type used only to exercise the OCR-failure path.
class OcrFailureForTest implements Exception {
  const OcrFailureForTest();
}

/// A PDF exporter that records calls and returns a fake path (or throws).
class FakePdfExportService implements PdfExportService {
  FakePdfExportService({this.throwError = false});

  final bool throwError;
  int calls = 0;
  List<ScannedPage>? lastPages;

  @override
  Future<String> createPdf({
    required String documentId,
    required List<ScannedPage> pages,
    required PdfQuality quality,
  }) async {
    calls++;
    lastPages = pages;
    if (throwError) throw const _FakePdfFailure();
    return 'documents/$documentId/export.pdf';
  }
}

class _FakePdfFailure implements Exception {
  const _FakePdfFailure();
}

/// An image processor that returns fixed bytes/dimensions without decoding.
class FakeImageProcessor implements ImageProcessor {
  @override
  Future<ProcessedImage> process(
    String sourcePath, {
    required int rotationQuarterTurns,
    required PdfQuality quality,
  }) async {
    return ProcessedImage(
      bytes: Uint8List.fromList([0, 1, 2, 3]),
      width: 100,
      height: 140,
    );
  }
}

/// A file storage that records writes/deletes in memory.
class FakeFileStorageService implements FileStorageService {
  final Map<String, List<int>> savedImages = {};
  final Map<String, List<int>> savedPdfs = {};
  final List<String> deletedDirs = [];

  @override
  Future<String> savePageImage(
    String documentId,
    int index,
    List<int> bytes,
  ) async {
    final path = 'documents/$documentId/pages/page_${index + 1}.jpg';
    savedImages[path] = bytes;
    return path;
  }

  @override
  Future<String> writePdf(String documentId, List<int> bytes) async {
    final path = 'documents/$documentId/export.pdf';
    savedPdfs[path] = bytes;
    return path;
  }

  @override
  Future<String> pdfFilePath(String documentId) async =>
      'documents/$documentId/export.pdf';

  @override
  Future<void> deleteDocumentDir(String documentId) async {
    deletedDirs.add(documentId);
  }

  @override
  Future<void> sweepOrphans(Set<String> knownIds) async {}
}

/// An in-memory [DocumentRepository] for tests.
class InMemoryDocumentRepository implements DocumentRepository {
  InMemoryDocumentRepository([List<ScannedDocument> seed = const []]) {
    for (final doc in seed) {
      _store[doc.id] = doc;
    }
  }

  final Map<String, ScannedDocument> _store = {};

  @override
  Future<List<ScannedDocument>> getDocuments() async =>
      _store.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  @override
  Future<ScannedDocument?> getById(String id) async => _store[id];

  @override
  Future<void> saveDocument(ScannedDocument document) async {
    _store[document.id] = document;
  }

  @override
  Future<void> deleteDocument(String id) async {
    _store.remove(id);
  }

  @override
  Future<List<ScannedDocument>> searchDocuments(String query) async =>
      filterDocuments(await getDocuments(), query);
}

/// A settings repository backed by an in-memory value.
class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository([this._settings = const AppSettings()]);

  AppSettings _settings;
  AppSettings? saved;

  @override
  AppSettings load() => _settings;

  @override
  Future<void> save(AppSettings settings) async {
    _settings = settings;
    saved = settings;
  }
}
