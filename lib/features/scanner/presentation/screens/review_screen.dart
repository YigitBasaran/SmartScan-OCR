import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartscanocr/core/widgets/app_snack_bar.dart';
import 'package:smartscanocr/features/scanner/presentation/controllers/scan_review_controller.dart';
import 'package:smartscanocr/features/scanner/presentation/controllers/scan_review_state.dart';
import 'package:smartscanocr/features/scanner/presentation/review_launch_action.dart';
import 'package:smartscanocr/features/scanner/presentation/widgets/processing_overlay.dart';
import 'package:smartscanocr/features/scanner/presentation/widgets/review_action_bar.dart';
import 'package:smartscanocr/features/scanner/presentation/widgets/review_page_tile.dart';

/// Review scanned/imported pages before running OCR and saving the PDF.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key, this.launchAction = ReviewLaunchAction.none});

  final ReviewLaunchAction launchAction;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  bool _launched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLaunch());
  }

  ScanReviewController get _notifier =>
      ref.read(scanReviewControllerProvider.notifier);

  Future<void> _maybeLaunch() async {
    if (_launched) return;
    _launched = true;
    switch (widget.launchAction) {
      case ReviewLaunchAction.scan:
        await _addPages(_notifier.scan);
      case ReviewLaunchAction.import:
        await _addPages(_notifier.importImages);
      case ReviewLaunchAction.none:
        break;
    }
  }

  /// Runs an add action then surfaces any error (cancellation is silent).
  Future<void> _addPages(Future<void> Function() action) async {
    await action();
    if (!mounted) return;
    final error = ref.read(scanReviewControllerProvider).error;
    if (error != null) {
      showErrorFeedback(context, error);
      _notifier.consumeError();
    }
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
      await _addPages(_notifier.scan);
    } else {
      await _addPages(_notifier.importImages);
    }
  }

  Future<void> _rename(String currentTitle) async {
    final controller = TextEditingController(text: currentTitle);
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Document title'),
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
    final document = await _notifier.runOcrAndSavePdf();
    if (!mounted) return;
    final error = ref.read(scanReviewControllerProvider).error;
    if (document != null) {
      if (error != null) showErrorFeedback(context, error);
      context.pushReplacement('/document/${document.id}');
    } else if (error != null) {
      showErrorFeedback(context, error);
      _notifier.consumeError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scanReviewControllerProvider);
    final showBottomBar = !(state.isEmpty && !state.isBusy);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.title.isEmpty ? 'Review' : state.title),
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
          _buildBody(state),
          if (state.isBusy)
            ProcessingOverlay(
              phaseLabel: state.phase.label,
              current: state.currentPage,
              total: state.totalPages,
              progress: state.progress,
            ),
        ],
      ),
      bottomNavigationBar: showBottomBar
          ? ReviewActionBar(
              onAdd: state.isBusy ? null : _showAddMenu,
              onSave: (state.isBusy || state.isEmpty) ? null : _save,
            )
          : null,
    );
  }

  Widget _buildBody(ScanReviewState state) {
    if (state.isEmpty && !state.isBusy) {
      return _EmptyReview(
        onScan: () => _addPages(_notifier.scan),
        onImport: () => _addPages(_notifier.importImages),
      );
    }
    return ReorderableListView.builder(
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
          onDelete: () => _notifier.removePage(page.id),
        );
      },
    );
  }
}

class _EmptyReview extends StatelessWidget {
  const _EmptyReview({required this.onScan, required this.onImport});
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
              Icons.add_photo_alternate_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('No pages yet', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Scan a document or import images to review them here.',
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
                  label: const Text('Scan'),
                ),
                OutlinedButton.icon(
                  onPressed: onImport,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Import'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
