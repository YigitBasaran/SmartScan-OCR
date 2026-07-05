import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartscanocr/core/providers/service_providers.dart';
import 'package:smartscanocr/features/documents/presentation/screens/library_screen.dart';

import 'support/factories.dart';
import 'support/fakes.dart';

Widget _wrap(InMemoryDocumentRepository repo) {
  return ProviderScope(
    overrides: [
      documentRepositoryProvider.overrideWithValue(repo),
      fileStorageServiceProvider.overrideWithValue(FakeFileStorageService()),
    ],
    child: const MaterialApp(home: LibraryScreen()),
  );
}

void main() {
  testWidgets('shows the empty state when there are no documents', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(InMemoryDocumentRepository()));
    // Let the async documents load resolve (avoid pumpAndSettle: the loading
    // spinner animates indefinitely).
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('No documents yet'), findsOneWidget);
  });

  testWidgets('search filters the document list by title', (tester) async {
    final repo = InMemoryDocumentRepository([
      makeDocument(id: '1', title: 'Invoice'),
      makeDocument(id: '2', title: 'Recipe'),
    ]);
    await tester.pumpWidget(_wrap(repo));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('Invoice'), findsOneWidget);
    expect(find.text('Recipe'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'invoice');
    await tester.pump();
    await tester.pump();

    expect(find.text('Invoice'), findsOneWidget);
    expect(find.text('Recipe'), findsNothing);
  });
}
