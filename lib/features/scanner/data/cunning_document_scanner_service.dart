import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smartscanocr/core/errors/app_exception.dart';
import 'package:smartscanocr/features/scanner/domain/services/document_scanner_service.dart';

/// Primary [DocumentScannerService] backed by `cunning_document_scanner`
/// (native ML Kit scanner on Android, VisionKit on iOS) for scanning, and
/// `image_picker` for the offline image-import fallback.
///
/// The scanner is always asked for images (`asPdf: false`); the app builds its
/// own PDF from the reviewed pages. To add `google_mlkit_document_scanner` as an
/// Android fallback later, create another class implementing
/// [DocumentScannerService] and swap the provider — no UI/controller changes.
class CunningDocumentScannerService implements DocumentScannerService {
  CunningDocumentScannerService({ImagePicker? imagePicker})
    : _picker = imagePicker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<List<String>> scanDocuments({int maxPages = 30}) async {
    try {
      final paths = await CunningDocumentScanner.getPictures(
        noOfPages: maxPages,
        androidScannerMode: AndroidScannerMode.full, // richest ML Kit mode
        asPdf: false, // return image paths, not the scanner's own PDF
      );
      if (paths == null) throw const ScanCancelled();
      if (paths.isEmpty) throw const NoPagesSelected();
      return paths;
    } on AppException {
      rethrow;
    } catch (e) {
      // PlatformException/MissingPlugin (no Play Services / camera) → can't scan.
      throw ScannerUnavailable(e);
    }
  }

  @override
  Future<List<String>> importImages({bool autoCorrect = true}) async {
    // Best-effort: route the import through ML Kit's in-scanner gallery flow so
    // imported photos get the same edge-detection / crop / perspective
    // correction as camera scans. Requires Google Play Services.
    if (autoCorrect) {
      try {
        final paths = await CunningDocumentScanner.getPictures(
          scannerSource: ScannerSource.gallery,
          androidScannerMode: AndroidScannerMode.full,
          asPdf: false,
        );
        if (paths == null) throw const ScanCancelled(); // user cancelled
        if (paths.isEmpty) throw const NoPagesSelected();
        return paths;
      } on AppException {
        rethrow; // cancel / no-pages are intentional; don't fall back
      } catch (_) {
        // ML Kit gallery unavailable (no Play Services / plugin error) —
        // fall through to the raw picker below.
      }
    }

    // Raw fallback: works offline and without Play Services (no correction).
    try {
      final files = await _picker.pickMultiImage();
      if (files.isEmpty) throw const ScanCancelled();
      return [for (final file in files) file.path];
    } on AppException {
      rethrow;
    } catch (e) {
      throw ScannerUnavailable(e);
    }
  }
}
