import 'package:smartscanocr/core/utils/map_cast.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_page.dart';

/// Serializes a [ScannedPage] to a JSON-compatible map (stored inside a document).
Map<String, dynamic> pageToMap(ScannedPage page) => {
  'id': page.id,
  'imagePath': page.imagePath,
  'order': page.order,
  'rotationQuarterTurns': page.rotationQuarterTurns,
  'ocrText': page.ocrText,
};

/// Reconstructs a [ScannedPage] from a Hive-stored map (with safe casts).
ScannedPage pageFromMap(Object? raw) {
  final map = asStringKeyedMap(raw);
  return ScannedPage(
    id: map['id'] as String,
    imagePath: map['imagePath'] as String,
    order: (map['order'] as num?)?.toInt() ?? 0,
    rotationQuarterTurns: (map['rotationQuarterTurns'] as num?)?.toInt() ?? 0,
    ocrText: map['ocrText'] as String?,
  );
}
