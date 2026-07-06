import 'package:smartscanocr/core/errors/app_exception.dart';
import 'package:smartscanocr/core/storage/file_storage_service.dart';
import 'package:smartscanocr/core/utils/dev_log.dart';
import 'package:smartscanocr/features/documents/domain/entities/ocr_status.dart';
import 'package:smartscanocr/features/documents/domain/entities/processing_phase.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_document.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_page.dart';
import 'package:smartscanocr/features/documents/domain/ocr_text_formatter.dart';
import 'package:smartscanocr/features/documents/domain/repositories/document_repository.dart';
import 'package:smartscanocr/features/documents/domain/services/document_processing_service.dart';
import 'package:smartscanocr/features/ocr/domain/services/ocr_service.dart';
import 'package:smartscanocr/features/pdf_export/domain/entities/pdf_export_mode.dart';
import 'package:smartscanocr/features/pdf_export/domain/entities/pdf_quality.dart';
import 'package:smartscanocr/features/pdf_export/domain/services/image_processor.dart';
import 'package:smartscanocr/features/pdf_export/domain/services/pdf_export_service.dart';
import 'package:smartscanocr/features/perspective/domain/services/perspective_correction_service.dart';
import 'package:uuid/uuid.dart';

/// Concrete [DocumentProcessingService]. All I/O is delegated to injected
/// services (image/ocr/pdf/storage/repository/correction), so it is fully
/// fakeable.
class DocumentProcessingServiceImpl implements DocumentProcessingService {
  DocumentProcessingServiceImpl({
    required this.imageProcessor,
    required this.ocrService,
    required this.pdfService,
    required this.storage,
    required this.repository,
    required this.correctionService,
    required this.uuid,
  });

  final ImageProcessor imageProcessor;
  final OcrService ocrService;
  final PdfExportService pdfService;
  final FileStorageService storage;
  final DocumentRepository repository;
  final PerspectiveCorrectionService correctionService;
  final Uuid uuid;

