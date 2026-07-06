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

/// Builds the user-facing shared/exported PDF filename from the document title.
///
/// Sanitizes illegal characters, turns spaces into underscores, collapses
/// repeated underscores, and ensures a single `.pdf`. Falls back to the
/// timestamped `SmartScan_yyyyMMdd_HHmmss.pdf` when the title is empty.
String buildShareFileName(String title, DateTime createdAt) {
  final base = sanitizeTitle(title)
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  if (base.isEmpty) return buildPdfFileName(createdAt);
  return '$base.pdf';
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
