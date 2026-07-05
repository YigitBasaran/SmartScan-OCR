import 'dart:io';

import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smartscanocr/core/errors/app_exception.dart';
import 'package:smartscanocr/core/sharing/sharing_service.dart';

/// [SharingService] backed by `share_plus` (share sheet) and `printing` (print).
class SharingServiceImpl implements SharingService {
  @override
  Future<void> sharePdf({required String path, String? fileName}) async {
    try {
      final params = ShareParams(
        files: [XFile(path, mimeType: 'application/pdf')],
        fileNameOverrides: fileName != null ? [fileName] : null,
        subject: fileName ?? 'SmartScan OCR document',
      );
      await SharePlus.instance.share(params);
    } catch (e) {
      throw ShareFailure(e);
    }
  }

  @override
  Future<void> shareText(String text) async {
    try {
      if (text.trim().isEmpty) throw const ShareFailure();
      await SharePlus.instance.share(ShareParams(text: text));
    } on AppException {
      rethrow;
    } catch (e) {
      throw ShareFailure(e);
    }
  }

  @override
  Future<void> printPdf(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      throw ShareFailure(e);
    }
  }
}
