import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartscanocr/core/providers/service_providers.dart';
import 'package:smartscanocr/features/documents/presentation/screens/document_detail_screen.dart';
import 'package:smartscanocr/features/pdf_export/domain/entities/pdf_export_mode.dart';

import 'support/factories.dart';
import 'support/fakes.dart';

void main() {
  late FakeFileStorageService storage;
  late FakePdfExportService pdf;
  late FakeSharingService sharing;

  Future<void> pumpDetail(
    WidgetTester tester,
    FakeRewardedAdService ads,
  ) async {
    final repo = InMemoryDocumentRepository([
      makeDocument(id: '1', title: 'March Invoice', text: 'hello'),
    ]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          documentRepositoryProvider.overrideWithValue(repo),
          fileStorageServiceProvider.overrideWithValue(storage),
          pdfExportServiceProvider.overrideWithValue(pdf),
          sharingServiceProvider.overrideWithValue(sharing),
          rewardedAdServiceProvider.overrideWithValue(ads),
        ],
        child: const MaterialApp(home: DocumentDetailScreen(documentId: '1')),
      ),
    );
    // Resolve the async documents load.
    await tester.pump();
    await tester.pump();
  }

  setUp(() {
    storage = FakeFileStorageService();
    pdf = FakePdfExportService();
    sharing = FakeSharingService();
  });

  Future<void> chooseRemoveWatermark(WidgetTester tester) async {
    await tester.tap(find.text('Share PDF'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove watermark'));
    await tester.pumpAndSettle();
  }

  testWidgets('watermark-free export requires the ad on every export', (
    tester,
  ) async {
    final ads = FakeRewardedAdService(earned: true);
    await pumpDetail(tester, ads);

    await chooseRemoveWatermark(tester);
    expect(ads.showCalls, 1);
    expect(pdf.renderModes, [PdfExportMode.watermarkFree]);
    expect(sharing.sharedPdfNames, ['March_Invoice.pdf']);

    // A second watermark-free export must show the ad again (no persisted unlock).
    await chooseRemoveWatermark(tester);
    expect(ads.showCalls, 2);
    expect(sharing.sharedPdfNames.length, 2);
  });

  testWidgets('reward not earned does not export watermark-free', (
    tester,
  ) async {
    final ads = FakeRewardedAdService(earned: false);
    await pumpDetail(tester, ads);

    await chooseRemoveWatermark(tester);
    expect(ads.showCalls, 1);
    expect(pdf.renderModes, isEmpty);
    expect(sharing.sharedPdfPaths, isEmpty);
  });

  testWidgets('ad unavailable keeps the watermarked export path', (
    tester,
  ) async {
    final ads = FakeRewardedAdService(available: false);
    await pumpDetail(tester, ads);

    await chooseRemoveWatermark(tester);
    expect(ads.showCalls, 0, reason: 'no ad shown when unavailable');
    expect(sharing.sharedPdfPaths, isEmpty);

    // Watermarked export still works.
    await tester.tap(find.text('Share PDF'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Export with watermark'));
    await tester.pumpAndSettle();
    expect(sharing.sharedPdfNames, ['March_Invoice.pdf']);
  });
}
