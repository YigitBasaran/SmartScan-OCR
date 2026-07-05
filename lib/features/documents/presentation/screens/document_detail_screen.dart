import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartscanocr/core/providers/service_providers.dart';
import 'package:smartscanocr/core/utils/filename_util.dart';
import 'package:smartscanocr/core/widgets/app_snack_bar.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_document.dart';
import 'package:smartscanocr/features/documents/presentation/controllers/documents_controller.dart';
import 'package:smartscanocr/features/documents/presentation/widgets/document_card.dart';
import 'package:smartscanocr/features/documents/presentation/widgets/document_page_preview.dart';
import 'package:smartscanocr/features/documents/presentation/widgets/ocr_text_section.dart';

/// Shows a saved document's metadata, previews, OCR text and share/manage actions.
class DocumentDetailScreen extends ConsumerWidget {
  const DocumentDetailScreen({super.key, required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(documentsControllerProvider);
    return docsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Could not load this document.')),
      ),
      data: (docs) {
        final matches = docs.where((d) => d.id == documentId);
        if (matches.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Document')),
            body: const Center(child: Text('This document no longer exists.')),
          );
        }
        return _DetailView(document: matches.first);
      },
    );
  }
}

class _DetailView extends ConsumerWidget {
  const _DetailView({required this.document});

  final ScannedDocument document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(document.title, overflow: TextOverflow.ellipsis),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'rename':
                  _rename(context, ref);
                case 'delete':
                  _delete(context, ref);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'rename', child: Text('Rename')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _MetadataCard(document: document),
          ),
          DocumentPagePreview(pages: document.pages),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _ActionBar(
              onSharePdf: () => _sharePdf(context, ref),
              onShareText: () => _shareText(context, ref),
              onCopyText: () => _copyText(context),
              onPrint: () => _printPdf(context, ref),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text('Recognized text', style: theme.textTheme.titleMedium),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OcrTextSection(document: document),
          ),
        ],
      ),
    );
  }

  Future<void> _sharePdf(BuildContext context, WidgetRef ref) async {
    if (!document.hasPdf) {
      showInfoSnackBar(context, 'No PDF is available for this document.');
      return;
    }
    try {
      await ref
          .read(sharingServiceProvider)
          .sharePdf(
            path: document.pdfPath!,
            fileName: buildPdfFileName(document.createdAt),
          );
    } catch (error) {
      if (!context.mounted) return;
      showErrorFeedback(context, error);
    }
  }

  Future<void> _shareText(BuildContext context, WidgetRef ref) async {
    if (!document.hasText) {
      showInfoSnackBar(context, 'There is no recognized text to share.');
      return;
    }
    try {
      await ref.read(sharingServiceProvider).shareText(document.combinedText);
    } catch (error) {
      if (!context.mounted) return;
      showErrorFeedback(context, error);
    }
  }

  Future<void> _printPdf(BuildContext context, WidgetRef ref) async {
    if (!document.hasPdf) {
      showInfoSnackBar(context, 'No PDF is available for this document.');
      return;
    }
    try {
      await ref.read(sharingServiceProvider).printPdf(document.pdfPath!);
    } catch (error) {
      if (!context.mounted) return;
      showErrorFeedback(context, error);
    }
  }

  void _copyText(BuildContext context) {
    if (!document.hasText) {
      showInfoSnackBar(context, 'There is no recognized text to copy.');
      return;
    }
    Clipboard.setData(ClipboardData(text: document.combinedText));
    showInfoSnackBar(context, 'Text copied to clipboard.');
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: document.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename document'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newTitle == null || newTitle.isEmpty || !context.mounted) return;
    await ref
        .read(documentsControllerProvider.notifier)
        .rename(document.id, newTitle);
    if (!context.mounted) return;
    showInfoSnackBar(context, 'Renamed.');
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete document?'),
        content: const Text(
          'This permanently removes the document, its pages and the PDF from '
          'this device. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(documentsControllerProvider.notifier).delete(document.id);
    if (!context.mounted) return;
    context.pop();
  }
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.document});
  final ScannedDocument document;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final created = DateFormat.yMMMMd().add_jm().format(document.createdAt);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(document.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            _MetaRow(icon: Icons.event, label: created),
            _MetaRow(
              icon: Icons.collections_outlined,
              label:
                  '${document.pageCount} page'
                  '${document.pageCount == 1 ? '' : 's'}',
            ),
            _MetaRow(
              icon: Icons.picture_as_pdf_outlined,
              label: document.hasPdf ? 'PDF saved' : 'No PDF',
            ),
            const SizedBox(height: 8),
            OcrStatusChip(status: document.ocrStatus),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.onSharePdf,
    required this.onShareText,
    required this.onCopyText,
    required this.onPrint,
  });

  final VoidCallback onSharePdf;
  final VoidCallback onShareText;
  final VoidCallback onCopyText;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.tonalIcon(
          onPressed: onSharePdf,
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Share PDF'),
        ),
        OutlinedButton.icon(
          onPressed: onShareText,
          icon: const Icon(Icons.notes_outlined),
          label: const Text('Share text'),
        ),
        OutlinedButton.icon(
          onPressed: onCopyText,
          icon: const Icon(Icons.copy_all_outlined),
          label: const Text('Copy text'),
        ),
        OutlinedButton.icon(
          onPressed: onPrint,
          icon: const Icon(Icons.print_outlined),
          label: const Text('Print'),
        ),
      ],
    );
  }
}
