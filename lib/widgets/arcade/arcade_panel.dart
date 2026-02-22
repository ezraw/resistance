import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'pixel_container.dart';

/// Reusable arcade-style panel with colored border on dark fill.
/// Uses pixel stair-step corners for the 8-bit aesthetic.
class ArcadePanel extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final Color fillColor;
  final double borderWidth;
  final double notchSize;
  final int steps;
  final EdgeInsetsGeometry padding;

  const ArcadePanel({
    super.key,
    required this.child,
    this.borderColor = AppColors.magenta,
    this.fillColor = AppColors.nightPlum,
    this.borderWidth = 6,
    this.notchSize = 4,
    this.steps = 2,
    this.padding = const EdgeInsets.all(16),
  });

  /// Secondary panel variant with thinner border and smaller notch.
  const ArcadePanel.secondary({
    super.key,
    required this.child,
    this.borderColor = AppColors.magenta,
    this.fillColor = AppColors.nightPlum,
    this.borderWidth = 2,
    this.notchSize = 3,
    this.steps = 2,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    return PixelContainer(
      fillColor: fillColor,
      borderColor: borderColor,
      borderWidth: borderWidth,
      notchSize: notchSize,
      steps: steps,
      padding: padding,
      child: child,
    );
  }
}
