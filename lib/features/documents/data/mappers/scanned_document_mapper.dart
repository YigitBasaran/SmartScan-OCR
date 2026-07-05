import 'package:smartscanocr/core/constants/app_constants.dart';
import 'package:smartscanocr/core/utils/map_cast.dart';
import 'package:smartscanocr/core/utils/schema_migration.dart';
import 'package:smartscanocr/features/documents/data/mappers/scanned_page_mapper.dart';
import 'package:smartscanocr/features/documents/domain/entities/ocr_status.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_document.dart';

/// Serializes a [ScannedDocument] to a JSON-compatible map for Hive.
///
/// Dates are stored as ISO-8601 strings and a [AppConstants.documentSchemaVersion]
/// is embedded so the shape can be migrated forward.
Map<String, dynamic> documentToMap(ScannedDocument doc) => {
  'schemaVersion': AppConstants.documentSchemaVersion,
  'id': doc.id,
  'title': doc.title,
  'createdAt': doc.createdAt.toIso8601String(),
  'updatedAt': doc.updatedAt.toIso8601String(),
  'pages': doc.pages.map(pageToMap).toList(),
  'pdfPath': doc.pdfPath,
  'combinedText': doc.combinedText,
  'pageCount': doc.pageCount,
  'ocrStatus': doc.ocrStatus.name,
};

/// Reconstructs a [ScannedDocument] from a Hive-stored map, migrating if needed.
ScannedDocument documentFromMap(Object? raw) {
  final map = migrateDocumentMap(asStringKeyedMap(raw));
  final pages = (map['pages'] as List).map(pageFromMap).toList()
    ..sort((a, b) => a.order.compareTo(b.order));
  return ScannedDocument(
    id: map['id'] as String,
    title: map['title'] as String,
    createdAt: DateTime.parse(map['createdAt'] as String),
    updatedAt: DateTime.parse(map['updatedAt'] as String),
    pages: pages,
    pdfPath: map['pdfPath'] as String?,
    combinedText: (map['combinedText'] as String?) ?? '',
    ocrStatus: parseOcrStatus(map['ocrStatus'] as String?),
  );
}
