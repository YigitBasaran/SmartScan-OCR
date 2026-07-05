import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartscanocr/core/providers/app_providers.dart';
import 'package:smartscanocr/core/providers/service_providers.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_document.dart';

/// Loads and mutates the saved-documents list.
class DocumentsController extends AsyncNotifier<List<ScannedDocument>> {
  @override
  Future<List<ScannedDocument>> build() async {
    final repo = ref.watch(documentRepositoryProvider);
    final docs = await repo.getDocuments();
    // One-time orphan cleanup: remove document folders with no metadata entry.
    await ref
        .read(fileStorageServiceProvider)
        .sweepOrphans(docs.map((d) => d.id).toSet());
    return docs;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(documentRepositoryProvider).getDocuments(),
    );
  }

  Future<void> delete(String id) async {
    try {
      await ref.read(documentRepositoryProvider).deleteDocument(id);
    } finally {
      await refresh();
    }
  }

  Future<void> rename(String id, String title) async {
    final repo = ref.read(documentRepositoryProvider);
    final doc = await repo.getById(id);
    if (doc == null) return;
    final now = ref.read(clockProvider)();
    await repo.saveDocument(doc.copyWith(title: title, updatedAt: now));
    await refresh();
  }
}

final documentsControllerProvider =
    AsyncNotifierProvider<DocumentsController, List<ScannedDocument>>(
      DocumentsController.new,
    );