  @override
  Future<DocumentBuildResult> buildAndSave({
    required String documentId,
    required String title,
    required DateTime createdAt,
    required DateTime now,
    required List<ScannedPage> pages,
    ScannedDocument? previous,
    required PdfQuality quality,
    ProcessingProgress? onProgress,
  }) async {
    final prevById = {
      for (final p in previous?.pages ?? const <ScannedPage>[]) p.id: p,
    };
    // Assign order from list position.
    final ordered = [
      for (var i = 0; i < pages.length; i++) pages[i].copyWith(order: i),
    ];

    final stagedIds = <String>[];
    final versions =
        <String, String>{}; // pageId -> version for its staged temp
    final committedPaths =
        <String, String>{}; // pageId -> committed versioned path
    final renderPages = <ScannedPage>[];
    final changedIds = <String>{};
    String? warning;

    try {
      // Phase 1: ensure originals + (re)process changed pages to staged temps.
      onProgress?.call(ProcessingPhase.preparing, 0, ordered.length);
      for (var i = 0; i < ordered.length; i++) {
        onProgress?.call(ProcessingPhase.preparing, i + 1, ordered.length);
        final page = ordered[i];
        final originalPath = await storage.saveOriginalFromPath(
          documentId,
          page.id,
          page.originalImagePath,
        );
        final prev = prevById[page.id];
        final needsReprocess =
            prev == null ||
            prev.editSignature != page.editSignature ||
            prev.processedImagePath == null;

        if (needsReprocess) {
          changedIds.add(page.id);
          // Automatic perspective-correction seam (no-op today; an OpenCV /
          // ML-Kit detector drops in here later). Manual crop corners are
          // applied afterwards by the image processor.
          final correction = await correctionService.correct(
            inputPath: originalPath,
          );
          warning ??= correction.warning;
          final processed = await imageProcessor.process(
            correction.outputPath,
            rotationQuarterTurns: page.rotationQuarterTurns,
            cropCorners: page.cropCorners,
            filter: page.filterMode,
            quality: quality,
          );
          warning ??= processed.warning;
          final tempPath = await storage.stageProcessedImage(
            documentId,
            page.id,
            processed.bytes,
          );
          // Unique, filesystem-safe version so the committed path changes on
          // every reprocess (busts Flutter's path-keyed image cache).
          versions[page.id] =
              '${now.microsecondsSinceEpoch}_${uuid.v4().replaceAll('-', '').substring(0, 8)}';
          devLog(
            'page ${page.id}: original=$originalPath -> processed(${processed.width}x${processed.height}) '
            'cropped=${page.cropCorners != null} filter=${page.filterMode.name} '
            'rotation=${page.rotationQuarterTurns} version=${versions[page.id]}'
            '${processed.warning != null ? ' warning=${processed.warning}' : ''}',
          );
          stagedIds.add(page.id);
          renderPages.add(
            page.copyWith(
              originalImagePath: originalPath,
              processedImagePath: tempPath,
            ),
          );
        } else {
          // Reuse the existing versioned processed image (unchanged content →
          // unchanged path, so its cache entry stays valid).
          renderPages.add(page.copyWith(originalImagePath: originalPath));
        }
      }

      // Phase 2: OCR only changed/new pages; preserve the rest. OCR problems
      // degrade gracefully (the PDF is still generated).
      final ocrByPage = <String, String>{};
      for (final page in renderPages) {
        if (!changedIds.contains(page.id)) {
          ocrByPage[page.id] = prevById[page.id]?.ocrText ?? '';
        }
      }
      var ocrHardFailed = false;
      final changedPages = renderPages
          .where((p) => changedIds.contains(p.id))
          .toList();
      if (changedPages.isNotEmpty) {
        onProgress?.call(ProcessingPhase.ocr, 0, changedPages.length);
        try {
          final result = await ocrService.recognizeDocument(
            changedPages,
            onProgress: (done, total) =>
                onProgress?.call(ProcessingPhase.ocr, done, total),
          );
          for (final r in result.pages) {
            ocrByPage[r.pageId] = r.text;
          }
          if (result.status == OcrStatus.failed) ocrHardFailed = true;
        } catch (_) {
          ocrHardFailed = true;
          for (final p in changedPages) {
            ocrByPage[p.id] = '';
          }
        }
      }

      // Phase 3: render the watermarked PDF (from staged temps for changed
      // pages) and stage it to export.new.pdf.
      onProgress?.call(ProcessingPhase.generatingPdf, 0, 0);
      final pdfBytes = await pdfService.renderPdf(
        renderPages,
        mode: PdfExportMode.watermarked,
      );
      await storage.stagePdf(documentId, pdfBytes);

      // Phase 4: commit — rename staged images to their versioned names (new
      // files; never overwriting an old version) and the PDF over export.pdf,
      // then write metadata (the single logical commit point).
      onProgress?.call(ProcessingPhase.saving, 0, 0);
      for (final id in stagedIds) {
        committedPaths[id] = await storage.commitProcessedImage(
          documentId,
          id,
          versions[id]!,
        );
      }
      final pdfPath = await storage.commitPdf(documentId);

      final finalPages = <ScannedPage>[];
      for (final page in renderPages) {
        final processedFinal = changedIds.contains(page.id)
            ? committedPaths[page.id]
            : page.processedImagePath;
        finalPages.add(
          page.copyWith(
            processedImagePath: processedFinal,
            ocrText: ocrByPage[page.id] ?? '',
          ),
        );
      }

      final combinedText = OcrTextFormatter.rebuildCombinedText(finalPages);
      final anyText = finalPages.any((p) => p.hasText);
      final allText =
          finalPages.isNotEmpty && finalPages.every((p) => p.hasText);
      final status = !anyText
          ? OcrStatus.failed
          : (allText ? OcrStatus.done : OcrStatus.partial);

      final document = ScannedDocument(
        id: documentId,
        title: title,
        createdAt: createdAt,
        updatedAt: now,
        pages: finalPages,
        pdfPath: pdfPath,
        combinedText: combinedText,
        ocrStatus: status,
      );
      await repository.saveDocument(document);

      // Only AFTER a successful metadata save: drop each changed page's previous
      // processed version, and remove files of pages deleted in this edit.
      for (final id in changedIds) {
        final prevPath = prevById[id]?.processedImagePath;
        if (prevPath != null && prevPath != committedPaths[id]) {
          await storage.deleteFileAt(prevPath);
        }
      }
      final keptIds = finalPages.map((p) => p.id).toSet();
      for (final prevPage in prevById.values) {
        if (!keptIds.contains(prevPage.id)) {
          await storage.deletePageFiles(documentId, prevPage.id);
        }
      }

      return DocumentBuildResult(
        document: document,
        warning: warning,
        ocrHardFailed: ocrHardFailed,
      );
    } catch (e) {
      // Roll back: discard staged temps and any just-committed (unreferenced)
      // versioned images/PDF. Never touch the previous document's files.
      for (final id in stagedIds) {
        await storage.discardStagedImage(documentId, id);
      }
      for (final path in committedPaths.values) {
        await storage.deleteFileAt(path);
      }
      await storage.discardStagedPdf(documentId);
      if (e is AppException) rethrow;
      throw StorageFailure(e);
    }
  }
}
