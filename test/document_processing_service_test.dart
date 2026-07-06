import 'package:flutter_test/flutter_test.dart';
import 'package:smartscanocr/core/errors/app_exception.dart';
import 'package:smartscanocr/features/documents/data/document_processing_service_impl.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_document.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_page.dart';
import 'package:smartscanocr/features/pdf_export/domain/entities/pdf_export_mode.dart';
import 'package:smartscanocr/features/pdf_export/domain/entities/pdf_quality.dart';
import 'package:smartscanocr/features/perspective/data/noop_perspective_correction_service.dart';
import 'package:uuid/uuid.dart';

import 'support/fakes.dart';

void main() {
  late FakeOcrService ocr;
  late FakePdfExportService pdf;
  late InMemoryDocumentRepository repo;
  late FakeFileStorageService storage;

  DocumentProcessingServiceImpl build() => DocumentProcessingServiceImpl(
    imageProcessor: FakeImageProcessor(),
    ocrService: ocr,
    pdfService: pdf,
    storage: storage,
    repository: repo,
    correctionService: const NoOpPerspectiveCorrectionService(),
    uuid: const Uuid(),
  );

  setUp(() {
    ocr = FakeOcrService();
    pdf = FakePdfExportService();
    repo = InMemoryDocumentRepository();
    storage = FakeFileStorageService();
  });

  // Creates an initial 2-page document ('a', 'b') and returns it.
  Future<ScannedDocument> seedDocument() async {
    final result = await build().buildAndSave(
      documentId: 'doc',
      title: 'Doc',
      createdAt: DateTime(2026),
      now: DateTime(2026),
      pages: const [
        ScannedPage(id: 'a', originalImagePath: 'a.jpg', order: 0),
        ScannedPage(id: 'b', originalImagePath: 'b.jpg', order: 1),
      ],
      quality: PdfQuality.balanced,
    );
    return result.document;
  }

  test('initial build OCRs all pages and generates a PDF', () async {
    final doc = await seedDocument();
    expect(ocr.calls, 1);
    expect(ocr.lastPageIds, ['a', 'b']);
    expect(pdf.calls, 1);
    expect(doc.pageCount, 2);
    expect((await repo.getDocuments()).length, 1);
  });

  test('reorder regenerates PDF without re-running OCR', () async {
    final doc = await seedDocument();
    final ocrCalls = ocr.calls;

    final reordered = [doc.pages[1], doc.pages[0]];
    final result = await build().buildAndSave(
      documentId: 'doc',
      title: 'Doc',
      createdAt: doc.createdAt,
      now: DateTime(2026, 1, 2),
      pages: reordered,
      previous: doc,
      quality: PdfQuality.balanced,
    );

    expect(ocr.calls, ocrCalls, reason: 'no OCR rerun on reorder');
    expect(pdf.calls, 2, reason: 'PDF regenerated');
    expect(result.document.pages.map((p) => p.id).toList(), ['b', 'a']);
    expect(result.document.pages[0].order, 0);
    expect(result.document.updatedAt, DateTime(2026, 1, 2));
  });

  test('delete removes a page, regenerates PDF, no OCR rerun', () async {
    final doc = await seedDocument();
    final ocrCalls = ocr.calls;

    final result = await build().buildAndSave(
      documentId: 'doc',
      title: 'Doc',
      createdAt: doc.createdAt,
      now: DateTime(2026, 1, 2),
      pages: [doc.pages[0]],
      previous: doc,
      quality: PdfQuality.balanced,
    );

    expect(result.document.pageCount, 1);
    expect(ocr.calls, ocrCalls, reason: 'survivor unchanged');
    expect(pdf.calls, 2);
    expect(storage.deletedPages, contains('doc/b'));
  });

  test(
    'add runs OCR for the new page only and preserves existing text',
    () async {
      final doc = await seedDocument();

      final added = [
        ...doc.pages,
        const ScannedPage(id: 'c', originalImagePath: 'c.jpg', order: 2),
      ];
      final result = await build().buildAndSave(
        documentId: 'doc',
        title: 'Doc',
        createdAt: doc.createdAt,
        now: DateTime(2026, 1, 2),
        pages: added,
        previous: doc,
        quality: PdfQuality.balanced,
      );

      expect(result.document.pageCount, 3);
      expect(ocr.lastPageIds, ['c'], reason: 'only the new page is OCR-ed');
      expect(result.document.pages.every((p) => p.hasText), isTrue);
    },
  );

  test('editing one page re-runs OCR only for that page', () async {
    final doc = await seedDocument();

    final edited = [
      doc.pages[0].copyWith(rotationQuarterTurns: 1, clearProcessed: true),
      doc.pages[1],
    ];
    final result = await build().buildAndSave(
      documentId: 'doc',
      title: 'Doc',
      createdAt: doc.createdAt,
      now: DateTime(2026, 1, 2),
      pages: edited,
      previous: doc,
      quality: PdfQuality.balanced,
    );

    expect(ocr.lastPageIds, ['a'], reason: 'only the edited page is OCR-ed');
    expect(result.document.pages.every((p) => p.hasText), isTrue);
  });

  test(
    'PDF failure leaves the previous document and metadata intact',
    () async {
      final doc = await seedDocument();
      final savedUpdatedAt = doc.updatedAt;

      final failing = DocumentProcessingServiceImpl(
        imageProcessor: FakeImageProcessor(),
        ocrService: ocr,
        pdfService: FakePdfExportService(throwError: true),
        storage: storage,
        repository: repo,
        correctionService: const NoOpPerspectiveCorrectionService(),
        uuid: const Uuid(),
      );

      await expectLater(
        () => failing.buildAndSave(
          documentId: 'doc',
          title: 'Doc',
          createdAt: doc.createdAt,
          now: DateTime(2026, 1, 2),
          pages: [
            doc.pages[0].copyWith(
              rotationQuarterTurns: 1,
              clearProcessed: true,
            ),
            doc.pages[1],
          ],
          previous: doc,
          quality: PdfQuality.balanced,
        ),
        throwsA(isA<AppException>()),
      );

      // Rolled back: staged temps discarded, metadata unchanged.
      expect(storage.pdfDiscarded, isTrue);
      final reloaded = await repo.getById('doc');
      expect(reloaded!.updatedAt, savedUpdatedAt);
      // No previous processed image files were deleted.
      expect(storage.deletedFiles, isEmpty);
    },
  );

  test(
    'editing a page changes its processedImagePath; unchanged pages keep theirs',
    () async {
      final doc = await seedDocument();
      final seedA = doc.pages.firstWhere((p) => p.id == 'a').processedImagePath;
      final seedB = doc.pages.firstWhere((p) => p.id == 'b').processedImagePath;

      final result = await build().buildAndSave(
        documentId: 'doc',
        title: 'Doc',
        createdAt: doc.createdAt,
        now: DateTime(2026, 1, 2),
        pages: [
          doc.pages[0].copyWith(rotationQuarterTurns: 1, clearProcessed: true),
          doc.pages[1],
        ],
        previous: doc,
        quality: PdfQuality.balanced,
      );

      final newA = result.document.pages
          .firstWhere((p) => p.id == 'a')
          .processedImagePath;
      final newB = result.document.pages
          .firstWhere((p) => p.id == 'b')
          .processedImagePath;
      expect(
        newA,
        isNot(seedA),
        reason: 'edited page path changes → UI reloads',
      );
      expect(newB, seedB, reason: 'unchanged page keeps its path');
      expect(
        storage.deletedFiles,
        contains(seedA),
        reason: 'old version deleted only after a successful save',
      );
    },
  );

  test('reorder does not change any processed image path', () async {
    final doc = await seedDocument();
    final result = await build().buildAndSave(
      documentId: 'doc',
      title: 'Doc',
      createdAt: doc.createdAt,
      now: DateTime(2026, 1, 2),
      pages: [doc.pages[1], doc.pages[0]],
      previous: doc,
      quality: PdfQuality.balanced,
    );
    for (final p in result.document.pages) {
      final seed = doc.pages.firstWhere((s) => s.id == p.id).processedImagePath;
      expect(p.processedImagePath, seed);
    }
    expect(storage.deletedFiles, isEmpty);
  });

  test('generated PDFs are watermarked', () async {
    await seedDocument();
    expect(pdf.renderModes, isNotEmpty);
    expect(pdf.renderModes, everyElement(PdfExportMode.watermarked));
  });
}
