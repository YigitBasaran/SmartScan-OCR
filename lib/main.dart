import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:smartscanocr/app/app.dart';
import 'package:smartscanocr/core/constants/app_constants.dart';
import 'package:smartscanocr/core/providers/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Offline-first: open local Hive boxes before the app runs. Documents are
  // stored locally on-device by default; no backend is involved.
  await Hive.initFlutter();
  final documentsBox = await Hive.openBox<dynamic>(
    AppConstants.documentsBoxName,
  );
  final settingsBox = await Hive.openBox<dynamic>(AppConstants.settingsBoxName);

  runApp(
    ProviderScope(
      overrides: [
        documentsBoxProvider.overrideWithValue(documentsBox),
        settingsBoxProvider.overrideWithValue(settingsBox),
      ],
      child: const SmartScanApp(),
    ),
  );
}
