import 'package:flutter/material.dart';
import '../painters/background_band_painter.dart';
import '../painters/particle_painter.dart';
import '../painters/streak_painter.dart';
import '../painters/resistance_band_config.dart';
import '../theme/accessibility.dart';

/// Composite background widget layering bands + streaks + particles + child.
class ArcadeBackground extends StatefulWidget {
  final Widget child;
  final int resistanceLevel;
  final bool isActive;
  final ResistanceBandConfig? config;

  const ArcadeBackground({
    super.key,
    required this.child,
    this.resistanceLevel = 0,
    this.isActive = false,
    this.config,
  });

  @override
  State<ArcadeBackground> createState() => _ArcadeBackgroundState();
}

class _ArcadeBackgroundState extends State<ArcadeBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config ??
        ResistanceBandConfig.forResistance(
          widget.resistanceLevel,
          isActive: widget.isActive,
        );

    final reduceMotion = Accessibility.reduceMotion(context);

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final time = _animController.value * 60; // 0-60 seconds

        return Stack(
          children: [
            // Layer 1: Banded background with dithering
            Positioned.fill(
              child: CustomPaint(
                painter: BackgroundBandPainter(
                  bandColors: config.bandColors,
                ),
              ),
            ),

            // Layer 2: Speed streaks
            if (config.showStreaks && !reduceMotion)
              Positioned.fill(
                child: CustomPaint(
                  painter: StreakPainter(
                    intensity: config.streakIntensity,
                    time: time,
                  ),
                ),
              ),

            // Layer 3: Pixel particles (in RepaintBoundary for performance)
            if (!reduceMotion)
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: ParticlePainter(time: time),
                  ),
                ),
              ),

            // Layer 4: Child content
            if (child != null) child,
          ],
        );
      },
      child: widget.child,
    );
  }
}
