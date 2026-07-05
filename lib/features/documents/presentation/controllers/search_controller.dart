import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartscanocr/features/documents/domain/document_search.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_document.dart';
import 'package:smartscanocr/features/documents/presentation/controllers/documents_controller.dart';

/// Holds the current library search query.
class SearchQueryController extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;
  void clear() => state = '';
}

final searchQueryProvider = NotifierProvider<SearchQueryController, String>(
  SearchQueryController.new,
);

/// The documents list filtered by the current query (reactive, derived).
final filteredDocumentsProvider = Provider<AsyncValue<List<ScannedDocument>>>((
  ref,
) {
  final query = ref.watch(searchQueryProvider);
  final docsAsync = ref.watch(documentsControllerProvider);
  return docsAsync.whenData((docs) => filterDocuments(docs, query));
});
