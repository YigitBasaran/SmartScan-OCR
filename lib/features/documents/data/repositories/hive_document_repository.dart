import 'package:hive_ce/hive_ce.dart';
import 'package:smartscanocr/core/errors/app_exception.dart';
import 'package:smartscanocr/core/storage/file_storage_service.dart';
import 'package:smartscanocr/features/documents/data/mappers/scanned_document_mapper.dart';
import 'package:smartscanocr/features/documents/domain/document_search.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_document.dart';
import 'package:smartscanocr/features/documents/domain/repositories/document_repository.dart';

/// [DocumentRepository] backed by a Hive box (metadata) + [FileStorageService]
/// (page images + PDF). Documents are stored as JSON-compatible maps.
class HiveDocumentRepository implements DocumentRepository {
  HiveDocumentRepository(this._box, this._storage);

  final Box<dynamic> _box;
  final FileStorageService _storage;

  @override
  Future<List<ScannedDocument>> getDocuments() async {
    try {
      final docs = _box.values.map(documentFromMap).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return docs;
    } catch (e) {
      throw StorageFailure(e);
    }
  }

  @override
  Future<ScannedDocument?> getById(String id) async {
    try {
      final raw = _box.get(id);
      return raw == null ? null : documentFromMap(raw);
    } catch (e) {
      throw StorageFailure(e);
    }
  }

  @override
  Future<void> saveDocument(ScannedDocument document) async {
    try {
      await _box.put(document.id, documentToMap(document));
    } catch (e) {
      throw StorageFailure(e);
    }
  }

  @override
  Future<void> deleteDocument(String id) async {
    try {
      // Delete the metadata first (source of truth), then the files.
      await _box.delete(id);
    } catch (e) {
      throw StorageFailure(e);
    }
    await _storage.deleteDocumentDir(id);
  }

  @override
  Future<List<ScannedDocument>> searchDocuments(String query) async {
    final all = await getDocuments();
    return filterDocuments(all, query);
  }
}
