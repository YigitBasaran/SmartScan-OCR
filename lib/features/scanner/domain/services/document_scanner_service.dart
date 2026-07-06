/// Abstraction over the document scanner + image importer.
///
/// Implementations return absolute image file paths only (never a
/// scanner-generated PDF); the app performs its own review, OCR, compression
/// and PDF export. This keeps the UI independent of any specific plugin.
abstract class DocumentScannerService {
  /// Launches the native scanner and returns the scanned page image paths.
  ///
  /// Throws [ScanCancelled] if the user cancels and [NoPagesSelected] if the
  /// scan produced nothing.
  Future<List<String>> scanDocuments({int maxPages = 30});

  /// First-class import path: pick one or more images from the gallery.
  ///
  /// When [autoCorrect] is true, imports are routed through the native scanner's
  /// gallery flow to get automatic crop/perspective correction (best-effort;
  /// needs platform support), falling back to a raw picker otherwise. Throws
  /// [ScanCancelled] if the user cancels.
  Future<List<String>> importImages({bool autoCorrect = true});
}
