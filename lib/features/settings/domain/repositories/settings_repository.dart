import 'package:smartscanocr/features/settings/domain/entities/app_settings.dart';

/// Loads and persists [AppSettings] locally.
abstract class SettingsRepository {
  AppSettings load();
  Future<void> save(AppSettings settings);
}
