import 'package:smartscanocr/core/constants/app_constants.dart';

/// Upgrades a stored document map to the current schema shape.
///
/// v1 → v2 added non-destructive page editing fields (`originalImagePath`,
/// `processedImagePath`, `cropCorners`, `filterMode`). Page-level field
/// fallbacks are handled defensively in `pageFromMap` (old `imagePath` →
/// `originalImagePath`), so this only needs to stamp the current version.
Map<String, dynamic> migrateDocumentMap(Map<String, dynamic> map) {
  final version = (map['schemaVersion'] as num?)?.toInt() ?? 1;
  var result = map;
  // Future document migrations chain here based on `version`.
  if (version != AppConstants.documentSchemaVersion) {
    result = {...result, 'schemaVersion': AppConstants.documentSchemaVersion};
  }
  return result;
}

/// Upgrades a stored settings map to the current schema shape.
///
/// v1 → v2 added `autoPerspectiveCorrection` (default enabled).
Map<String, dynamic> migrateSettingsMap(Map<String, dynamic> map) {
  final version = (map['schemaVersion'] as num?)?.toInt() ?? 1;
  var result = map;
  if (version < 2 && !result.containsKey('autoPerspectiveCorrection')) {
    result = {...result, 'autoPerspectiveCorrection': true};
  }
  if (result['schemaVersion'] != AppConstants.settingsSchemaVersion) {
    result = {...result, 'schemaVersion': AppConstants.settingsSchemaVersion};
  }
  return result;
}
