/// Safe casting helpers for values read back from Hive.
///
/// Hive returns `Map<dynamic, dynamic>` and `List<dynamic>` for nested data, so
/// a direct `as Map<String, dynamic>` cast throws. These helpers rebuild the
/// collections with the correct element types instead.
Map<String, dynamic> asStringKeyedMap(Object? value) =>
    Map<String, dynamic>.from(value as Map);

List<String> asStringList(Object? value) =>
    (value as List).map((e) => e.toString()).toList();

List<Map<String, dynamic>> asMapList(Object? value) =>
    (value as List).map(asStringKeyedMap).toList();
