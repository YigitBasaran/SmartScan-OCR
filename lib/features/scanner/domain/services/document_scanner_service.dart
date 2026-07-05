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

  /// First-class fallback/import path: pick one or more images from the gallery.
  ///
  /// Throws [ScanCancelled] if the user cancels.
  Future<List<String>> importImages();
}
