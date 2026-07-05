import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:smartscanocr/features/documents/data/repositories/hive_document_repository.dart';

import 'support/factories.dart';
import 'support/fakes.dart';

void main() {
  late Box<dynamic> box;
  late FakeFileStorageService storage;
  late HiveDocumentRepository repository;
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('hive_docs_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox<dynamic>('documents');
    storage = FakeFileStorageService();
    repository = HiveDocumentRepository(box, storage);
  });

  tearDown(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  test('saves and reads back a document', () async {
    await repository.saveDocument(
      makeDocument(id: '1', title: 'Hello', text: 'world'),
    );
    final loaded = await repository.getById('1');
    expect(loaded?.title, 'Hello');
    expect(loaded?.combinedText, 'world');
  });

  test('lists documents sorted by updatedAt descending', () async {
    await repository.saveDocument(
      makeDocument(id: 'a', createdAt: DateTime(2026, 1, 1)),
    );
    await repository.saveDocument(
      makeDocument(id: 'b', createdAt: DateTime(2026, 3, 1)),
    );
    final docs = await repository.getDocuments();
    expect(docs.first.id, 'b');
  });

  test('delete removes the entry and requests file cleanup', () async {
    await repository.saveDocument(makeDocument(id: 'x'));
    await repository.deleteDocument('x');
    expect(await repository.getById('x'), isNull);
    expect(storage.deletedDirs, contains('x'));
  });

  test('search matches title and recognized text', () async {
    await repository.saveDocument(
      makeDocument(id: '1', title: 'Invoice', text: ''),
    );
    await repository.saveDocument(
      makeDocument(id: '2', title: 'Notes', text: 'the invoice total'),
    );
    final results = await repository.searchDocuments('invoice');
    expect(results.map((d) => d.id).toSet(), {'1', '2'});
  });
}
