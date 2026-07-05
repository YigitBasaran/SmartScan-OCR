/// App-wide constant values: names, directories and schema versions.
///
/// Keeping these in one place makes storage layout and persistence versioning
/// explicit and easy to evolve.
class AppConstants {
  const AppConstants._();

  static const String appName = 'SmartScan OCR';

  // Hive box names.
  static const String documentsBoxName = 'documents';
  static const String settingsBoxName = 'settings';

  // On-disk storage layout under the app documents directory.
  static const String documentsDirName = 'documents';
  static const String pagesDirName = 'pages';
  static const String pdfFileName = 'export.pdf';

  // Prefix for the user-facing/share PDF filename: SmartScan_yyyyMMdd_HHmmss.pdf
  static const String pdfFilePrefix = 'SmartScan';

  // Persistence schema versions. Bump these when the stored map shape changes
  // and add a migration step in `schema_migration.dart`.
  static const int documentSchemaVersion = 1;
  static const int settingsSchemaVersion = 1;

  static const String settingsKey = 'app_settings';
}
