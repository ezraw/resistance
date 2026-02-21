import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A particle in the pixel celebration effect.
class _PixelParticle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  Color color;

  _PixelParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
  });
}

/// CustomPainter that renders falling/exploding small colored squares
/// for an 8-bit "level complete" celebration effect.
class PixelCelebrationPainter extends CustomPainter {
  /// Animation progress from 0.0 to 1.0 over ~3 seconds.
  final double progress;

  /// Cached particles generated on first paint.
  late final List<_PixelParticle> _particles;
  bool _initialized = false;

  static const _colors = [
    AppColors.hotPink,
    AppColors.magenta,
    AppColors.neonCyan,
    AppColors.gold,
    AppColors.warmCream,
    AppColors.electricViolet,
  ];

  PixelCelebrationPainter({required this.progress});

  void _initParticles(Size size) {
    if (_initialized) return;
    _initialized = true;

    final random = Random(42); // fixed seed for deterministic layout
    _particles = List.generate(45, (i) {
      final angle = random.nextDouble() * 2 * pi;
      final speed = 100 + random.nextDouble() * 300;
      return _PixelParticle(
        x: size.width / 2,
        y: 0,
        vx: cos(angle) * speed,
        vy: sin(angle).abs() * speed * 0.5 + 50, // bias downward
        size: 2.0 + random.nextDouble() * 4.0, // 2-6px blocks
        color: _colors[random.nextInt(_colors.length)],
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    _initParticles(size);

    const gravity = 400.0;
    final t = progress * 3.0; // map 0-1 to 0-3 seconds
    // Fade out in the last third of the animation
    final opacity = progress < 0.67 ? 1.0 : ((1.0 - progress) / 0.33).clamp(0.0, 1.0);

    for (final particle in _particles) {
      final px = particle.x + particle.vx * t;
      final py = particle.y + particle.vy * t + 0.5 * gravity * t * t;
      final alpha = opacity;

      if (alpha <= 0) continue;

      final paint = Paint()
        ..color = particle.color.withValues(alpha: alpha);

      // Snap to pixel grid for 8-bit feel
      final snapSize = particle.size.roundToDouble();
      final snappedX = (px / 2).round() * 2.0;
      final snappedY = (py / 2).round() * 2.0;

      canvas.drawRect(
        Rect.fromLTWH(snappedX, snappedY, snapSize, snapSize),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(PixelCelebrationPainter oldDelegate) =>
      progress != oldDelegate.progress;
}
