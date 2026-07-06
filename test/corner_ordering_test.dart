import 'package:flutter_test/flutter_test.dart';
import 'package:smartscanocr/features/perspective/domain/corner_ordering.dart';
import 'package:smartscanocr/features/perspective/domain/entities/document_corner.dart';

void main() {
  test('orders a skewed quad into TL / TR / BR / BL', () {
    // Supplied out of order (TR, TL, BL, BR).
    final corners = const [
      DocumentCorner(0.9, 0.12), // top-right (small y, large x)
      DocumentCorner(0.08, 0.1), // top-left (small x + y)
      DocumentCorner(0.12, 0.9), // bottom-left (large y, small x)
      DocumentCorner(0.88, 0.92), // bottom-right (large x + y)
    ];

    final ordered = orderCorners(corners);

    expect(ordered.topLeft, const DocumentCorner(0.08, 0.1));
    expect(ordered.topRight, const DocumentCorner(0.9, 0.12));
    expect(ordered.bottomRight, const DocumentCorner(0.88, 0.92));
    expect(ordered.bottomLeft, const DocumentCorner(0.12, 0.9));
  });
}
