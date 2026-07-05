/// Manages on-disk storage for documents under the app documents directory:
///
/// ```text
/// /documents/{documentId}/pages/page_1.jpg
/// /documents/{documentId}/export.pdf
/// ```
abstract class FileStorageService {
  /// Writes a page image (`page_{index+1}.jpg`) and returns its absolute path.
  Future<String> savePageImage(String documentId, int index, List<int> bytes);

  /// Writes the document's `export.pdf` and returns its absolute path.
  Future<String> writePdf(String documentId, List<int> bytes);

  /// The absolute path where the document's PDF would live.
  Future<String> pdfFilePath(String documentId);

  /// Best-effort removal of the whole `/documents/{documentId}` folder.
  Future<void> deleteDocumentDir(String documentId);

  /// Removes document folders whose id is not in [knownIds] (orphan cleanup).
  Future<void> sweepOrphans(Set<String> knownIds);
}
