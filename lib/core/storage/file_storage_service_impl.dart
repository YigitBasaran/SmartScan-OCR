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

  Future<Directory> _pagesDir(String documentId) async {
    final docDir = await _documentDir(documentId);
    final dir = Directory(p.join(docDir.path, AppConstants.pagesDirName));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> _pagePath(String documentId, String fileName) async {
    final pagesDir = await _pagesDir(documentId);
    return p.join(pagesDir.path, fileName);
  }

  @override
  Future<String> saveOriginalFromPath(
    String documentId,
    String pageId,
    String sourcePath,
  ) async {
    try {
      final dest = await _pagePath(
        documentId,
        AppConstants.originalImageName(pageId),
      );
      // Originals are immutable: only copy if absent and not already in place.
      if (!File(dest).existsSync() && sourcePath != dest) {
        await File(sourcePath).copy(dest);
      }
      return dest;
    } catch (e) {
      throw FileWriteFailure(e);
    }
  }

  @override
  Future<String> originalImagePath(String documentId, String pageId) =>
      _pagePath(documentId, AppConstants.originalImageName(pageId));

  @override
  Future<String> stageProcessedImage(
    String documentId,
    String pageId,
    List<int> bytes,
  ) async {
    try {
      final path = await _pagePath(
        documentId,
        AppConstants.processedImageTempName(pageId),
      );
      await File(path).writeAsBytes(bytes, flush: true);
      return path;
    } catch (e) {
      throw FileWriteFailure(e);
    }
  }

  @override
  Future<String> commitProcessedImage(
    String documentId,
    String pageId,
    String version,
  ) async {
    try {
      final tempPath = await _pagePath(
        documentId,
        AppConstants.processedImageTempName(pageId),
      );
      final finalPath = await _pagePath(
        documentId,
        AppConstants.processedImageName(pageId, version),
      );
      await File(tempPath).rename(finalPath); // atomic on same volume
      return finalPath;
    } catch (e) {
      throw FileWriteFailure(e);
    }
  }

  @override
  Future<void> discardStagedImage(String documentId, String pageId) async {
    try {
      final path = await _pagePath(
        documentId,
        AppConstants.processedImageTempName(pageId),
      );
      final file = File(path);
      if (file.existsSync()) await file.delete();
    } catch (_) {
      // Best-effort rollback.
    }
  }

  @override
  Future<String> stagePdf(String documentId, List<int> bytes) async {
    try {
      final docDir = await _documentDir(documentId);
      final path = p.join(docDir.path, AppConstants.pdfTempFileName);
      await File(path).writeAsBytes(bytes, flush: true);
      return path;
    } catch (e) {
      throw FileWriteFailure(e);
    }
  }

  @override
  Future<String> commitPdf(String documentId) async {
    try {
      final docDir = await _documentDir(documentId);
      final tempPath = p.join(docDir.path, AppConstants.pdfTempFileName);
      final finalPath = p.join(docDir.path, AppConstants.pdfFileName);
      await File(tempPath).rename(finalPath);
      return finalPath;
    } catch (e) {
      throw FileWriteFailure(e);
    }
  }

  @override
  Future<void> discardStagedPdf(String documentId) async {
    try {
      final docDir = await _documentDir(documentId);
      final file = File(p.join(docDir.path, AppConstants.pdfTempFileName));
      if (file.existsSync()) await file.delete();
    } catch (_) {
      // Best-effort rollback.
    }
  }

  @override
  Future<String> pdfFilePath(String documentId) async {
    final docDir = await _documentDir(documentId);
    return p.join(docDir.path, AppConstants.pdfFileName);
  }

  @override
  Future<String> stagePdfForShare(String documentId, String fileName) async {
    try {
      final source = File(await pdfFilePath(documentId));
      final tempDir = await getTemporaryDirectory();
      final dest = p.join(tempDir.path, fileName);
      await source.copy(dest);
      return dest;
    } catch (e) {
      throw ShareFailure(e);
    }
  }

  @override
  Future<String> writeTempShareFile(String fileName, List<int> bytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final dest = p.join(tempDir.path, fileName);
      await File(dest).writeAsBytes(bytes, flush: true);
      return dest;
    } catch (e) {
      throw ShareFailure(e);
    }
  }

  @override
  Future<void> deleteFileAt(String path) async {
    try {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    } catch (_) {
      // Best-effort.
    }
  }

  @override
  Future<void> deletePageFiles(String documentId, String pageId) async {
    try {
      final pagesDir = await _pagesDir(documentId);
      if (!pagesDir.existsSync()) return;
      final prefix = '$pageId.';
      await for (final entity in pagesDir.list()) {
        if (entity is File && p.basename(entity.path).startsWith(prefix)) {
          try {
            await entity.delete();
          } catch (_) {
            // Best-effort per file.
          }
        }
      }
    } catch (_) {
      // Best-effort.
    }
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
