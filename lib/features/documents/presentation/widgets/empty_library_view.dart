import 'package:flutter/material.dart';

/// Friendly empty state shown when the library has no documents.
class EmptyLibraryView extends StatelessWidget {
  const EmptyLibraryView({
    super.key,
    required this.onScan,
    required this.onImport,
  });

  final VoidCallback onScan;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.document_scanner_outlined,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No documents yet',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Scan a document or import images to get started. '
              'Everything is processed on your device and saved locally.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: onScan,
                  icon: const Icon(Icons.document_scanner),
                  label: const Text('Scan document'),
                ),
                OutlinedButton.icon(
                  onPressed: onImport,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Import images'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
