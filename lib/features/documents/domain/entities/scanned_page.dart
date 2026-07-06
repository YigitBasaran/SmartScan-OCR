import 'package:smartscanocr/features/documents/domain/entities/page_filter.dart';
import 'package:smartscanocr/features/perspective/domain/entities/document_corner.dart';

/// A single page of a scanned/imported document.
///
/// Edits are non-destructive: [originalImagePath] is the raw scan/import and is
/// never overwritten; [processedImagePath] is the edited output (rotation, crop,
/// filter, compression) actually embedded in the PDF and fed to OCR. When it is
/// null the page has not been processed yet and [effectiveImagePath] falls back
/// to the original.
class ScannedPage {
  const ScannedPage({
    required this.id,
    required this.originalImagePath,
    required this.order,
    this.processedImagePath,
    this.rotationQuarterTurns = 0,
    this.cropCorners,
    this.filterMode = PageFilter.none,
    this.ocrText,
  });

  final String id;

  /// Immutable raw source image (never overwritten).
  final String originalImagePath;

  /// Edited output used for OCR + PDF; null => not yet processed.
  final String? processedImagePath;

  final int order;
  final int rotationQuarterTurns;

  /// Manual crop quad in normalized [0..1] source coordinates; null => full frame.
  final List<DocumentCorner>? cropCorners;

  final PageFilter filterMode;
  final String? ocrText;

  /// Image used for OCR + PDF: the processed output when present, else original.
  String get effectiveImagePath => processedImagePath ?? originalImagePath;

  /// Rotation to apply when *displaying* [effectiveImagePath]. Zero once a page
  /// is processed (rotation is baked into the processed image); otherwise the
  /// pending review rotation is applied live to the original.
  int get displayQuarterTurns =>
      processedImagePath != null ? 0 : rotationQuarterTurns;

  /// Filter to apply live when displaying a not-yet-processed page (the pending
  /// filter is baked into the processed image, so processed pages use none).
  PageFilter get displayFilter =>
      processedImagePath != null ? PageFilter.none : filterMode;

  bool get hasText => (ocrText ?? '').trim().isNotEmpty;

  bool get hasEdits =>
      rotationQuarterTurns != 0 ||
      cropCorners != null ||
      filterMode != PageFilter.none;

  /// Stable signature of the inputs that determine the processed output. Two
  /// pages with the same signature produce the same processed image, so save
  /// can skip reprocessing (and re-OCR) when it is unchanged.
  String get editSignature {
    final corners = cropCorners == null
        ? 'none'
        : cropCorners!
              .map((c) => '${c.x.toStringAsFixed(4)},${c.y.toStringAsFixed(4)}')
              .join(';');
    return '$originalImagePath|r$rotationQuarterTurns|f${filterMode.name}|c$corners';
  }

  ScannedPage copyWith({
    String? id,
    String? originalImagePath,
    String? processedImagePath,
    bool clearProcessed = false,
    int? order,
    int? rotationQuarterTurns,
    List<DocumentCorner>? cropCorners,
    bool clearCorners = false,
    PageFilter? filterMode,
    String? ocrText,
    bool clearOcr = false,
  }) {
    return ScannedPage(
      id: id ?? this.id,
      originalImagePath: originalImagePath ?? this.originalImagePath,
      processedImagePath: clearProcessed
          ? null
          : (processedImagePath ?? this.processedImagePath),
      order: order ?? this.order,
      rotationQuarterTurns: rotationQuarterTurns ?? this.rotationQuarterTurns,
      cropCorners: clearCorners ? null : (cropCorners ?? this.cropCorners),
      filterMode: filterMode ?? this.filterMode,
      ocrText: clearOcr ? null : (ocrText ?? this.ocrText),
    );
  }
}
