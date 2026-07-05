/// The PDF export quality, controlling image resize + JPEG compression.
///
/// Each level maps to a maximum image dimension (longest side, in pixels) and a
/// JPEG quality. Lower values produce smaller files.
enum PdfQuality { small, balanced, high }

/// Parses a [PdfQuality] from its persisted `name`, defaulting to [PdfQuality.balanced].
PdfQuality parsePdfQuality(String? name) => PdfQuality.values.firstWhere(
  (q) => q.name == name,
  orElse: () => PdfQuality.balanced,
);

extension PdfQualitySettings on PdfQuality {
  /// Longest side (in pixels) a page image is resized to before JPEG encoding.
  int get maxDimension => switch (this) {
    PdfQuality.small => 1240,
    PdfQuality.balanced => 1754,
    PdfQuality.high => 2480,
  };

  /// JPEG encoding quality (0-100). Lower = smaller file.
  int get jpegQuality => switch (this) {
    PdfQuality.small => 60,
    PdfQuality.balanced => 75,
    PdfQuality.high => 85,
  };

  String get label => switch (this) {
    PdfQuality.small => 'Smaller file',
    PdfQuality.balanced => 'Balanced',
    PdfQuality.high => 'High quality',
  };

  String get description => switch (this) {
    PdfQuality.small => 'Lower resolution, smallest PDF size.',
    PdfQuality.balanced => 'A good balance of clarity and file size.',
    PdfQuality.high => 'Sharpest text, larger PDF size.',
  };
}
