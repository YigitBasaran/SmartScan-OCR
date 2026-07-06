import 'package:smartscanocr/features/documents/domain/entities/scanned_page.dart';

/// Pure page-list edit operations shared by the pre-save review flow and the
/// post-save document editor, so both behave identically.

/// Reassigns `order` from list position.
List<ScannedPage> reindexPages(List<ScannedPage> pages) => [
  for (var i = 0; i < pages.length; i++) pages[i].copyWith(order: i),
];

List<ScannedPage> removePageById(List<ScannedPage> pages, String id) =>
    reindexPages(pages.where((p) => p.id != id).toList());

/// Moves the page at [oldIndex] to [newIndex] (already adjusted by
/// `ReorderableListView.onReorderItem`).
List<ScannedPage> reorderPages(
  List<ScannedPage> pages,
  int oldIndex,
  int newIndex,
) {
  final list = [...pages];
  final moved = list.removeAt(oldIndex);
  list.insert(newIndex, moved);
  return reindexPages(list);
}

/// Rotates one page 90° clockwise and marks it for reprocessing.
List<ScannedPage> rotatePageById(List<ScannedPage> pages, String id) => [
  for (final p in pages)
    if (p.id == id)
      p.copyWith(
        rotationQuarterTurns: (p.rotationQuarterTurns + 1) % 4,
        clearProcessed: true,
      )
    else
      p,
];

/// Replaces a page with an edited version (from the page editor).
List<ScannedPage> replacePage(List<ScannedPage> pages, ScannedPage updated) => [
  for (final p in pages)
    if (p.id == updated.id) updated else p,
];

/// Appends new pages (from scan/import) after the current ones.
List<ScannedPage> appendPages(
  List<ScannedPage> pages,
  List<ScannedPage> newPages,
) => reindexPages([...pages, ...newPages]);
