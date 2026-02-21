import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'pixel_container.dart';

/// Small bordered badge for HUD elements: icon + text.
/// Uses pixel stair-step corners (notchSize: 2) for the 8-bit aesthetic.
class ArcadeBadge extends StatelessWidget {
  final Widget? icon;
  final String text;
  final Color borderColor;
  final Color fillColor;
  final Color? textColor;
  final double fontSize;
  final VoidCallback? onTap;

  const ArcadeBadge({
    super.key,
    this.icon,
    required this.text,
    this.borderColor = AppColors.electricViolet,
    this.fillColor = AppColors.nightPlum,
    this.textColor,
    this.fontSize = 8,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final badge = PixelContainer(
      fillColor: fillColor,
      borderColor: borderColor,
      borderWidth: 2,
      notchSize: 2,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: AppTypography.label(
              fontSize: fontSize,
              color: textColor ?? AppColors.white,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: badge,
      );
    }
    return badge;
  }
}
