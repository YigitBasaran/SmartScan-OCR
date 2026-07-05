import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartscanocr/core/providers/service_providers.dart';
import 'package:smartscanocr/features/documents/presentation/controllers/documents_controller.dart';

import 'support/factories.dart';
import 'support/fakes.dart';

ProviderContainer _containerWith(InMemoryDocumentRepository repo) {
  return ProviderContainer(
    overrides: [
      documentRepositoryProvider.overrideWithValue(repo),
      fileStorageServiceProvider.overrideWithValue(FakeFileStorageService()),
    ],
  );
}

void main() {
  test('loads documents from the repository', () async {
    final repo = InMemoryDocumentRepository([
      makeDocument(id: '1'),
      makeDocument(id: '2'),
    ]);
    final container = _containerWith(repo);
    addTearDown(container.dispose);

    final docs = await container.read(documentsControllerProvider.future);
    expect(docs.length, 2);
  });

  test('delete removes a document', () async {
    final repo = InMemoryDocumentRepository([
      makeDocument(id: '1'),
      makeDocument(id: '2'),
    ]);
    final container = _containerWith(repo);
    addTearDown(container.dispose);

    await container.read(documentsControllerProvider.future);
    await container.read(documentsControllerProvider.notifier).delete('1');

    final docs = await container.read(documentsControllerProvider.future);
    expect(docs.map((d) => d.id), ['2']);
  });

  test('rename updates the title', () async {
    final repo = InMemoryDocumentRepository([
      makeDocument(id: '1', title: 'Old'),
    ]);
    final container = _containerWith(repo);
    addTearDown(container.dispose);

    await container.read(documentsControllerProvider.future);
    await container
        .read(documentsControllerProvider.notifier)
        .rename('1', 'New title');

    final docs = await container.read(documentsControllerProvider.future);
    expect(docs.single.title, 'New title');
  });
}
