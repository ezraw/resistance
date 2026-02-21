import 'package:flutter/material.dart';

/// Builds a closed [Path] with 2-step staircase corners, giving the
/// classic 8-bit pixel border look. Each corner has two notch steps of
/// [notchSize] pixels, creating a stepped diagonal instead of a curve.
///
/// [inset] shrinks the path inward (used for stroke centering).
Path buildPixelBorderPath(Rect rect, double notchSize, {double inset = 0}) {
  final l = rect.left + inset;
  final t = rect.top + inset;
  final r = rect.right - inset;
  final b = rect.bottom - inset;
  final n = notchSize;

  return Path()
    // Start at top-left, after the two-step notch
    ..moveTo(l + 2 * n, t)
    // Top edge → top-right corner notch
    ..lineTo(r - 2 * n, t)
    ..lineTo(r - 2 * n, t + n)
    ..lineTo(r - n, t + n)
    ..lineTo(r - n, t + 2 * n)
    ..lineTo(r, t + 2 * n)
    // Right edge → bottom-right corner notch
    ..lineTo(r, b - 2 * n)
    ..lineTo(r - n, b - 2 * n)
    ..lineTo(r - n, b - n)
    ..lineTo(r - 2 * n, b - n)
    ..lineTo(r - 2 * n, b)
    // Bottom edge → bottom-left corner notch
    ..lineTo(l + 2 * n, b)
    ..lineTo(l + 2 * n, b - n)
    ..lineTo(l + n, b - n)
    ..lineTo(l + n, b - 2 * n)
    ..lineTo(l, b - 2 * n)
    // Left edge → back to top-left corner notch
    ..lineTo(l, t + 2 * n)
    ..lineTo(l + n, t + 2 * n)
    ..lineTo(l + n, t + n)
    ..lineTo(l + 2 * n, t + n)
    ..close();
}

/// CustomPainter that draws a filled rectangle with pixel stair-step
/// corners and an optional border stroke.
class PixelBorderPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;
  final double notchSize;

  const PixelBorderPainter({
    required this.fillColor,
    required this.borderColor,
    required this.borderWidth,
    required this.notchSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Fill
    final fillPath = buildPixelBorderPath(rect, notchSize);
    canvas.drawPath(
      fillPath,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );

    // Stroke (inset by half the border width so it stays within bounds)
    if (borderWidth > 0) {
      final strokePath =
          buildPixelBorderPath(rect, notchSize, inset: borderWidth / 2);
      canvas.drawPath(
        strokePath,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth
          ..strokeJoin = StrokeJoin.miter,
      );
    }
  }

  @override
  bool shouldRepaint(PixelBorderPainter oldDelegate) =>
      fillColor != oldDelegate.fillColor ||
      borderColor != oldDelegate.borderColor ||
      borderWidth != oldDelegate.borderWidth ||
      notchSize != oldDelegate.notchSize;
}
