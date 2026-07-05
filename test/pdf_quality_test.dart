import 'package:flutter_test/flutter_test.dart';
import 'package:smartscanocr/features/pdf_export/domain/entities/pdf_quality.dart';

void main() {
  group('PdfQuality mapping', () {
    test('maps each level to the expected (maxDimension, jpegQuality)', () {
      expect(PdfQuality.small.maxDimension, 1240);
      expect(PdfQuality.small.jpegQuality, 60);
      expect(PdfQuality.balanced.maxDimension, 1754);
      expect(PdfQuality.balanced.jpegQuality, 75);
      expect(PdfQuality.high.maxDimension, 2480);
      expect(PdfQuality.high.jpegQuality, 85);
    });

    test('quality increases dimension and jpeg quality monotonically', () {
      expect(
        PdfQuality.small.maxDimension < PdfQuality.balanced.maxDimension,
        isTrue,
      );
      expect(
        PdfQuality.balanced.maxDimension < PdfQuality.high.maxDimension,
        isTrue,
      );
    });
  });

  group('parsePdfQuality', () {
    test('parses a known name', () {
      expect(parsePdfQuality('high'), PdfQuality.high);
    });

    test('falls back to balanced for unknown/null', () {
      expect(parsePdfQuality('nonsense'), PdfQuality.balanced);
      expect(parsePdfQuality(null), PdfQuality.balanced);
    });
  });
}
