import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartscanocr/core/widgets/app_snack_bar.dart';
import 'package:smartscanocr/features/documents/domain/entities/processing_phase.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_page.dart';
import 'package:smartscanocr/features/documents/presentation/controllers/document_edit_controller.dart';
import 'package:smartscanocr/features/documents/presentation/controllers/documents_controller.dart';
import 'package:smartscanocr/features/documents/presentation/screens/page_editor_screen.dart';
import 'package:smartscanocr/features/scanner/presentation/review_launch_action.dart';
import 'package:smartscanocr/features/scanner/presentation/widgets/processing_overlay.dart';
import 'package:smartscanocr/features/scanner/presentation/widgets/review_page_tile.dart';

/// Post-save editing: reorder / delete / add / edit pages, rename, then save —
/// which regenerates the PDF and re-runs OCR only for changed/new pages.
class EditDocumentScreen extends ConsumerStatefulWidget {
  const EditDocumentScreen({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<EditDocumentScreen> createState() => _EditDocumentScreenState();
}

class _EditDocumentScreenState extends ConsumerState<EditDocumentScreen> {
  DocumentEditController get _notifier =>
      ref.read(documentEditControllerProvider.notifier);

  Future<void> _editPage(ScannedPage page) async {
    final edited = await Navigator.of(context).push<ScannedPage>(
      MaterialPageRoute(builder: (_) => PageEditorScreen(page: page)),
    );
    if (edited != null) _notifier.applyPageEdit(edited);
  }

  Future<void> _confirmDeletePage(ScannedPage page) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete page?'),
        content: const Text('This page will be removed when you save changes.'),
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
    if (ok == true) _notifier.removePage(page.id);
  }

  Future<void> _showAddMenu() async {
    final action = await showModalBottomSheet<ReviewLaunchAction>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.document_scanner),
              title: const Text('Scan document'),
              onTap: () => Navigator.pop(context, ReviewLaunchAction.scan),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Import images'),
              onTap: () => Navigator.pop(context, ReviewLaunchAction.import),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    if (action == ReviewLaunchAction.scan) {
      await _notifier.addScan();
    } else {
      await _notifier.addImport();
    }
    if (!mounted) return;
    final error = ref.read(documentEditControllerProvider).error;
    if (error != null) {
      showErrorFeedback(context, error);
      _notifier.consumeError();
    }
  }

  Future<void> _rename(String current) async {
    final controller = TextEditingController(text: current);
    final title = await showDialog<String>(
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
    if (title == null || !mounted) return;
    _notifier.setTitle(title);
  }

  Future<void> _save() async {
    final document = await _notifier.save();
    if (!mounted) return;
    final state = ref.read(documentEditControllerProvider);
    if (state.error != null) {
      showErrorFeedback(context, state.error!);
      _notifier.consumeError();
    }
    if (state.noticeMessage != null) {
      showInfoSnackBar(context, state.noticeMessage!);
      _notifier.consumeNotice();
    }
    if (document != null) {
      showInfoSnackBar(context, 'Document updated.');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(documentsControllerProvider);
    return docsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Could not load this document.')),
      ),
      data: (docs) {
        final matches = docs.where((d) => d.id == widget.documentId);
        if (matches.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Edit document')),
            body: const Center(child: Text('This document no longer exists.')),
          );
        }
        // Initialize the working copy once from the saved document.
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _notifier.load(matches.first),
        );
        final state = ref.watch(documentEditControllerProvider);
        if (!state.loaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _buildEditor(state);
      },
    );
  }

  Widget _buildEditor(DocumentEditState state) {
    return Scaffold(
      appBar: AppBar(
        title: Text(state.title.isEmpty ? 'Edit document' : state.title),
        actions: [
          IconButton(
            tooltip: 'Rename',
            icon: const Icon(Icons.drive_file_rename_outline),
            onPressed: state.isBusy ? null : () => _rename(state.title),
          ),
        ],
      ),
      body: Stack(
        children: [
          ReorderableListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: state.pages.length,
            onReorderItem: _notifier.reorderPage,
            itemBuilder: (context, index) {
              final page = state.pages[index];
              return ReviewPageTile(
                key: ValueKey(page.id),
                page: page,
                index: index,
                onRotate: () => _notifier.rotatePage(page.id),
                onDelete: () => _confirmDeletePage(page),
                onEdit: () => _editPage(page),
              );
            },
          ),
          if (state.isBusy)
            ProcessingOverlay(
              phaseLabel: state.phase.label,
              current: state.currentPage,
              total: state.totalPages,
              progress: state.progress,
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: state.isBusy ? null : _showAddMenu,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: (state.isBusy || state.pages.isEmpty)
                      ? null
                      : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
