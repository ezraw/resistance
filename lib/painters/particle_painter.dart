import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A single pixel particle.
class _Particle {
  double x;
  double y;
  double speed;
  int size; // 1 = 1px, 2 = 2x2 block
  Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.color,
  });
}

/// CustomPainter for drifting pixel particles.
/// Should be wrapped in a RepaintBoundary for performance.
class ParticlePainter extends CustomPainter {
  final double time; // elapsed seconds for animation
  final int particleCount;
  final List<_Particle> _particles;

  ParticlePainter({
    required this.time,
    this.particleCount = 80,
  }) : _particles = _generateParticles(particleCount);

  static final Random _random = Random(42); // fixed seed for deterministic layout

  static List<_Particle> _generateParticles(int count) {
    final particles = <_Particle>[];
    for (int i = 0; i < count; i++) {
      final is2x2 = _random.nextDouble() < 0.3;
      // Color distribution: 60% magenta, 25% violet, 10% deep violet, 5% cyan
      final colorRoll = _random.nextDouble();
      Color color;
      if (colorRoll < 0.60) {
        color = AppColors.magenta.withValues(alpha: 0.4);
      } else if (colorRoll < 0.85) {
        color = AppColors.electricViolet.withValues(alpha: 0.35);
      } else if (colorRoll < 0.95) {
        color = AppColors.deepViolet.withValues(alpha: 0.3);
      } else {
        color = AppColors.neonCyan.withValues(alpha: 0.5);
      }

      particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: 5 + _random.nextDouble() * 5, // 5-10 px/sec
        size: is2x2 ? 2 : 1,
        color: color,
      ));
    }
    return particles;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    const pixelSize = 2.0;

    for (final p in _particles) {
      // Animate y position downward, wrapping at bottom
      final drift = (p.speed * time) % size.height;
      final y = (p.y * size.height + drift) % size.height;
      final x = p.x * size.width;
      final blockSize = p.size * pixelSize;

      canvas.drawRect(
        Rect.fromLTWH(x, y, blockSize, blockSize),
        Paint()..color = p.color,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => time != oldDelegate.time;
}
