import 'package:flutter/material.dart';

/// Bottom bar for the review screen: add more pages + run the save pipeline.
///
/// A null callback disables the corresponding button (e.g. while processing).
class ReviewActionBar extends StatelessWidget {
  const ReviewActionBar({super.key, this.onAdd, this.onSave});

  final VoidCallback? onAdd;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.check),
                label: const Text('Run OCR & Save PDF'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
