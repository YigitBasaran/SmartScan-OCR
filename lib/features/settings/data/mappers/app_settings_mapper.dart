import 'package:flutter/material.dart' show ThemeMode;
import 'package:smartscanocr/core/constants/app_constants.dart';
import 'package:smartscanocr/core/utils/map_cast.dart';
import 'package:smartscanocr/core/utils/schema_migration.dart';
import 'package:smartscanocr/features/pdf_export/domain/entities/pdf_quality.dart';
import 'package:smartscanocr/features/settings/domain/entities/app_settings.dart';

ThemeMode parseThemeMode(String? name) => ThemeMode.values.firstWhere(
  (m) => m.name == name,
  orElse: () => ThemeMode.system,
);

Map<String, dynamic> settingsToMap(AppSettings settings) => {
  'schemaVersion': AppConstants.settingsSchemaVersion,
  'themeMode': settings.themeMode.name,
  'pdfQuality': settings.pdfQuality.name,
  'autoPerspectiveCorrection': settings.autoPerspectiveCorrection,
};

AppSettings settingsFromMap(Object? raw) {
  final map = migrateSettingsMap(asStringKeyedMap(raw));
  return AppSettings(
    themeMode: parseThemeMode(map['themeMode'] as String?),
    pdfQuality: parsePdfQuality(map['pdfQuality'] as String?),
    autoPerspectiveCorrection:
        (map['autoPerspectiveCorrection'] as bool?) ?? true,
  );
}
