import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartscanocr/features/perspective/domain/entities/document_corner.dart';
import 'package:smartscanocr/features/perspective/presentation/crop_geometry.dart';

void main() {
  test('containedRect is the full box when aspect ratios match', () {
    final rect = containedRect(const Size(200, 100), 2.0);
    expect(rect, const Rect.fromLTWH(0, 0, 200, 100));
  });

  test('containedRect letterboxes a wide image inside a square box', () {
    final rect = containedRect(const Size(200, 200), 2.0);
    expect(rect, const Rect.fromLTWH(0, 50, 200, 100));
  });

  test('screen<->normalized round-trips (independent of letterbox)', () {
    final fit = containedRect(const Size(200, 200), 2.0); // top=50, h=100
    const corner = DocumentCorner(0.25, 0.75);
    final screen = normalizedToScreen(corner, fit);
    final back = screenToNormalized(screen, fit);
    expect(back.x, closeTo(0.25, 1e-9));
    expect(back.y, closeTo(0.75, 1e-9));
  });
}
