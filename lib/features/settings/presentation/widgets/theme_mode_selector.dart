import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartscanocr/features/settings/presentation/controllers/settings_controller.dart';

/// Segmented control for choosing the app theme mode.
class ThemeModeSelector extends ConsumerWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(
      settingsControllerProvider.select((s) => s.themeMode),
    );
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(value: ThemeMode.system, label: Text('System')),
          ButtonSegment(value: ThemeMode.light, label: Text('Light')),
          ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
        ],
        selected: {mode},
        showSelectedIcon: false,
        onSelectionChanged: (selection) => ref
            .read(settingsControllerProvider.notifier)
            .setThemeMode(selection.first),
      ),
    );
  }
}
