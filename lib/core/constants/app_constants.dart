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

  /// Staged PDF written during regeneration; renamed over [pdfFileName] on success.
  static const String pdfTempFileName = 'export.new.pdf';

  // Prefix for the user-facing/share PDF filename: SmartScan_yyyyMMdd_HHmmss.pdf
  static const String pdfFilePrefix = 'SmartScan';

  // Per-page image file names. Originals are stable; the processed image is
  // versioned (`{pageId}.{version}.jpg`) so that whenever a page is reprocessed
  // its path changes and Flutter's path-keyed image cache reloads the new bytes.
  static String originalImageName(String pageId) => '$pageId.orig.jpg';
  static String processedImageName(String pageId, String version) =>
      '$pageId.$version.jpg';
  static String processedImageTempName(String pageId) => '$pageId.new.jpg';

  // Persistence schema versions. Bump these when the stored map shape changes
  // and add a migration step in `schema_migration.dart`.
  static const int documentSchemaVersion = 2;
  static const int settingsSchemaVersion = 2;

  static const String settingsKey = 'app_settings';
}
