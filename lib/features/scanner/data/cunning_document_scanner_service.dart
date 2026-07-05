import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smartscanocr/core/errors/app_exception.dart';
import 'package:smartscanocr/features/scanner/domain/services/document_scanner_service.dart';

/// Primary [DocumentScannerService] backed by `cunning_document_scanner`
/// (native ML Kit scanner on Android, VisionKit on iOS) for scanning, and
/// `image_picker` for the first-class image-import path.
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
        asPdf: false, // return image paths, not the scanner's own PDF
      );
      if (paths == null) throw const ScanCancelled();
      if (paths.isEmpty) throw const NoPagesSelected();
      return paths;
    } on AppException {
      rethrow;
    } on MissingPluginException catch (e) {
      throw ScannerUnavailable(e);
    } catch (e) {
      // PlatformException (no Play Services / camera) or the plugin's own
      // permission exception all mean "can't scan right now".
      throw ScannerUnavailable(e);
    }
  }

  @override
  Future<List<String>> importImages() async {
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
