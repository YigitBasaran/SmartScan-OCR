import 'package:flutter_test/flutter_test.dart';
import 'package:smartscanocr/features/documents/domain/document_search.dart';

import 'support/factories.dart';

void main() {
  final docs = [
    makeDocument(id: '1', title: 'Invoice March', text: 'total amount due'),
    makeDocument(id: '2', title: 'Recipe', text: 'the invoice of ingredients'),
    makeDocument(id: '3', title: 'Notes', text: 'unrelated content'),
  ];

  group('filterDocuments', () {
    test('empty query returns all documents', () {
      expect(filterDocuments(docs, '').length, 3);
      expect(filterDocuments(docs, '   ').length, 3);
    });

    test('matches the title case-insensitively', () {
      final result = filterDocuments(docs, 'INVOICE');
      expect(result.map((d) => d.id), containsAll(['1', '2']));
    });

    test('matches the recognized text', () {
      final result = filterDocuments(docs, 'ingredients');
      expect(result.map((d) => d.id), ['2']);
    });

    test('matches partial words (substring)', () {
      // "voice" should match "Invoice".
      final result = filterDocuments(docs, 'voice');
      expect(result.map((d) => d.id).toSet(), {'1', '2'});
    });

    test('returns empty when nothing matches', () {
      expect(filterDocuments(docs, 'zzzzz'), isEmpty);
    });
  });
}
