import 'package:smartscanocr/core/utils/map_cast.dart';
import 'package:smartscanocr/features/documents/domain/entities/page_filter.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_page.dart';
import 'package:smartscanocr/features/perspective/domain/entities/document_corner.dart';

/// Serializes a [ScannedPage] to a JSON-compatible map (stored inside a document).
Map<String, dynamic> pageToMap(ScannedPage page) => {
  'id': page.id,
  'originalImagePath': page.originalImagePath,
  'processedImagePath': page.processedImagePath,
  'order': page.order,
  'rotationQuarterTurns': page.rotationQuarterTurns,
  'cropCorners': page.cropCorners?.map((c) => c.toMap()).toList(),
  'filterMode': page.filterMode.name,
  'ocrText': page.ocrText,
};

/// Reconstructs a [ScannedPage] from a Hive-stored map (with safe casts).
///
/// Defensively falls back to the v1 `imagePath` key so pre-v2 documents load
/// without a separate page-level migration pass.
ScannedPage pageFromMap(Object? raw) {
  final map = asStringKeyedMap(raw);
  final original = (map['originalImagePath'] ?? map['imagePath']) as String;
  final cornersRaw = map['cropCorners'];
  return ScannedPage(
    id: map['id'] as String,
    originalImagePath: original,
    processedImagePath: map['processedImagePath'] as String?,
    order: (map['order'] as num?)?.toInt() ?? 0,
    rotationQuarterTurns: (map['rotationQuarterTurns'] as num?)?.toInt() ?? 0,
    cropCorners: cornersRaw == null
        ? null
        : (cornersRaw as List)
              .map((e) => DocumentCorner.fromMap(asStringKeyedMap(e)))
              .toList(),
    filterMode: parsePageFilter(map['filterMode'] as String?),
    ocrText: map['ocrText'] as String?,
  );
}
