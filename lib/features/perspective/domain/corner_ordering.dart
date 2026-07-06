import 'package:smartscanocr/features/perspective/domain/entities/document_corner.dart';

/// Four document corners in the order `image`'s `copyRectify` expects.
class OrderedCorners {
  const OrderedCorners({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
  });

  final DocumentCorner topLeft;
  final DocumentCorner topRight;
  final DocumentCorner bottomRight;
  final DocumentCorner bottomLeft;
}

/// Sorts four arbitrary corner points into top-left / top-right / bottom-right /
/// bottom-left using the classic sum/difference heuristic:
/// - top-left has the smallest `x + y`, bottom-right the largest;
/// - top-right has the smallest `y - x`, bottom-left the largest.
///
/// Works in any consistent coordinate space (normalized or pixel). Requires
/// exactly four corners.
OrderedCorners orderCorners(List<DocumentCorner> corners) {
  assert(corners.length == 4, 'orderCorners requires exactly 4 corners');
  DocumentCorner minBy(double Function(DocumentCorner) key) =>
      corners.reduce((a, b) => key(a) <= key(b) ? a : b);
  DocumentCorner maxBy(double Function(DocumentCorner) key) =>
      corners.reduce((a, b) => key(a) >= key(b) ? a : b);

  return OrderedCorners(
    topLeft: minBy((c) => c.x + c.y),
    bottomRight: maxBy((c) => c.x + c.y),
    topRight: minBy((c) => c.y - c.x),
    bottomLeft: maxBy((c) => c.y - c.x),
  );
}
