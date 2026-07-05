import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartscanocr/features/pdf_export/domain/entities/pdf_quality.dart';
import 'package:smartscanocr/features/settings/presentation/controllers/settings_controller.dart';

/// Lets the user pick the default PDF export quality.
class PdfQualitySelector extends ConsumerWidget {
  const PdfQualitySelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      settingsControllerProvider.select((s) => s.pdfQuality),
    );
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        for (final quality in PdfQuality.values)
          ListTile(
            title: Text(quality.label),
            subtitle: Text(quality.description),
            trailing: selected == quality
                ? Icon(Icons.check_circle, color: scheme.primary)
                : const Icon(Icons.circle_outlined),
            onTap: () => ref
                .read(settingsControllerProvider.notifier)
                .setPdfQuality(quality),
          ),
      ],
    );
  }
}
