import 'package:flutter/material.dart';
import 'package:smartscanocr/features/settings/presentation/widgets/about_section.dart';
import 'package:smartscanocr/features/settings/presentation/widgets/auto_correction_toggle.dart';
import 'package:smartscanocr/features/settings/presentation/widgets/pdf_quality_selector.dart';
import 'package:smartscanocr/features/settings/presentation/widgets/theme_mode_selector.dart';

/// Settings: theme, default PDF quality, OCR note and about.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: const [
          _SectionHeader('Appearance'),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ThemeModeSelector(),
          ),
          SizedBox(height: 8),
          _SectionHeader('PDF export'),
          PdfQualitySelector(),
          SizedBox(height: 8),
          _SectionHeader('Scanning'),
          AutoCorrectionToggle(),
          SizedBox(height: 8),
          _SectionHeader('Text recognition'),
          ListTile(
            leading: Icon(Icons.text_fields),
            title: Text('On-device OCR'),
            subtitle: Text(
              'Latin script. Runs on your device; no cloud services are used.',
            ),
          ),
          SizedBox(height: 8),
          _SectionHeader('About'),
          AboutSection(),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
