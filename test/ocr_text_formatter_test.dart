import 'package:flutter_test/flutter_test.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_page.dart';
import 'package:smartscanocr/features/documents/domain/ocr_text_formatter.dart';

import 'support/factories.dart';

void main() {
  test('formatForSharing includes the title and per-page headers in order', () {
    final doc = makeDocument(
      id: 'd',
      title: 'March Invoice',
      pages: const [
        // Deliberately out of insertion order to prove it sorts by `order`.
        ScannedPage(
          id: 'p2',
          originalImagePath: 'b',
          order: 1,
          ocrText: 'second page text',
        ),
        ScannedPage(
          id: 'p1',
          originalImagePath: 'a',
          order: 0,
          ocrText: 'first page text',
        ),
      ],
    );

    final text = OcrTextFormatter.formatForSharing(doc);

    expect(text, contains('SmartScan OCR - March Invoice'));
    expect(text.indexOf('Page 1'), lessThan(text.indexOf('Page 2')));
    expect(
      text.indexOf('first page text'),
      lessThan(text.indexOf('second page text')),
      reason: 'ordered by order, not insertion order',
    );
  });

  test('an empty-OCR page renders "No text detected."', () {
    final doc = makeDocument(
      id: 'd',
      pages: const [ScannedPage(id: 'p', originalImagePath: 'a', order: 0)],
    );
    expect(
      OcrTextFormatter.formatForSharing(doc),
      contains('No text detected.'),
    );
  });

  test('rebuildCombinedText is order-driven', () {
    final pages = const [
      ScannedPage(id: 'b', originalImagePath: 'b', order: 1, ocrText: 'B'),
      ScannedPage(id: 'a', originalImagePath: 'a', order: 0, ocrText: 'A'),
    ];
    expect(OcrTextFormatter.rebuildCombinedText(pages), 'A\n\nB');
  });
}
