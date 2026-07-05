import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartscanocr/app/router.dart';
import 'package:smartscanocr/app/theme.dart';
import 'package:smartscanocr/core/constants/app_constants.dart';
import 'package:smartscanocr/features/settings/presentation/controllers/settings_controller.dart';

/// Root widget: wires theme, theme mode (from settings) and the router.
class SmartScanApp extends ConsumerWidget {
  const SmartScanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(
      settingsControllerProvider.select((s) => s.themeMode),
    );
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
