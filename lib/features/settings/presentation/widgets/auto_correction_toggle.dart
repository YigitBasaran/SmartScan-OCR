import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartscanocr/features/settings/presentation/controllers/settings_controller.dart';

/// Toggles best-effort automatic perspective correction for scans/imports.
class AutoCorrectionToggle extends ConsumerWidget {
  const AutoCorrectionToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(
      settingsControllerProvider.select((s) => s.autoPerspectiveCorrection),
    );
    return SwitchListTile(
      title: const Text('Auto perspective correction'),
      subtitle: const Text(
        'Best-effort automatic crop and perspective for scans and imports. '
        'Requires Google Play Services; results vary — you can also adjust '
        'crop per page.',
      ),
      value: enabled,
      onChanged: (value) => ref
          .read(settingsControllerProvider.notifier)
          .setAutoPerspectiveCorrection(value),
    );
  }
}
