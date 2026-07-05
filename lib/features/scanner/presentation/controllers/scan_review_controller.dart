import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartscanocr/core/errors/app_exception.dart';
import 'package:smartscanocr/core/providers/app_providers.dart';
import 'package:smartscanocr/core/providers/service_providers.dart';
import 'package:smartscanocr/core/utils/filename_util.dart';
import 'package:smartscanocr/features/documents/domain/entities/ocr_status.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_document.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_page.dart';
import 'package:smartscanocr/features/documents/presentation/controllers/documents_controller.dart';
import 'package:smartscanocr/features/ocr/domain/entities/ocr_document_result.dart';
import 'package:smartscanocr/features/ocr/domain/entities/ocr_page_result.dart';
import 'package:smartscanocr/features/scanner/presentation/controllers/scan_review_state.dart';
import 'package:smartscanocr/features/settings/presentation/controllers/settings_controller.dart';

/// Drives the review flow: collect pages (scan/import), edit them, then run the
/// OCR + PDF + save pipeline while reporting progress via [ScanReviewState].
class ScanReviewController extends Notifier<ScanReviewState> {
  @override
  ScanReviewState build() => const ScanReviewState();

  Future<void> scan() async {
    try {
      final paths = await ref
          .read(documentScannerServiceProvider)
          .scanDocuments();
      _appendPaths(paths);
    } catch (e) {
      _setError(e);
    }
  }

  Future<void> importImages() async {
    try {
      final paths = await ref
          .read(documentScannerServiceProvider)
          .importImages();
      _appendPaths(paths);
    } catch (e) {
      _setError(e);
    }
  }

  void _appendPaths(List<String> paths) {
    final uuid = ref.read(uuidProvider);
    final pages = [...state.pages];
    var order = pages.length;
    for (final path in paths) {
      pages.add(ScannedPage(id: uuid.v4(), imagePath: path, order: order));
      order++;
    }
    state = state.copyWith(pages: pages, clearError: true);
  }

  void _setError(Object error) {
    if (error is ScanCancelled) return; // silent
    state = state.copyWith(error: error);
  }

  void consumeError() => state = state.copyWith(clearError: true);

  void setTitle(String title) => state = state.copyWith(title: title);

  void removePage(String pageId) {
    _reindex(state.pages.where((p) => p.id != pageId).toList());
  }

  void rotatePage(String pageId) {
    final pages = state.pages
        .map(
          (p) => p.id == pageId
              ? p.copyWith(
                  rotationQuarterTurns: (p.rotationQuarterTurns + 1) % 4,
                )
              : p,
        )
        .toList();
    state = state.copyWith(pages: pages);
  }

  /// Reorders a page. [newIndex] is the final target index (already adjusted by
  /// `ReorderableListView.onReorderItem`).
  void reorderPage(int oldIndex, int newIndex) {
    final pages = [...state.pages];
    final moved = pages.removeAt(oldIndex);
    pages.insert(newIndex, moved);
    _reindex(pages);
  }

  void _reindex(List<ScannedPage> pages) {
    final reindexed = <ScannedPage>[
      for (var i = 0; i < pages.length; i++) pages[i].copyWith(order: i),
    ];
    state = state.copyWith(pages: reindexed);
  }

  /// Runs the full pipeline: orient+compress+save images -> OCR -> PDF -> persist.
  ///
  /// Returns the saved document, or null on failure / when there are no pages.
  /// OCR problems degrade gracefully — the PDF is still generated and saved.
  Future<ScannedDocument?> runOcrAndSavePdf() async {
    if (state.pages.isEmpty) {
      state = state.copyWith(error: const NoPagesSelected());
      return null;
    }

    final uuid = ref.read(uuidProvider);
    final clock = ref.read(clockProvider);
    final quality = ref.read(settingsControllerProvider).pdfQuality;
    final imageProcessor = ref.read(imageProcessorProvider);
    final fileStorage = ref.read(fileStorageServiceProvider);
    final ocrService = ref.read(ocrServiceProvider);
    final pdfService = ref.read(pdfExportServiceProvider);
    final repository = ref.read(documentRepositoryProvider);

    final documentId = uuid.v4();
    final ordered = [...state.pages]
      ..sort((a, b) => a.order.compareTo(b.order));

    try {
      // Phase 1: orient + compress + save each page image.
      state = state.copyWith(
        phase: ProcessingPhase.preparing,
        currentPage: 0,
        totalPages: ordered.length,
        clearError: true,
        clearSaved: true,
      );
      final savedPages = <ScannedPage>[];
      for (var i = 0; i < ordered.length; i++) {
        state = state.copyWith(currentPage: i + 1);
        final page = ordered[i];
        final processed = await imageProcessor.process(
          page.imagePath,
          rotationQuarterTurns: page.rotationQuarterTurns,
          quality: quality,
        );
        final savedPath = await fileStorage.savePageImage(
          documentId,
          i,
          processed.bytes,
        );
        savedPages.add(
          page.copyWith(
            imagePath: savedPath,
            order: i,
            rotationQuarterTurns: 0,
          ),
        );
      }

      // Phase 2: OCR each saved page (failures degrade, never abort).
      state = state.copyWith(
        phase: ProcessingPhase.ocr,
        currentPage: 0,
        totalPages: savedPages.length,
      );
      OcrDocumentResult ocrResult;
      try {
        ocrResult = await ocrService.recognizeDocument(
          savedPages,
          onProgress: (done, total) =>
              state = state.copyWith(currentPage: done, totalPages: total),
        );
      } catch (_) {
        ocrResult = OcrDocumentResult(
          pages: [
            for (final p in savedPages) OcrPageResult(pageId: p.id, text: ''),
          ],
          combinedText: '',
          status: OcrStatus.failed,
        );
      }
      final textByPage = {for (final r in ocrResult.pages) r.pageId: r.text};
      final pagesWithText = savedPages
          .map((p) => p.copyWith(ocrText: textByPage[p.id] ?? ''))
          .toList();

      // Phase 3: generate the image-based PDF.
      state = state.copyWith(phase: ProcessingPhase.generatingPdf);
      final pdfPath = await pdfService.createPdf(
        documentId: documentId,
        pages: pagesWithText,
        quality: quality,
      );

      // Phase 4: persist metadata (the Hive write is the commit point).
      state = state.copyWith(phase: ProcessingPhase.saving);
      final now = clock();
      final title = state.title.trim().isEmpty
          ? buildDefaultDocumentTitle(now)
          : state.title.trim();
      final document = ScannedDocument(
        id: documentId,
        title: title,
        createdAt: now,
        updatedAt: now,
        pages: pagesWithText,
        pdfPath: pdfPath,
        combinedText: ocrResult.combinedText,
        ocrStatus: ocrResult.status,
      );
      await repository.saveDocument(document);
      await ref.read(documentsControllerProvider.notifier).refresh();

      // Non-blocking info if OCR degraded (PDF was still saved).
      final Object? info = switch (ocrResult.status) {
        OcrStatus.failed => const OcrFailure(),
        _ when ocrResult.combinedText.trim().isEmpty => const OcrNoText(),
        _ => null,
      };
      state = state.copyWith(
        phase: ProcessingPhase.done,
        savedDocumentId: documentId,
        error: info,
        clearError: info == null,
      );
      return document;
    } catch (e) {
      state = state.copyWith(
        phase: ProcessingPhase.idle,
        error: toAppException(e),
      );
      return null;
    }
  }
}

final scanReviewControllerProvider =
    NotifierProvider.autoDispose<ScanReviewController, ScanReviewState>(
      ScanReviewController.new,
    );
