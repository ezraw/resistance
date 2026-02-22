import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// A pixel-art divider with a subtle arc.
///
/// The line is drawn as a series of small rectangles along a shallow arc
/// path. When [archUp] is false (default), endpoints sit at the top and the
/// center dips [dip] pixels lower (concave). When [archUp] is true, the
/// center rises [dip] pixels above the endpoints (convex). Coordinates are
/// snapped to a grid equal to [thickness].
class PixelDivider extends StatelessWidget {
  final Color color;
  final double thickness;
  final double dip;
  final double margin;
  final bool archUp;

  const PixelDivider({
    super.key,
    this.color = AppColors.purpleMagenta,
    this.thickness = 2,
    this.dip = 3,
    this.margin = 8,
    this.archUp = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: margin),
      child: CustomPaint(
        size: Size(double.infinity, thickness + dip),
        painter: _PixelDividerPainter(
          color: color,
          thickness: thickness,
          dip: dip,
          archUp: archUp,
        ),
      ),
    );
  }
}

class _PixelDividerPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final double dip;
  final bool archUp;

  _PixelDividerPainter({
    required this.color,
    required this.thickness,
    required this.dip,
    required this.archUp,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()..color = color;
    final grid = thickness; // snap to grid of this size
    final w = size.width;
    final steps = (w / grid).floor();
    if (steps <= 0) return;

    final halfSteps = steps ~/ 2;

    for (int i = 0; i < steps; i++) {
      final x = i * grid;
      // Calculate y offset along a parabolic arc: 0 at edges, dip at center
      final t = (i - halfSteps).abs() / halfSteps.clamp(1, halfSteps);
      final rawY = dip * (1 - t * t);
      // Snap to grid
      final snappedY = (rawY / grid).round() * grid;
      // archUp: invert so center is high (y=0) and edges are low (y=dip)
      final y = archUp ? dip - snappedY : snappedY;
      canvas.drawRect(
        Rect.fromLTWH(x, y, grid, grid),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_PixelDividerPainter oldDelegate) =>
      color != oldDelegate.color ||
      thickness != oldDelegate.thickness ||
      dip != oldDelegate.dip ||
      archUp != oldDelegate.archUp;
}
