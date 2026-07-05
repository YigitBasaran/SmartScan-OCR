import 'package:smartscanocr/core/constants/app_constants.dart';

/// Upgrades a stored document map to the current schema shape.
///
/// Version 1 is the current baseline. When the persisted shape changes, bump
/// [AppConstants.documentSchemaVersion] and add a migration step here, e.g.:
///
/// ```dart
/// if (version < 2) {
///   map = _migrateDocumentV1toV2(map);
/// }
/// ```
Map<String, dynamic> migrateDocumentMap(Map<String, dynamic> map) {
  final version = (map['schemaVersion'] as num?)?.toInt() ?? 1;
  var result = map;
  // Future migrations chain here based on `version`.
  if (version != AppConstants.documentSchemaVersion) {
    result = {...result, 'schemaVersion': AppConstants.documentSchemaVersion};
  }
  return result;
}

/// Upgrades a stored settings map to the current schema shape.
Map<String, dynamic> migrateSettingsMap(Map<String, dynamic> map) {
  final version = (map['schemaVersion'] as num?)?.toInt() ?? 1;
  var result = map;
  if (version != AppConstants.settingsSchemaVersion) {
    result = {...result, 'schemaVersion': AppConstants.settingsSchemaVersion};
  }
  return result;
}
