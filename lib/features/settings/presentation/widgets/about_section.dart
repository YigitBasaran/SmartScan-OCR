import 'package:flutter/material.dart';
import 'package:smartscanocr/core/constants/app_constants.dart';

/// About section: app info + precise privacy/behaviour notes.
class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  static const List<String> _notes = [
    'Text recognition (OCR) runs entirely on your device.',
    'No cloud OCR API is used.',
    'Documents are stored locally on this device by default.',
    'The Android scanner and OCR may require Google Play Services.',
    'iOS is structurally supported but was not built or tested on Windows.',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ListTile(
          leading: Icon(Icons.document_scanner_outlined),
          title: Text(AppConstants.appName),
          subtitle: Text('Version 1.0.0 · Offline-first document scanner'),
        ),
        for (final note in _notes)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 3, right: 8),
                  child: Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Expanded(child: Text(note, style: theme.textTheme.bodyMedium)),
              ],
            ),
          ),
      ],
    );
  }
}
