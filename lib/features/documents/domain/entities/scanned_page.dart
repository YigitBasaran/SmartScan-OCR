/// A single page of a scanned/imported document.
///
/// [rotationQuarterTurns] is the pending rotation applied during review; it is
/// baked into the saved image (and reset to 0) when the document is saved.
class ScannedPage {
  const ScannedPage({
    required this.id,
    required this.imagePath,
    required this.order,
    this.rotationQuarterTurns = 0,
    this.ocrText,
  });

  final String id;
  final String imagePath;
  final int order;
  final int rotationQuarterTurns;
  final String? ocrText;

  bool get hasText => (ocrText ?? '').trim().isNotEmpty;

  ScannedPage copyWith({
    String? id,
    String? imagePath,
    int? order,
    int? rotationQuarterTurns,
    String? ocrText,
  }) {
    return ScannedPage(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      order: order ?? this.order,
      rotationQuarterTurns: rotationQuarterTurns ?? this.rotationQuarterTurns,
      ocrText: ocrText ?? this.ocrText,
    );
  }
}
