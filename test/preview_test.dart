import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartscanocr/features/documents/domain/entities/page_filter.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_page.dart';
import 'package:smartscanocr/features/documents/presentation/widgets/document_page_preview.dart';
import 'package:smartscanocr/features/documents/presentation/widgets/page_filter_preview.dart';

void main() {
  group('displayFilter', () {
    test('is the pending filter until processed, then none', () {
      const pending = ScannedPage(
        id: 'p',
        originalImagePath: 'a.jpg',
        order: 0,
        filterMode: PageFilter.blackWhite,
      );
      expect(pending.displayFilter, PageFilter.blackWhite);

      const processed = ScannedPage(
        id: 'p',
        originalImagePath: 'a.jpg',
        processedImagePath: 'a.jpg',
        order: 0,
        filterMode: PageFilter.blackWhite,
      );
      expect(processed.displayFilter, PageFilter.none);
    });
  });

  group('applyFilterPreview', () {
    const child = SizedBox();

    test('none returns the child unchanged', () {
      expect(applyFilterPreview(PageFilter.none, child), same(child));
    });

    test('non-none filters wrap the child in a ColorFiltered', () {
      for (final filter in [
        PageFilter.grayscale,
        PageFilter.blackWhite,
        PageFilter.enhance,
      ]) {
        expect(applyFilterPreview(filter, child), isA<ColorFiltered>());
      }
    });
  });

  testWidgets('document preview shows the watermark label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DocumentPagePreview(
            pages: [
              ScannedPage(
                id: 'p',
                originalImagePath: 'x.jpg',
                processedImagePath: 'x.jpg',
                order: 0,
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Scanned with SmartScan OCR'), findsWidgets);
  });
}
