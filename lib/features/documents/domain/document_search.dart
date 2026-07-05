import 'package:smartscanocr/features/documents/domain/entities/scanned_document.dart';

/// Case-insensitive substring search over document title + recognized text.
///
/// Pure function so it can be unit-tested and reused by the repository and the
/// reactive `filteredDocumentsProvider`.
List<ScannedDocument> filterDocuments(
  List<ScannedDocument> docs,
  String query,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return List.of(docs);
  return docs
      .where(
        (d) =>
            d.title.toLowerCase().contains(q) ||
            d.combinedText.toLowerCase().contains(q),
      )
      .toList();
}
