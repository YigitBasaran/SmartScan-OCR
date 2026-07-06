import 'package:flutter/widgets.dart';
import 'package:smartscanocr/features/documents/domain/entities/page_filter.dart';

/// Wraps [child] with on-screen colour filters that approximate the
/// image-package processing for [filter], so the editor/thumbnail preview
/// closely matches the saved output. Purely visual (no re-encode). Filters are
/// composed by nesting [ColorFiltered] widgets.
Widget applyFilterPreview(PageFilter filter, Widget child) {
  switch (filter) {
    case PageFilter.none:
      return child;
    case PageFilter.grayscale:
      return ColorFiltered(colorFilter: _grayscale, child: child);
    case PageFilter.blackWhite:
      // grayscale, then strong contrast — matches img.contrast(grayscale, 200).
      return ColorFiltered(
        colorFilter: _contrast(2.0),
        child: ColorFiltered(colorFilter: _grayscale, child: child),
      );
    case PageFilter.enhance:
      // contrast 1.15 + saturation 1.1 + brightness 1.03 (img.adjustColor).
      return ColorFiltered(
        colorFilter: _contrast(1.15),
        child: ColorFiltered(
          colorFilter: _saturation(1.1),
          child: ColorFiltered(colorFilter: _brightness(1.03), child: child),
        ),
      );
  }
}

const ColorFilter _grayscale = ColorFilter.matrix(<double>[
  0.299, 0.587, 0.114, 0, 0, //
  0.299, 0.587, 0.114, 0, 0, //
  0.299, 0.587, 0.114, 0, 0, //
  0, 0, 0, 1, 0,
]);

/// Contrast around mid-grey: out = (in - 0.5) * c + 0.5 (c = 1 is identity).
ColorFilter _contrast(double c) {
  final t = 128 * (1 - c);
  return ColorFilter.matrix(<double>[
    c, 0, 0, 0, t, //
    0, c, 0, 0, t, //
    0, 0, c, 0, t, //
    0, 0, 0, 1, 0,
  ]);
}

/// Multiplicative brightness (b = 1 is identity).
ColorFilter _brightness(double b) => ColorFilter.matrix(<double>[
  b, 0, 0, 0, 0, //
  0, b, 0, 0, 0, //
  0, 0, b, 0, 0, //
  0, 0, 0, 1, 0,
]);

/// Saturation interpolation toward luminance (s = 1 is identity).
ColorFilter _saturation(double s) {
  const lumR = 0.299, lumG = 0.587, lumB = 0.114;
  final sr = (1 - s) * lumR, sg = (1 - s) * lumG, sb = (1 - s) * lumB;
  return ColorFilter.matrix(<double>[
    sr + s, sg, sb, 0, 0, //
    sr, sg + s, sb, 0, 0, //
    sr, sg, sb + s, 0, 0, //
    0, 0, 0, 1, 0,
  ]);
}
