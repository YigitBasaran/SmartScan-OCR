import 'package:flutter/material.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_document.dart';
import 'package:smartscanocr/features/documents/presentation/widgets/document_card.dart';

/// Responsive grid of [DocumentCard]s.
class DocumentGrid extends StatelessWidget {
  const DocumentGrid({
    super.key,
    required this.documents,
    required this.onOpen,
  });

  final List<ScannedDocument> documents;
  final void Function(ScannedDocument document) onOpen;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents[index];
        return DocumentCard(document: document, onTap: () => onOpen(document));
      },
    );
  }
}
