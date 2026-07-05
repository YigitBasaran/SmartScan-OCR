import 'package:smartscanocr/features/documents/domain/entities/scanned_document.dart';

/// Persists and queries saved documents.
abstract class DocumentRepository {
  Future<List<ScannedDocument>> getDocuments();
  Future<ScannedDocument?> getById(String id);
  Future<void> saveDocument(ScannedDocument document);

  /// Deletes the document metadata and its on-disk files.
  Future<void> deleteDocument(String id);

  /// Searches by title and recognized text (case-insensitive substring).
  Future<List<ScannedDocument>> searchDocuments(String query);
}
