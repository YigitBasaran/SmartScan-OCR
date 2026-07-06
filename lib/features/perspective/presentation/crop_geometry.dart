import 'dart:ui';

import 'package:smartscanocr/features/perspective/domain/entities/document_corner.dart';

/// Pure screen↔normalized coordinate mapping for the crop overlay.
///
/// The image is shown with `BoxFit.contain`; [containedRect] is the letterboxed
/// rectangle the image actually occupies inside [box]. Normalized corners are in
/// `[0..1]` of the (un-rotated) source image, matching where the image processor
/// applies them — no rotation is involved in this mapping.

Rect containedRect(Size box, double imageAspect) {
  final boxAspect = box.width / box.height;
  double w;
  double h;
  if (imageAspect >= boxAspect) {
    w = box.width;
    h = box.width / imageAspect;
  } else {
    h = box.height;
    w = box.height * imageAspect;
  }
  final left = (box.width - w) / 2;
  final top = (box.height - h) / 2;
  return Rect.fromLTWH(left, top, w, h);
}

Offset normalizedToScreen(DocumentCorner c, Rect fit) =>
    Offset(fit.left + c.x * fit.width, fit.top + c.y * fit.height);

DocumentCorner screenToNormalized(Offset o, Rect fit) => DocumentCorner(
  ((o.dx - fit.left) / fit.width).clamp(0.0, 1.0),
  ((o.dy - fit.top) / fit.height).clamp(0.0, 1.0),
);

/// Full-frame quad in TL, TR, BR, BL order — the crop starting position.
List<DocumentCorner> fullFrameCorners() => const [
  DocumentCorner(0, 0),
  DocumentCorner(1, 0),
  DocumentCorner(1, 1),
  DocumentCorner(0, 1),
];
