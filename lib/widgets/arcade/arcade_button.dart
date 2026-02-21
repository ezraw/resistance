import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'pixel_container.dart';

/// Color scheme presets for arcade buttons.
enum ArcadeButtonScheme {
  gold,    // START, DONE, RESUME
  magenta, // PAUSE
  orange,  // RESTART
  red,     // FINISH
}

/// Reusable arcade-style button with 3D depth, dark border, uppercase text.
/// Includes press/release animation (translateY + shadow shrink).
/// Uses pixel stair-step corners for the 8-bit aesthetic.
class ArcadeButton extends StatefulWidget {
  final String label;
  final Widget? icon;
  final VoidCallback? onTap;
  final ArcadeButtonScheme scheme;
  final bool enabled;
  final double minHeight;
  final double minWidth;

  const ArcadeButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.scheme = ArcadeButtonScheme.gold,
    this.enabled = true,
    this.minHeight = 48,
    this.minWidth = 120,
  });

  @override
  State<ArcadeButton> createState() => _ArcadeButtonState();
}

class _ArcadeButtonState extends State<ArcadeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _pressAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _pressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _pressController,
        curve: Curves.linear,
        reverseCurve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  Color get _topColor {
    switch (widget.scheme) {
      case ArcadeButtonScheme.gold:
        return AppColors.gold;
      case ArcadeButtonScheme.magenta:
        return AppColors.magenta;
      case ArcadeButtonScheme.orange:
        return const Color(0xFFFF8C00);
      case ArcadeButtonScheme.red:
        return AppColors.red;
    }
  }

  Color get _bottomColor {
    switch (widget.scheme) {
      case ArcadeButtonScheme.gold:
        return AppColors.goldDark;
      case ArcadeButtonScheme.magenta:
        return const Color(0xFF8A0A48);
      case ArcadeButtonScheme.orange:
        return const Color(0xFFCC6600);
      case ArcadeButtonScheme.red:
        return const Color(0xFFCC1122);
    }
  }

  Color get _textColor {
    switch (widget.scheme) {
      case ArcadeButtonScheme.gold:
        return AppColors.nightPlum;
      case ArcadeButtonScheme.magenta:
      case ArcadeButtonScheme.orange:
      case ArcadeButtonScheme.red:
        return AppColors.white;
    }
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.enabled) return;
    _pressController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (!widget.enabled) return;
    _pressController.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    if (!widget.enabled) return;
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveOpacity = widget.enabled ? 1.0 : 0.4;
    final maxDepth = widget.enabled ? 4.0 : 0.0;

    return Opacity(
      opacity: effectiveOpacity,
      child: AnimatedBuilder(
        animation: _pressAnimation,
        builder: (context, child) {
          final pressProgress = _pressAnimation.value;
          final translateY = pressProgress * 3; // 0-3px down
          final depthHeight = maxDepth * (1 - pressProgress); // shrink to 0

          return GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            child: UnconstrainedBox(
              child: Transform.translate(
                offset: Offset(0, translateY),
                child: IntrinsicWidth(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: widget.minHeight,
                      minWidth: widget.minWidth,
                    ),
                    child: PixelContainer(
                      fillColor: _bottomColor,
                      borderColor: AppColors.nightPlum,
                      borderWidth: 3,
                      notchSize: 3,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          color: _topColor,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (widget.icon != null) ...[
                                widget.icon!,
                                const SizedBox(width: 8),
                              ],
                              Text(
                                widget.label.toUpperCase(),
                                style: AppTypography.button(
                                  fontSize: 12,
                                  color: _textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (depthHeight > 0)
                          Container(
                            height: depthHeight,
                            color: _bottomColor,
                          ),
                      ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
