import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartscanocr/core/constants/app_constants.dart';
import 'package:smartscanocr/features/documents/presentation/controllers/documents_controller.dart';
import 'package:smartscanocr/features/documents/presentation/controllers/search_controller.dart';
import 'package:smartscanocr/features/documents/presentation/widgets/document_grid.dart';
import 'package:smartscanocr/features/documents/presentation/widgets/empty_library_view.dart';
import 'package:smartscanocr/features/documents/presentation/widgets/library_search_bar.dart';
import 'package:smartscanocr/features/scanner/presentation/review_launch_action.dart';

/// Home screen: the searchable library of saved documents.
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  void _openReview(BuildContext context, ReviewLaunchAction action) {
    context.push('/review', extra: action);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtered = ref.watch(filteredDocumentsProvider);
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            tooltip: 'Import images',
            icon: const Icon(Icons.photo_library_outlined),
            onPressed: () => _openReview(context, ReviewLaunchAction.import),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openReview(context, ReviewLaunchAction.scan),
        icon: const Icon(Icons.document_scanner),
        label: const Text('Scan'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: LibrarySearchBar(),
          ),
          Expanded(
            child: filtered.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorView(
                onRetry: () =>
                    ref.read(documentsControllerProvider.notifier).refresh(),
              ),
              data: (docs) {
                if (docs.isEmpty) {
                  // With an empty query the filtered list equals all documents,
                  // so this is a genuinely empty library; otherwise it's a
                  // "no results" state for the current query.
                  if (query.trim().isEmpty) {
                    return EmptyLibraryView(
                      onScan: () =>
                          _openReview(context, ReviewLaunchAction.scan),
                      onImport: () =>
                          _openReview(context, ReviewLaunchAction.import),
                    );
                  }
                  return _NoResultsView(query: query);
                }
                return DocumentGrid(
                  documents: docs,
                  onOpen: (doc) => context.push('/document/${doc.id}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Could not load your documents.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _NoResultsView extends StatelessWidget {
  const _NoResultsView({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'No documents match "$query".',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
