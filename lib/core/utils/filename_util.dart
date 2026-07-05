import 'package:intl/intl.dart';
import 'package:smartscanocr/core/constants/app_constants.dart';

/// Builds the share/export PDF filename: `SmartScan_yyyyMMdd_HHmmss.pdf`.
///
/// The on-disk file is always `export.pdf`; this friendlier, timestamped name
/// is applied when the user shares/exports the document.
String buildPdfFileName(DateTime date) {
  final stamp = DateFormat('yyyyMMdd_HHmmss').format(date);
  return '${AppConstants.pdfFilePrefix}_$stamp.pdf';
}

/// A friendly default document title, e.g. `Scan 2026-07-04 15:30`.
String buildDefaultDocumentTitle(DateTime date) {
  final stamp = DateFormat('yyyy-MM-dd HH:mm').format(date);
  return 'Scan $stamp';
}

/// Removes characters that are illegal in filenames and collapses whitespace.
///
/// Used so a user-provided title can safely appear in a shared filename.
String sanitizeTitle(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return trimmed;
  return trimmed
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
