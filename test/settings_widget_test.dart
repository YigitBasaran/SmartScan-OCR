import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartscanocr/core/providers/service_providers.dart';
import 'package:smartscanocr/features/pdf_export/domain/entities/pdf_quality.dart';
import 'package:smartscanocr/features/settings/presentation/screens/settings_screen.dart';

import 'support/fakes.dart';

Widget _wrap(FakeSettingsRepository repo) => ProviderScope(
  overrides: [settingsRepositoryProvider.overrideWithValue(repo)],
  child: const MaterialApp(home: SettingsScreen()),
);

void main() {
  testWidgets('changing the theme mode persists it', (tester) async {
    final repo = FakeSettingsRepository();
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(repo.saved?.themeMode, ThemeMode.dark);
  });

  testWidgets('changing the PDF quality persists it', (tester) async {
    final repo = FakeSettingsRepository();
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('High quality'));
    await tester.pumpAndSettle();

    expect(repo.saved?.pdfQuality, PdfQuality.high);
  });
}
