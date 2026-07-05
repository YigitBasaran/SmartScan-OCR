import 'package:hive_ce/hive_ce.dart';
import 'package:smartscanocr/core/constants/app_constants.dart';
import 'package:smartscanocr/features/settings/data/mappers/app_settings_mapper.dart';
import 'package:smartscanocr/features/settings/domain/entities/app_settings.dart';
import 'package:smartscanocr/features/settings/domain/repositories/settings_repository.dart';

/// [SettingsRepository] backed by a Hive box holding a single settings map.
class HiveSettingsRepository implements SettingsRepository {
  HiveSettingsRepository(this._box);

  final Box<dynamic> _box;

  @override
  AppSettings load() {
    final raw = _box.get(AppConstants.settingsKey);
    if (raw == null) return const AppSettings();
    return settingsFromMap(raw);
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _box.put(AppConstants.settingsKey, settingsToMap(settings));
  }
}
