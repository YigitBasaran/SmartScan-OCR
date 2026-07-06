import 'package:flutter/material.dart' show ThemeMode;
import 'package:smartscanocr/features/pdf_export/domain/entities/pdf_quality.dart';

/// User-configurable settings, persisted locally.
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.pdfQuality = PdfQuality.balanced,
    this.autoPerspectiveCorrection = true,
  });

  final ThemeMode themeMode;
  final PdfQuality pdfQuality;

  /// Best-effort automatic crop/perspective correction for imports and scans.
  final bool autoPerspectiveCorrection;

  AppSettings copyWith({
    ThemeMode? themeMode,
    PdfQuality? pdfQuality,
    bool? autoPerspectiveCorrection,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    pdfQuality: pdfQuality ?? this.pdfQuality,
    autoPerspectiveCorrection:
        autoPerspectiveCorrection ?? this.autoPerspectiveCorrection,
  );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.themeMode == themeMode &&
      other.pdfQuality == pdfQuality &&
      other.autoPerspectiveCorrection == autoPerspectiveCorrection;

  @override
  int get hashCode =>
      Object.hash(themeMode, pdfQuality, autoPerspectiveCorrection);
}
