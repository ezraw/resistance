import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'arcade/arcade_panel.dart';
import 'arcade/pixel_divider.dart';
import 'arcade/resistance_arrow.dart';

class ResistanceControl extends StatefulWidget {
  final int currentLevel;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final bool isUpdating;
  final Widget? leftOverlay;
  final Widget? rightOverlay;

  const ResistanceControl({
    super.key,
    required this.currentLevel,
    required this.onIncrease,
    required this.onDecrease,
    this.isUpdating = false,
    this.leftOverlay,
    this.rightOverlay,
  });

  @override
  State<ResistanceControl> createState() => _ResistanceControlState();
}

class _ResistanceControlState extends State<ResistanceControl>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _pulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleIncrease() {
    if (widget.currentLevel >= 100 || widget.isUpdating) return;
    _pulseController.forward(from: 0);
    widget.onIncrease();
  }

  void _handleDecrease() {
    if (widget.currentLevel <= 0 || widget.isUpdating) return;
    _pulseController.forward(from: 0);
    widget.onDecrease();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _buildControlPanel(),
    );
  }

  Widget _buildControlPanel() {
    final increaseEnabled = widget.currentLevel < 100 && !widget.isUpdating;
    final decreaseEnabled = widget.currentLevel > 0 && !widget.isUpdating;

    return ArcadePanel(
      borderColor: AppColors.magenta,
      borderWidth: 8,
      notchSize: 5,
      steps: 4,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Stack(
        children: [
          Column(
            children: [
              // Top half — increase zone
              Expanded(
                child: GestureDetector(
                  onTap: _handleIncrease,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      Opacity(
                        opacity: increaseEnabled ? 1.0 : 0.35,
                        child: const ResistanceArrow(
                          direction: ArrowDirection.up,
                          shadowColor: AppColors.goldDark,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),

              // Divider right above number (arches up)
              const PixelDivider(thickness: 4, dip: 12, margin: 0, archUp: true),
              const SizedBox(height: 16),

              // Center number with pulse animation
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value > 1.0
                        ? 1.0 + (_pulseAnimation.value - 1.0) * 0.5
                        : 1.0,
                    child: child,
                  );
                },
                child: Text(
                  '${widget.currentLevel}',
                  style: AppTypography.resistanceNumber(
                    fontSize: widget.currentLevel >= 100 ? 48 : 64,
                  ),
                ),
              ),

              const SizedBox(height: 12),
              // Divider right below number
              const PixelDivider(thickness: 4, dip: 12, margin: 0),

              // Bottom half — decrease zone
              Expanded(
                child: GestureDetector(
                  onTap: _handleDecrease,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      Opacity(
                        opacity: decreaseEnabled ? 1.0 : 0.35,
                        child: const ResistanceArrow(
                          direction: ArrowDirection.down,
                          shadowColor: AppColors.burntOrange,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Left overlay (e.g. HR pill) — vertically centered inside panel
          if (widget.leftOverlay != null)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Center(child: widget.leftOverlay!),
            ),

          // Right overlay (e.g. Power pill) — vertically centered inside panel
          if (widget.rightOverlay != null)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Center(child: widget.rightOverlay!),
            ),
        ],
      ),
    );
  }

}
