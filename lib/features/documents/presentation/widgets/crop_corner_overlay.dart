import 'package:flutter/material.dart';
import 'package:smartscanocr/features/perspective/domain/entities/document_corner.dart';
import 'package:smartscanocr/features/perspective/presentation/crop_geometry.dart';

/// Draggable four-corner crop overlay drawn over a `BoxFit.contain` image.
///
/// [corners] are normalized `[0..1]` in TL, TR, BR, BL order. Dragging a handle
/// reports updated corners via [onChanged].
class CropCornerOverlay extends StatelessWidget {
  const CropCornerOverlay({
    super.key,
    required this.imageAspect,
    required this.corners,
    required this.onChanged,
  });

  final double imageAspect;
  final List<DocumentCorner> corners;
  final ValueChanged<List<DocumentCorner>> onChanged;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return LayoutBuilder(
      builder: (context, constraints) {
        final box = Size(constraints.maxWidth, constraints.maxHeight);
        final fit = containedRect(box, imageAspect);
        final points = corners.map((c) => normalizedToScreen(c, fit)).toList();
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _QuadPainter(points, color)),
            ),
            for (var i = 0; i < points.length; i++)
              Positioned(
                left: points[i].dx - 18,
                top: points[i].dy - 18,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: (details) {
                    final updated = [...corners];
                    updated[i] = screenToNormalized(
                      points[i] + details.delta,
                      fit,
                    );
                    onChanged(updated);
                  },
                  child: _Handle(color: color),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.35),
          border: Border.all(color: color, width: 2),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _QuadPainter extends CustomPainter {
  _QuadPainter(this.points, this.color);
  final List<Offset> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length != 4) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()..addPolygon(points, true);
    canvas.drawPath(path, paint);
    final fill = Paint()..color = color.withValues(alpha: 0.12);
    canvas.drawPath(path, fill);
  }

  @override
  bool shouldRepaint(covariant _QuadPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}
