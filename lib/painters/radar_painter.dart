import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// CustomPainter for radar sweep animation on the scan screen.
/// Renders with pixel blocks for an 8-bit aesthetic.
class RadarPainter extends CustomPainter {
  final double sweepAngle; // 0.0 - 1.0 (fraction of full rotation)
  final double ringPhase; // 0.0 - 1.0 (ring expansion)

  RadarPainter({
    required this.sweepAngle,
    required this.ringPhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) / 2 * 0.9;
    final blockSize = max(4.0, maxRadius / 35); // pixel block size

    // Draw concentric rings as pixel blocks
    _drawPixelRings(canvas, center, maxRadius, blockSize);

    // Draw sweep beam as pixel blocks
    _drawPixelSweepBeam(canvas, center, maxRadius, blockSize);

    // Center dot as a square block
    final dotSize = blockSize * 1.5;
    canvas.drawRect(
      Rect.fromCenter(center: center, width: dotSize, height: dotSize),
      Paint()..color = AppColors.neonCyan,
    );
  }

  void _drawPixelRings(
      Canvas canvas, Offset center, double maxRadius, double blockSize) {
    for (int i = 1; i <= 4; i++) {
      final baseRadius = maxRadius * (i / 4);
      final expandedRadius = baseRadius + (maxRadius * 0.05 * ringPhase);
      final radius = expandedRadius.clamp(0.0, maxRadius);
      final alpha = (0.18 * (1 - ringPhase * 0.5)).clamp(0.05, 0.2);

      final paint = Paint()..color = AppColors.neonCyan.withValues(alpha: alpha);

      // Step around the circle placing pixel blocks
      final circumference = 2 * pi * radius;
      final steps = max(16, (circumference / blockSize).round());

      for (int s = 0; s < steps; s++) {
        final angle = (s / steps) * 2 * pi;
        // Snap to grid for staircase appearance
        final x = center.dx + cos(angle) * radius;
        final y = center.dy + sin(angle) * radius;
        final snappedX = (x / blockSize).round() * blockSize;
        final snappedY = (y / blockSize).round() * blockSize;

        canvas.drawRect(
          Rect.fromLTWH(
              snappedX - blockSize / 2, snappedY - blockSize / 2,
              blockSize, blockSize),
          paint,
        );
      }
    }
  }

  void _drawPixelSweepBeam(
      Canvas canvas, Offset center, double maxRadius, double blockSize) {
    final angle = sweepAngle * 2 * pi;

    // Phosphor trail (~90 degrees behind beam)
    for (int i = 0; i < 20; i++) {
      final trailAngle = angle - (i / 20) * (pi / 2);
      final alpha = (0.3 * (1 - i / 20)).clamp(0.0, 0.3);
      final paint = Paint()
        ..color = AppColors.neonCyan.withValues(alpha: alpha);

      // Draw pixel blocks along the beam line
      final beamSteps = max(8, (maxRadius / blockSize).round());
      for (int s = 0; s <= beamSteps; s++) {
        final r = (s / beamSteps) * maxRadius;
        final x = center.dx + cos(trailAngle) * r;
        final y = center.dy + sin(trailAngle) * r;
        final snappedX = (x / blockSize).round() * blockSize;
        final snappedY = (y / blockSize).round() * blockSize;

        canvas.drawRect(
          Rect.fromLTWH(
              snappedX - blockSize / 2, snappedY - blockSize / 2,
              blockSize, blockSize),
          paint,
        );
      }
    }

    // Main beam - brighter pixel blocks
    final mainPaint = Paint()
      ..color = AppColors.neonCyan.withValues(alpha: 0.8);
    final beamSteps = max(8, (maxRadius / blockSize).round());
    for (int s = 0; s <= beamSteps; s++) {
      final r = (s / beamSteps) * maxRadius;
      final x = center.dx + cos(angle) * r;
      final y = center.dy + sin(angle) * r;
      final snappedX = (x / blockSize).round() * blockSize;
      final snappedY = (y / blockSize).round() * blockSize;

      canvas.drawRect(
        Rect.fromLTWH(
            snappedX - blockSize / 2, snappedY - blockSize / 2,
            blockSize, blockSize),
        mainPaint,
      );
    }
  }

  @override
  bool shouldRepaint(RadarPainter oldDelegate) =>
      sweepAngle != oldDelegate.sweepAngle || ringPhase != oldDelegate.ringPhase;
}
