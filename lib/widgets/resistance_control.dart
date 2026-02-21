import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'arcade/arcade_panel.dart';
import 'arcade/pixel_container.dart';

class ResistanceControl extends StatefulWidget {
  final int currentLevel;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final bool isUpdating;

  const ResistanceControl({
    super.key,
    required this.currentLevel,
    required this.onIncrease,
    required this.onDecrease,
    this.isUpdating = false,
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
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 60,
            bottom: 100,
          ),
          child: _buildControlPanel(),
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return ArcadePanel(
      borderColor: AppColors.magenta,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 240),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // +5 button
            _buildIncrementButton(
              label: '+5',
              onTap: _handleIncrease,
              isEnabled: widget.currentLevel < 100 && !widget.isUpdating,
            ),

            // Level number
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: AnimatedBuilder(
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
            ),

            // -5 button
            _buildIncrementButton(
              label: '-5',
              onTap: _handleDecrease,
              isEnabled: widget.currentLevel > 0 && !widget.isUpdating,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncrementButton({
    required String label,
    required VoidCallback onTap,
    required bool isEnabled,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: double.infinity,
        child: PixelContainer(
          fillColor: isEnabled
              ? AppColors.gold
              : AppColors.gold.withValues(alpha: 0.35),
          borderColor: isEnabled
              ? AppColors.goldDark
              : AppColors.goldDark.withValues(alpha: 0.35),
          borderWidth: 3,
          notchSize: 3,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: Text(
              label,
              style: AppTypography.button(
                fontSize: 14,
                color: isEnabled
                    ? AppColors.nightPlum
                    : AppColors.nightPlum.withValues(alpha: 0.45),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
