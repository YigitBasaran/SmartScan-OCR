import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartscanocr/core/errors/app_exception.dart';
import 'package:smartscanocr/core/providers/app_providers.dart';
import 'package:smartscanocr/core/providers/service_providers.dart';
import 'package:smartscanocr/core/utils/filename_util.dart';
import 'package:smartscanocr/features/documents/domain/entities/processing_phase.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_document.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_page.dart';
import 'package:smartscanocr/features/documents/domain/page_edit_ops.dart'
    as ops;
import 'package:smartscanocr/features/documents/presentation/controllers/documents_controller.dart';
import 'package:smartscanocr/features/settings/presentation/controllers/settings_controller.dart';

/// State for editing an already-saved document.
class DocumentEditState {
  const DocumentEditState({
    this.documentId,
    this.title = '',
    this.createdAt,
    this.pages = const [],
    this.previous,
    this.phase = ProcessingPhase.idle,
    this.currentPage = 0,
    this.totalPages = 0,
    this.error,
    this.noticeMessage,
    this.saved = false,
    this.loaded = false,
  });

  final String? documentId;
  final String title;
  final DateTime? createdAt;
  final List<ScannedPage> pages;
  final ScannedDocument? previous;
  final ProcessingPhase phase;
  final int currentPage;
  final int totalPages;
  final Object? error;
  final String? noticeMessage;
  final bool saved;
  final bool loaded;

  bool get isBusy =>
      phase != ProcessingPhase.idle && phase != ProcessingPhase.done;

  double? get progress =>
      totalPages <= 0 ? null : (currentPage / totalPages).clamp(0.0, 1.0);

  DocumentEditState copyWith({
    String? documentId,
    String? title,
    DateTime? createdAt,
    List<ScannedPage>? pages,
    ScannedDocument? previous,
    ProcessingPhase? phase,
    int? currentPage,
    int? totalPages,
    Object? error,
    bool clearError = false,
    String? noticeMessage,
    bool clearNotice = false,
    bool? saved,
    bool? loaded,
  }) {
    return DocumentEditState(
      documentId: documentId ?? this.documentId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      pages: pages ?? this.pages,
      previous: previous ?? this.previous,
      phase: phase ?? this.phase,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      error: clearError ? null : (error ?? this.error),
      noticeMessage: clearNotice ? null : (noticeMessage ?? this.noticeMessage),
      saved: saved ?? this.saved,
      loaded: loaded ?? this.loaded,
    );
  }
}

/// Loads an existing document into an editable working copy, applies page edits
/// (reorder/delete/rotate/edit/add), and saves via the shared build pipeline —
/// regenerating the PDF and re-running OCR only for changed/new pages.
class DocumentEditController extends Notifier<DocumentEditState> {
  @override
  DocumentEditState build() => const DocumentEditState();

  /// Initializes the working copy from [doc] once.
  void load(ScannedDocument doc) {
    if (state.loaded) return;
    state = DocumentEditState(
      documentId: doc.id,
      title: doc.title,
      createdAt: doc.createdAt,
      pages: [...doc.pages]..sort((a, b) => a.order.compareTo(b.order)),
      previous: doc,
      loaded: true,
    );
  }

  void setTitle(String title) => state = state.copyWith(title: title);

  void rotatePage(String id) =>
      state = state.copyWith(pages: ops.rotatePageById(state.pages, id));

  void removePage(String id) =>
      state = state.copyWith(pages: ops.removePageById(state.pages, id));

  void reorderPage(int oldIndex, int newIndex) => state = state.copyWith(
    pages: ops.reorderPages(state.pages, oldIndex, newIndex),
  );

  void applyPageEdit(ScannedPage page) =>
      state = state.copyWith(pages: ops.replacePage(state.pages, page));

  void consumeError() => state = state.copyWith(clearError: true);
  void consumeNotice() => state = state.copyWith(clearNotice: true);

  Future<void> addScan() =>
      _add(() => ref.read(documentScannerServiceProvider).scanDocuments());

  Future<void> addImport() => _add(() {
    final auto = ref.read(settingsControllerProvider).autoPerspectiveCorrection;
    return ref
        .read(documentScannerServiceProvider)
        .importImages(autoCorrect: auto);
  });

  Future<void> _add(Future<List<String>> Function() action) async {
    try {
      _appendPaths(await action());
    } catch (e) {
      if (e is ScanCancelled) return;
      state = state.copyWith(error: e);
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

  /// Regenerates and saves the document. Returns the saved document, or null on
  /// failure / when no pages remain. On failure the previous document is intact.
  Future<ScannedDocument?> save() async {
    if (state.pages.isEmpty) {
      state = state.copyWith(error: const NoPagesSelected());
      return null;
    }
    final now = ref.read(clockProvider)();
    final quality = ref.read(settingsControllerProvider).pdfQuality;
    final processing = ref.read(documentProcessingServiceProvider);
    final title = state.title.trim().isEmpty
        ? (state.previous?.title ?? buildDefaultDocumentTitle(now))
        : state.title.trim();

    state = state.copyWith(
      phase: ProcessingPhase.preparing,
      currentPage: 0,
      totalPages: state.pages.length,
      clearError: true,
      clearNotice: true,
    );

    try {
      final result = await processing.buildAndSave(
        documentId: state.documentId!,
        title: title,
        createdAt: state.createdAt!,
        now: now,
        pages: state.pages,
        previous: state.previous,
        quality: quality,
        onProgress: (phase, done, total) => state = state.copyWith(
          phase: phase,
          currentPage: done,
          totalPages: total,
        ),
      );
      await ref.read(documentsControllerProvider.notifier).refresh();
      final info = result.ocrHardFailed ? const OcrFailure() : null;
      state = state.copyWith(
        phase: ProcessingPhase.done,
        saved: true,
        previous: result.document,
        pages: [...result.document.pages]
          ..sort((a, b) => a.order.compareTo(b.order)),
        error: info,
        clearError: info == null,
        noticeMessage: result.warning,
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

final documentEditControllerProvider =
    NotifierProvider.autoDispose<DocumentEditController, DocumentEditState>(
      DocumentEditController.new,
    );
