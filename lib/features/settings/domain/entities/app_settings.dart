import 'package:flutter/material.dart' show ThemeMode;
import 'package:smartscanocr/features/pdf_export/domain/entities/pdf_quality.dart';

/// User-configurable settings, persisted locally.
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.pdfQuality = PdfQuality.balanced,
  });

  final ThemeMode themeMode;
  final PdfQuality pdfQuality;

  AppSettings copyWith({ThemeMode? themeMode, PdfQuality? pdfQuality}) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        pdfQuality: pdfQuality ?? this.pdfQuality,
      );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.themeMode == themeMode &&
      other.pdfQuality == pdfQuality;

  @override
  int get hashCode => Object.hash(themeMode, pdfQuality);
}
