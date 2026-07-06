import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:smartscanocr/core/errors/app_exception.dart';
import 'package:smartscanocr/core/sharing/sharing_service.dart';
import 'package:smartscanocr/core/storage/file_storage_service.dart';
import 'package:smartscanocr/features/documents/domain/document_search.dart';
import 'package:smartscanocr/features/documents/domain/entities/ocr_status.dart';
import 'package:smartscanocr/features/documents/domain/entities/page_filter.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_document.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_page.dart';
import 'package:smartscanocr/features/perspective/domain/entities/document_corner.dart';
import 'package:smartscanocr/features/documents/domain/repositories/document_repository.dart';
import 'package:smartscanocr/features/monetization/domain/rewarded_ad_service.dart';
import 'package:smartscanocr/features/ocr/domain/entities/ocr_document_result.dart';
import 'package:smartscanocr/features/ocr/domain/entities/ocr_page_result.dart';
import 'package:smartscanocr/features/ocr/domain/services/ocr_service.dart';
import 'package:smartscanocr/features/pdf_export/domain/entities/pdf_export_mode.dart';
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
  Future<List<String>> importImages({bool autoCorrect = true}) async {
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

  /// Page ids passed to the most recent recognizeDocument call.
  List<String> lastPageIds = const [];

  @override
  Future<OcrDocumentResult> recognizeDocument(
    List<ScannedPage> pages, {
    OcrProgressCallback? onProgress,
  }) async {
    calls++;
    lastPageIds = pages.map((p) => p.id).toList();
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

/// A PDF exporter that records calls (and the export mode) and returns fake
/// bytes (or throws).
class FakePdfExportService implements PdfExportService {
  FakePdfExportService({this.throwError = false});

  final bool throwError;
  int calls = 0;
  List<ScannedPage>? lastPages;
  final List<PdfExportMode> renderModes = [];

  @override
  Future<Uint8List> renderPdf(
    List<ScannedPage> pages, {
    PdfExportMode mode = PdfExportMode.watermarked,
  }) async {
    calls++;
    lastPages = pages;
    renderModes.add(mode);
    if (throwError) throw const _FakePdfFailure();
    return Uint8List.fromList([0x25, 0x50, 0x44, 0x46]); // "%PDF"
  }
}

class _FakePdfFailure implements Exception {
  const _FakePdfFailure();
}

/// An image processor that returns fixed bytes/dimensions without decoding, and
/// records the source paths it processed.
class FakeImageProcessor implements ImageProcessor {
  final List<String> processedPaths = [];

  @override
  Future<ProcessedImage> process(
    String sourcePath, {
    required int rotationQuarterTurns,
    List<DocumentCorner>? cropCorners,
    PageFilter filter = PageFilter.none,
    required PdfQuality quality,
  }) async {
    processedPaths.add(sourcePath);
    return ProcessedImage(
      bytes: Uint8List.fromList([0, 1, 2, 3]),
      width: 100,
      height: 140,
    );
  }
}

/// A file storage that records writes/deletes in memory, distinguishing staged
/// from committed writes so tests can assert transaction/rollback behavior.
class FakeFileStorageService implements FileStorageService {
  final Map<String, List<int>> originals = {};
  final Map<String, List<int>> stagedImages = {};
  final Map<String, List<int>> committedImages = {};
  final List<String> discardedImages = [];
  List<int>? stagedPdfBytes;
  List<int>? committedPdfBytes;
  bool pdfDiscarded = false;
  final List<String> deletedPages = [];
  final List<String> deletedFiles = [];
  final List<String> deletedDirs = [];
  final List<String> sharedFileNames = [];
  final Map<String, List<int>> tempShareBytes = {};

  String _key(String documentId, String pageId) => '$documentId/$pageId';

  @override
  Future<String> saveOriginalFromPath(
    String documentId,
    String pageId,
    String sourcePath,
  ) async {
    originals.putIfAbsent(_key(documentId, pageId), () => const <int>[]);
    return 'documents/$documentId/pages/$pageId.orig.jpg';
  }

  @override
  Future<String> originalImagePath(String documentId, String pageId) async =>
      'documents/$documentId/pages/$pageId.orig.jpg';

  @override
  Future<String> stageProcessedImage(
    String documentId,
    String pageId,
    List<int> bytes,
  ) async {
    stagedImages[_key(documentId, pageId)] = bytes;
    return 'documents/$documentId/pages/$pageId.new.jpg';
  }

  @override
  Future<String> commitProcessedImage(
    String documentId,
    String pageId,
    String version,
  ) async {
    final key = _key(documentId, pageId);
    committedImages[key] = stagedImages.remove(key) ?? const <int>[];
    return 'documents/$documentId/pages/$pageId.$version.jpg';
  }

  @override
  Future<void> discardStagedImage(String documentId, String pageId) async {
    stagedImages.remove(_key(documentId, pageId));
    discardedImages.add(_key(documentId, pageId));
  }

  @override
  Future<String> stagePdf(String documentId, List<int> bytes) async {
    stagedPdfBytes = bytes;
    return 'documents/$documentId/export.new.pdf';
  }

  @override
  Future<String> commitPdf(String documentId) async {
    committedPdfBytes = stagedPdfBytes;
    stagedPdfBytes = null;
    return 'documents/$documentId/export.pdf';
  }

  @override
  Future<void> discardStagedPdf(String documentId) async {
    stagedPdfBytes = null;
    pdfDiscarded = true;
  }

  @override
  Future<String> pdfFilePath(String documentId) async =>
      'documents/$documentId/export.pdf';

  @override
  Future<String> stagePdfForShare(String documentId, String fileName) async {
    sharedFileNames.add(fileName);
    return 'tmp/$fileName';
  }

  @override
  Future<String> writeTempShareFile(String fileName, List<int> bytes) async {
    sharedFileNames.add(fileName);
    tempShareBytes[fileName] = bytes;
    return 'tmp/$fileName';
  }

  @override
  Future<void> deleteFileAt(String path) async {
    deletedFiles.add(path);
  }

  @override
  Future<void> deletePageFiles(String documentId, String pageId) async {
    deletedPages.add(_key(documentId, pageId));
  }

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

/// A rewarded-ad service with configurable availability + reward outcome.
class FakeRewardedAdService implements RewardedAdService {
  FakeRewardedAdService({this.available = true, this.earned = true});

  final bool available;
  final bool earned;
  int showCalls = 0;

  @override
  Future<bool> isRewardedAdAvailable() async => available;

  @override
  Future<RewardResult> showWatermarkRemovalAd(BuildContext context) async {
    showCalls++;
    return RewardResult(earnedReward: earned);
  }
}

/// A sharing service that records what it was asked to share.
class FakeSharingService implements SharingService {
  final List<String> sharedPdfPaths = [];
  final List<String?> sharedPdfNames = [];
  final List<String> sharedTexts = [];
  bool throwOnShare = false;

  @override
  Future<void> sharePdf({required String path, String? fileName}) async {
    if (throwOnShare) throw const ShareFailure();
    sharedPdfPaths.add(path);
    sharedPdfNames.add(fileName);
  }

  @override
  Future<void> shareText(String text) async => sharedTexts.add(text);

  @override
  Future<void> printPdf(String path) async {}
}
