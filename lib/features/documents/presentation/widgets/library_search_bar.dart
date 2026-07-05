import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartscanocr/features/documents/presentation/controllers/search_controller.dart';

/// Search field that filters the library by title and recognized text.
class LibrarySearchBar extends ConsumerStatefulWidget {
  const LibrarySearchBar({super.key});

  @override
  ConsumerState<LibrarySearchBar> createState() => _LibrarySearchBarState();
}

class _LibrarySearchBarState extends ConsumerState<LibrarySearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.search,
      onChanged: (value) {
        ref.read(searchQueryProvider.notifier).update(value);
        setState(() {}); // refresh the clear button
      },
      decoration: InputDecoration(
        hintText: 'Search title or recognized text',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Clear',
                onPressed: () {
                  _controller.clear();
                  ref.read(searchQueryProvider.notifier).clear();
                  setState(() {});
                },
              ),
      ),
    );
  }
}
