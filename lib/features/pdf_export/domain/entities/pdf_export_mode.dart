/// How a PDF should be rendered for export.
enum PdfExportMode {
  /// Free default: draws the SmartScan OCR branding watermark on each page.
  watermarked,

  /// Watermark-free output (unlocked per-export via a rewarded ad).
  watermarkFree,
}
