/// A scan-style filter applied to a page image during processing.
enum PageFilter { none, grayscale, blackWhite, enhance }

/// Parses a [PageFilter] from its persisted `name`, defaulting to [PageFilter.none].
PageFilter parsePageFilter(String? name) => PageFilter.values.firstWhere(
  (f) => f.name == name,
  orElse: () => PageFilter.none,
);

extension PageFilterLabel on PageFilter {
  String get label => switch (this) {
    PageFilter.none => 'Original',
    PageFilter.grayscale => 'Grayscale',
    PageFilter.blackWhite => 'Black & white',
    PageFilter.enhance => 'Enhance',
  };
}
