/// Shares/prints documents via the platform share sheet and print dialog.
///
/// Kept behind an interface so the UI never depends on `share_plus`/`printing`
/// directly, and so it can be faked in tests.
abstract class SharingService {
  /// Shares the PDF at [path]. [fileName] overrides the shared file's name
  /// (e.g. `SmartScan_20260704_153045.pdf`) since the on-disk file is `export.pdf`.
  Future<void> sharePdf({required String path, String? fileName});

  /// Shares plain [text] (e.g. the recognized OCR text).
  Future<void> shareText(String text);

  /// Opens the system print/preview dialog for the PDF at [path].
  Future<void> printPdf(String path);
}
