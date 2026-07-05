import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartscanocr/core/errors/app_exception.dart';
import 'package:smartscanocr/core/providers/app_providers.dart';
import 'package:smartscanocr/core/providers/service_providers.dart';
import 'package:smartscanocr/features/documents/domain/entities/ocr_status.dart';
import 'package:smartscanocr/features/scanner/presentation/controllers/scan_review_controller.dart';
import 'package:smartscanocr/features/scanner/presentation/controllers/scan_review_state.dart';

import 'support/fakes.dart';

ProviderContainer _makeContainer({
  FakeOcrService? ocr,
  FakePdfExportService? pdf,
  FakeDocumentScannerService? scanner,
  InMemoryDocumentRepository? repo,
}) {
  return ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(() => DateTime(2026, 7, 4, 15, 30, 45)),
      imageProcessorProvider.overrideWithValue(FakeImageProcessor()),
      fileStorageServiceProvider.overrideWithValue(FakeFileStorageService()),
      ocrServiceProvider.overrideWithValue(ocr ?? FakeOcrService()),
      pdfExportServiceProvider.overrideWithValue(pdf ?? FakePdfExportService()),
      documentScannerServiceProvider.overrideWithValue(
        scanner ?? FakeDocumentScannerService(),
      ),
      documentRepositoryProvider.overrideWithValue(
        repo ?? InMemoryDocumentRepository(),
      ),
      settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
    ],
  );
}

void main() {
  // Keep the autoDispose controller alive for the test's lifetime.
  ScanReviewController keepAlive(ProviderContainer container) {
    container.listen(scanReviewControllerProvider, (_, _) {});
    return container.read(scanReviewControllerProvider.notifier);
  }

  test('scan appends pages', () async {
    final container = _makeContainer();
    addTearDown(container.dispose);
    final controller = keepAlive(container);
    await controller.scan();
    expect(container.read(scanReviewControllerProvider).pages.length, 2);
  });

  test('import appends pages', () async {
    final container = _makeContainer();
    addTearDown(container.dispose);
    final controller = keepAlive(container);
    await controller.importImages();
    expect(container.read(scanReviewControllerProvider).pages.length, 1);
  });

  test('cancelled scan is silent (no error, no pages)', () async {
    final container = _makeContainer(
      scanner: FakeDocumentScannerService(scanError: const ScanCancelled()),
    );
    addTearDown(container.dispose);
    final controller = keepAlive(container);
    await controller.scan();
    final state = container.read(scanReviewControllerProvider);
    expect(state.pages, isEmpty);
    expect(state.error, isNull);
  });

  test('scanner error is surfaced', () async {
    final container = _makeContainer(
      scanner: FakeDocumentScannerService(
        scanError: const ScannerUnavailable(),
      ),
    );
    addTearDown(container.dispose);
    final controller = keepAlive(container);
    await controller.scan();
    expect(
      container.read(scanReviewControllerProvider).error,
      isA<ScannerUnavailable>(),
    );
  });

  test('rotate then remove re-indexes remaining pages', () async {
    final container = _makeContainer();
    addTearDown(container.dispose);
    final controller = keepAlive(container);
    await controller.scan(); // 2 pages
    final firstId = container.read(scanReviewControllerProvider).pages.first.id;

    controller.rotatePage(firstId);
    expect(
      container
          .read(scanReviewControllerProvider)
          .pages
          .first
          .rotationQuarterTurns,
      1,
    );

    controller.removePage(firstId);
    final pages = container.read(scanReviewControllerProvider).pages;
    expect(pages.length, 1);
    expect(pages.first.order, 0);
  });

  test('reorder moves a page to the target index', () async {
    final container = _makeContainer();
    addTearDown(container.dispose);
    final controller = keepAlive(container);
    await controller.scan(); // [a, b]
    final ids = container
        .read(scanReviewControllerProvider)
        .pages
        .map((p) => p.id)
        .toList();

    controller.reorderPage(0, 1); // move first to index 1 -> [b, a]
    final after = container.read(scanReviewControllerProvider).pages;
    expect(after.map((p) => p.id).toList(), [ids[1], ids[0]]);
    expect(after[0].order, 0);
    expect(after[1].order, 1);
  });

  test('runOcrAndSavePdf saves a document and reports done', () async {
    final repo = InMemoryDocumentRepository();
    final pdf = FakePdfExportService();
    final container = _makeContainer(repo: repo, pdf: pdf);
    addTearDown(container.dispose);
    final controller = keepAlive(container);

    await controller.scan();
    final document = await controller.runOcrAndSavePdf();

    expect(document, isNotNull);
    expect(pdf.calls, 1);
    final state = container.read(scanReviewControllerProvider);
    expect(state.phase, ProcessingPhase.done);
    expect(state.savedDocumentId, document!.id);

    final saved = await repo.getDocuments();
    expect(saved.length, 1);
    expect(saved.first.pdfPath, isNotNull);
    expect(saved.first.combinedText, isNotEmpty);
    expect(saved.first.ocrStatus, OcrStatus.done);
  });

  test(
    'OCR failure still generates and saves the PDF (failed status)',
    () async {
      final repo = InMemoryDocumentRepository();
      final pdf = FakePdfExportService();
      final container = _makeContainer(
        repo: repo,
        pdf: pdf,
        ocr: FakeOcrService(throwError: true),
      );
      addTearDown(container.dispose);
      final controller = keepAlive(container);

      await controller.scan();
      final document = await controller.runOcrAndSavePdf();

      expect(document, isNotNull);
      expect(pdf.calls, 1); // PDF still generated despite OCR failure
      expect(document!.pdfPath, isNotNull);
      expect(document.ocrStatus, OcrStatus.failed);
      expect(
        container.read(scanReviewControllerProvider).error,
        isA<OcrFailure>(),
      );
      expect((await repo.getDocuments()).length, 1);
    },
  );

  test('no recognized text yields an OcrNoText info but still saves', () async {
    final repo = InMemoryDocumentRepository();
    final container = _makeContainer(
      repo: repo,
      ocr: FakeOcrService(textPerPage: '', status: OcrStatus.done),
    );
    addTearDown(container.dispose);
    final controller = keepAlive(container);

    await controller.scan();
    final document = await controller.runOcrAndSavePdf();

    expect(document, isNotNull);
    expect(
      container.read(scanReviewControllerProvider).error,
      isA<OcrNoText>(),
    );
    expect((await repo.getDocuments()).length, 1);
  });

  test(
    'running with no pages sets NoPagesSelected and saves nothing',
    () async {
      final repo = InMemoryDocumentRepository();
      final container = _makeContainer(repo: repo);
      addTearDown(container.dispose);
      final controller = keepAlive(container);

      final document = await controller.runOcrAndSavePdf();
      expect(document, isNull);
      expect(
        container.read(scanReviewControllerProvider).error,
        isA<NoPagesSelected>(),
      );
      expect(await repo.getDocuments(), isEmpty);
    },
  );

  test('default title is derived from the clock when none is set', () async {
    final container = _makeContainer();
    addTearDown(container.dispose);
    final controller = keepAlive(container);
    await controller.scan();
    final document = await controller.runOcrAndSavePdf();
    expect(document!.title, 'Scan 2026-07-04 15:30');
  });
}
