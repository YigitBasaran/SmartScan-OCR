/// Manages on-disk storage for documents under the app documents directory:
///
/// ```text
/// /documents/{documentId}/pages/{pageId}.orig.jpg   # immutable original
/// /documents/{documentId}/pages/{pageId}.jpg        # processed (regenerated)
/// /documents/{documentId}/export.pdf
/// ```
///
/// Edits are non-destructive and transaction-like: reprocessed pages and the
/// regenerated PDF are written to staged temp files first and only renamed over
/// the live files once the whole operation succeeds (rename is atomic on the
/// same volume), so a failed regeneration never corrupts the previous document.
abstract class FileStorageService {
  /// Copies [sourcePath] into storage as the immutable original if it does not
  /// already exist; returns the stored path. Originals are never overwritten.
  Future<String> saveOriginalFromPath(
    String documentId,
    String pageId,
    String sourcePath,
  );

  /// Absolute path of the committed original image for a page.
  Future<String> originalImagePath(String documentId, String pageId);

  /// Stages a processed image to a temp file (`{pageId}.new.jpg`); returns the
  /// temp path. Commit later with [commitProcessedImage].
  Future<String> stageProcessedImage(
    String documentId,
    String pageId,
    List<int> bytes,
  );

  /// Commits a staged processed image (temp → `{pageId}.{version}.jpg`); returns
  /// the versioned final path. A new [version] each reprocess makes the path
  /// change so the UI reloads the image.
  Future<String> commitProcessedImage(
    String documentId,
    String pageId,
    String version,
  );

  /// Deletes a staged processed temp file (rollback); best-effort.
  Future<void> discardStagedImage(String documentId, String pageId);

  /// Stages the regenerated PDF to `export.new.pdf`; returns the temp path.
  Future<String> stagePdf(String documentId, List<int> bytes);

  /// Commits the staged PDF (`export.new.pdf` → `export.pdf`); returns the final
  /// path.
  Future<String> commitPdf(String documentId);

  /// Deletes the staged PDF temp (rollback); best-effort.
  Future<void> discardStagedPdf(String documentId);

  /// Absolute path where the committed PDF lives.
  Future<String> pdfFilePath(String documentId);

  /// Copies `export.pdf` into the temp directory as [fileName] and returns that
  /// path, so the share sheet shows a title-based filename (not `export.pdf`).
  Future<String> stagePdfForShare(String documentId, String fileName);

  /// Writes arbitrary PDF [bytes] into the temp directory as [fileName] and
  /// returns that path (used for the watermark-free export share).
  Future<String> writeTempShareFile(String fileName, List<int> bytes);

  /// Deletes a single file if it exists (best-effort). Used to drop a page's
  /// previous processed image version after a new one is committed.
  Future<void> deleteFileAt(String path);

  /// Removes every `{pageId}.*` file for a page (original + all processed
  /// versions + staging).
  Future<void> deletePageFiles(String documentId, String pageId);

  /// Best-effort removal of the whole `/documents/{documentId}` folder.
  Future<void> deleteDocumentDir(String documentId);

  /// Removes document folders whose id is not in [knownIds] (orphan cleanup).
  Future<void> sweepOrphans(Set<String> knownIds);
}
