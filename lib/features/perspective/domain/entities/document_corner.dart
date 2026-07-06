/// A document corner in **normalized** image coordinates: `x` and `y` are each
/// in `[0..1]` of the source image's width/height. Storing corners normalized
/// keeps them resolution-independent, so the same crop applies at any
/// `PdfQuality` output size.
class DocumentCorner {
  const DocumentCorner(this.x, this.y);

  final double x;
  final double y;

  DocumentCorner clampToUnit() =>
      DocumentCorner(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0));

  Map<String, dynamic> toMap() => {'x': x, 'y': y};

  factory DocumentCorner.fromMap(Map<String, dynamic> map) => DocumentCorner(
    (map['x'] as num).toDouble(),
    (map['y'] as num).toDouble(),
  );

  @override
  bool operator ==(Object other) =>
      other is DocumentCorner && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}
