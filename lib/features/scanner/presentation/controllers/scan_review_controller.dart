import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartscanocr/core/errors/app_exception.dart';
import 'package:smartscanocr/core/providers/app_providers.dart';
import 'package:smartscanocr/core/providers/service_providers.dart';
import 'package:smartscanocr/core/utils/filename_util.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_document.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_page.dart';
import 'package:smartscanocr/features/documents/domain/page_edit_ops.dart'
    as ops;
import 'package:smartscanocr/features/documents/presentation/controllers/documents_controller.dart';
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
      final auto = ref
          .read(settingsControllerProvider)
          .autoPerspectiveCorrection;
      final paths = await ref
          .read(documentScannerServiceProvider)
          .importImages(autoCorrect: auto);
      _appendPaths(paths);
    } catch (e) {
      _setError(e);
    }
  }

  void _appendPaths(List<String> paths) {
    final uuid = ref.read(uuidProvider);
    final newPages = [
      for (final path in paths)
        ScannedPage(id: uuid.v4(), originalImagePath: path, order: 0),
    ];
    state = state.copyWith(
      pages: ops.appendPages(state.pages, newPages),
      clearError: true,
    );
  }

  void _setError(Object error) {
    if (error is ScanCancelled) return; // silent
    state = state.copyWith(error: error);
  }

  void consumeError() => state = state.copyWith(clearError: true);

  void setTitle(String title) => state = state.copyWith(title: title);

  void removePage(String pageId) =>
      state = state.copyWith(pages: ops.removePageById(state.pages, pageId));

  void rotatePage(String pageId) =>
      state = state.copyWith(pages: ops.rotatePageById(state.pages, pageId));

  /// Reorders a page. [newIndex] is the final target index (already adjusted by
  /// `ReorderableListView.onReorderItem`).
  void reorderPage(int oldIndex, int newIndex) => state = state.copyWith(
    pages: ops.reorderPages(state.pages, oldIndex, newIndex),
  );

  /// Replaces a page with the edited version returned by the page editor.
  void applyPageEdit(ScannedPage page) =>
      state = state.copyWith(pages: ops.replacePage(state.pages, page));

  /// Runs the shared pipeline (process → OCR → PDF → persist) for a new document.
  ///
  /// Returns the saved document, or null on failure / when there are no pages.
  /// OCR problems degrade gracefully — the PDF is still generated and saved.
  Future<ScannedDocument?> runOcrAndSavePdf() async {
    if (state.pages.isEmpty) {
      state = state.copyWith(error: const NoPagesSelected());
      return null;
    }

    final uuid = ref.read(uuidProvider);
    final now = ref.read(clockProvider)();
    final quality = ref.read(settingsControllerProvider).pdfQuality;
    final processing = ref.read(documentProcessingServiceProvider);

    final documentId = uuid.v4();
    final title = state.title.trim().isEmpty
        ? buildDefaultDocumentTitle(now)
        : state.title.trim();
    final ordered = [...state.pages]
      ..sort((a, b) => a.order.compareTo(b.order));

    state = state.copyWith(
      phase: ProcessingPhase.preparing,
      currentPage: 0,
      totalPages: ordered.length,
      clearError: true,
      clearSaved: true,
    );

    try {
      final result = await processing.buildAndSave(
        documentId: documentId,
        title: title,
        createdAt: now,
        now: now,
        pages: ordered,
        quality: quality,
        onProgress: (phase, done, total) => state = state.copyWith(
          phase: phase,
          currentPage: done,
          totalPages: total,
        ),
      );
      await ref.read(documentsControllerProvider.notifier).refresh();

      // Non-blocking info if OCR degraded (the PDF was still saved).
      final Object? info = result.ocrHardFailed
          ? const OcrFailure()
          : (result.document.combinedText.trim().isEmpty
                ? const OcrNoText()
                : null);
      state = state.copyWith(
        phase: ProcessingPhase.done,
        savedDocumentId: result.document.id,
        error: info,
        clearError: info == null,
      );
      return result.document;
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
