import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// CustomPainter for diagonal speed streaks in the upper portion of the screen.
class StreakPainter extends CustomPainter {
  final double intensity; // 0.0 - 1.0
  final double time; // for shimmer animation

  StreakPainter({
    required this.intensity,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0 || size.width <= 0 || size.height <= 0) return;

    final random = Random(123); // fixed seed for consistent placement
    final streakCount = (4 + intensity * 6).toInt(); // 4-10 streaks
    final upperThird = size.height * 0.4;

    for (int i = 0; i < streakCount; i++) {
      final startX = random.nextDouble() * size.width * 1.2 - size.width * 0.1;
      final startY = random.nextDouble() * upperThird;
      final length = 40 + random.nextDouble() * 80;
      final isCyan = random.nextDouble() < 0.6;
      final baseColor = isCyan ? AppColors.neonCyan : AppColors.warmCream;

      // Shimmer: a brighter band moving along the streak
      final shimmerPhase = (time / 4.0 + i * 0.3) % 1.0;
      final shimmerCenter = shimmerPhase;
      const shimmerWidth = 0.15;

      // Draw streak as pixel-stepped diagonal segments
      final segmentCount = (length / 4).floor();
      for (int s = 0; s < segmentCount; s++) {
        final t = s / segmentCount;
        final sx = startX + s * 4.0;
        final sy = startY + s * 2.0; // ~26 degree angle

        // Calculate shimmer opacity at this point
        final distFromShimmer = (t - shimmerCenter).abs();
        final shimmerFactor = distFromShimmer < shimmerWidth
            ? (1 - distFromShimmer / shimmerWidth) * 0.4
            : 0.0;
        final alpha = (0.15 + shimmerFactor) * intensity;

        canvas.drawRect(
          Rect.fromLTWH(sx, sy, 4, 2),
          Paint()..color = baseColor.withValues(alpha: alpha.clamp(0.0, 1.0)),
        );
      }
    }
  }

  @override
  bool shouldRepaint(StreakPainter oldDelegate) =>
      intensity != oldDelegate.intensity || time != oldDelegate.time;
}
