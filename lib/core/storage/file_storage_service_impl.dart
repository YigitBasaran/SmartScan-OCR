import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:smartscanocr/core/constants/app_constants.dart';
import 'package:smartscanocr/core/errors/app_exception.dart';
import 'package:smartscanocr/core/storage/file_storage_service.dart';

/// Filesystem-backed [FileStorageService] using the app documents directory.
class FileStorageServiceImpl implements FileStorageService {
  Future<Directory> _documentsRoot() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, AppConstants.documentsDirName));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> _documentDir(String documentId) async {
    final root = await _documentsRoot();
    final dir = Directory(p.join(root.path, documentId));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  @override
  Future<String> savePageImage(
    String documentId,
    int index,
    List<int> bytes,
  ) async {
    try {
      final docDir = await _documentDir(documentId);
      final pagesDir = Directory(
        p.join(docDir.path, AppConstants.pagesDirName),
      );
      if (!pagesDir.existsSync()) {
        await pagesDir.create(recursive: true);
      }
      final file = File(p.join(pagesDir.path, 'page_${index + 1}.jpg'));
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (e) {
      throw FileWriteFailure(e);
    }
  }

  @override
  Future<String> writePdf(String documentId, List<int> bytes) async {
    try {
      final docDir = await _documentDir(documentId);
      final file = File(p.join(docDir.path, AppConstants.pdfFileName));
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (e) {
      throw FileWriteFailure(e);
    }
  }

  @override
  Future<String> pdfFilePath(String documentId) async {
    final docDir = await _documentDir(documentId);
    return p.join(docDir.path, AppConstants.pdfFileName);
  }

  @override
  Future<void> deleteDocumentDir(String documentId) async {
    try {
      final root = await _documentsRoot();
      final dir = Directory(p.join(root.path, documentId));
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {
      // Best-effort: a failed file delete should not block removing the entry.
    }
  }

  @override
  Future<void> sweepOrphans(Set<String> knownIds) async {
    try {
      final root = await _documentsRoot();
      if (!root.existsSync()) return;
      await for (final entity in root.list()) {
        if (entity is Directory) {
          final id = p.basename(entity.path);
          if (!knownIds.contains(id)) {
            try {
              await entity.delete(recursive: true);
            } catch (_) {
              // Ignore individual failures.
            }
          }
        }
      }
    } catch (_) {
      // Best-effort cleanup; ignore (e.g. path_provider unavailable in tests).
    }
  }
}
