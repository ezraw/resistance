import 'package:flutter/material.dart';

/// Builds a closed [Path] with N-step staircase corners. Each corner
/// iterates [steps] times, alternating horizontal and vertical segments
/// of [notchSize] length, consuming `steps * notchSize` pixels per axis.
///
/// With `steps: 2` the output is identical to [buildPixelBorderPath].
///
/// [inset] shrinks the path inward (used for stroke centering).
Path buildPixelBorderPathMultiStep(
  Rect rect,
  double notchSize, {
  double inset = 0,
  int steps = 2,
}) {
  final l = rect.left + inset;
  final t = rect.top + inset;
  final r = rect.right - inset;
  final b = rect.bottom - inset;
  final n = notchSize;
  final s = steps;

  final path = Path()..moveTo(l + s * n, t);

  // Top edge → top-right corner notch
  path.lineTo(r - s * n, t);
  for (int i = s; i >= 1; i--) {
    path.lineTo(r - i * n, t + (s - i) * n + n);
    if (i > 1) path.lineTo(r - (i - 1) * n, t + (s - i) * n + n);
  }
  path.lineTo(r, t + s * n);

  // Right edge → bottom-right corner notch
  path.lineTo(r, b - s * n);
  for (int i = s; i >= 1; i--) {
    path.lineTo(r - (s - i) * n - n, b - i * n);
    if (i > 1) path.lineTo(r - (s - i) * n - n, b - (i - 1) * n);
  }
  path.lineTo(r - s * n, b);

  // Bottom edge → bottom-left corner notch
  path.lineTo(l + s * n, b);
  for (int i = s; i >= 1; i--) {
    path.lineTo(l + i * n, b - (s - i) * n - n);
    if (i > 1) path.lineTo(l + (i - 1) * n, b - (s - i) * n - n);
  }
  path.lineTo(l, b - s * n);

  // Left edge → back to top-left corner notch
  path.lineTo(l, t + s * n);
  for (int i = s; i >= 1; i--) {
    path.lineTo(l + (s - i) * n + n, t + i * n);
    if (i > 1) path.lineTo(l + (s - i) * n + n, t + (i - 1) * n);
  }

  return path..close();
}

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
  final int steps;

  const PixelBorderPainter({
    required this.fillColor,
    required this.borderColor,
    required this.borderWidth,
    required this.notchSize,
    this.steps = 2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Fill
    final fillPath =
        buildPixelBorderPathMultiStep(rect, notchSize, steps: steps);
    canvas.drawPath(
      fillPath,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );

    // Stroke (inset by half the border width so it stays within bounds)
    if (borderWidth > 0) {
      final strokePath = buildPixelBorderPathMultiStep(rect, notchSize,
          inset: borderWidth / 2, steps: steps);
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
      notchSize != oldDelegate.notchSize ||
      steps != oldDelegate.steps;
}
