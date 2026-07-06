import 'package:flutter/material.dart';
import 'package:smartscanocr/features/documents/domain/entities/page_filter.dart';

/// Horizontal chips for choosing a page's scan-style filter.
class PageFilterSelector extends StatelessWidget {
  const PageFilterSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final PageFilter selected;
  final ValueChanged<PageFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final filter in PageFilter.values)
          ChoiceChip(
            label: Text(filter.label),
            selected: selected == filter,
            onSelected: (_) => onSelected(filter),
          ),
      ],
    );
  }
}
