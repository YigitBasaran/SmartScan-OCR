import 'package:smartscanocr/features/documents/domain/entities/scanned_page.dart';

/// The step the save pipeline is currently on.
enum ProcessingPhase { idle, preparing, ocr, generatingPdf, saving, done }

extension ProcessingPhaseLabel on ProcessingPhase {
  String get label => switch (this) {
    ProcessingPhase.idle => '',
    ProcessingPhase.preparing => 'Preparing pages',
    ProcessingPhase.ocr => 'Recognizing text',
    ProcessingPhase.generatingPdf => 'Creating PDF',
    ProcessingPhase.saving => 'Saving',
    ProcessingPhase.done => 'Done',
  };
}

/// Immutable state for the scan/import review + save flow.
class ScanReviewState {
  const ScanReviewState({
    this.title = '',
    this.pages = const [],
    this.phase = ProcessingPhase.idle,
    this.currentPage = 0,
    this.totalPages = 0,
    this.error,
    this.savedDocumentId,
  });

  final String title;
  final List<ScannedPage> pages;
  final ProcessingPhase phase;
  final int currentPage;
  final int totalPages;

  /// Set on failure (or non-blocking info such as no-text); the UI reads + clears it.
  final Object? error;

  /// Set once saving completes so the UI can navigate to the new document.
  final String? savedDocumentId;

  bool get isEmpty => pages.isEmpty;
  bool get isBusy =>
      phase != ProcessingPhase.idle && phase != ProcessingPhase.done;

  double? get progress {
    if (totalPages <= 0) return null;
    return (currentPage / totalPages).clamp(0.0, 1.0);
  }

  ScanReviewState copyWith({
    String? title,
    List<ScannedPage>? pages,
    ProcessingPhase? phase,
    int? currentPage,
    int? totalPages,
    Object? error,
    bool clearError = false,
    String? savedDocumentId,
    bool clearSaved = false,
  }) {
    return ScanReviewState(
      title: title ?? this.title,
      pages: pages ?? this.pages,
      phase: phase ?? this.phase,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      error: clearError ? null : (error ?? this.error),
      savedDocumentId: clearSaved
          ? null
          : (savedDocumentId ?? this.savedDocumentId),
    );
  }
}
