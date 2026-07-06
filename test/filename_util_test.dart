import 'package:flutter_test/flutter_test.dart';
import 'package:smartscanocr/core/utils/filename_util.dart';

void main() {
  group('buildPdfFileName', () {
    test('formats the timestamp as SmartScan_yyyyMMdd_HHmmss.pdf', () {
      final date = DateTime(2026, 7, 4, 15, 30, 45);
      expect(buildPdfFileName(date), 'SmartScan_20260704_153045.pdf');
    });

    test('zero-pads single-digit month/day/time components', () {
      final date = DateTime(2026, 1, 2, 3, 4, 5);
      expect(buildPdfFileName(date), 'SmartScan_20260102_030405.pdf');
    });
  });

  group('sanitizeTitle', () {
    test('removes illegal filename characters and collapses whitespace', () {
      expect(sanitizeTitle('  a/b:c*?  d '), 'abc d');
    });

    test('returns empty for whitespace-only input', () {
      expect(sanitizeTitle('   '), '');
    });
  });

  test('buildDefaultDocumentTitle produces a friendly title', () {
    final date = DateTime(2026, 7, 4, 15, 30);
    expect(buildDefaultDocumentTitle(date), 'Scan 2026-07-04 15:30');
  });

  group('buildShareFileName', () {
    test('uses the sanitized title with underscores for spaces', () {
      expect(
        buildShareFileName('March Invoice', DateTime(2026, 7, 4, 15, 30, 45)),
        'March_Invoice.pdf',
      );
    });

    test('empty title falls back to the timestamped name', () {
      expect(
        buildShareFileName('   ', DateTime(2026, 7, 4, 15, 30, 45)),
        'SmartScan_20260704_153045.pdf',
      );
    });

    test('strips illegal characters and collapses separators', () {
      expect(
        buildShareFileName('Report: Q1  2026', DateTime(2026)),
        'Report_Q1_2026.pdf',
      );
    });
  });
}
