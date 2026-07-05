import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartscanocr/core/providers/service_providers.dart';
import 'package:smartscanocr/features/pdf_export/domain/entities/pdf_quality.dart';
import 'package:smartscanocr/features/settings/domain/entities/app_settings.dart';

/// Exposes and persists [AppSettings].
class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(settingsRepositoryProvider).load();

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await ref.read(settingsRepositoryProvider).save(state);
  }

  Future<void> setPdfQuality(PdfQuality quality) async {
    state = state.copyWith(pdfQuality: quality);
    await ref.read(settingsRepositoryProvider).save(state);
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
