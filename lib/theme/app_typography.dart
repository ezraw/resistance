import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Text style factories using Press Start 2P pixel font.
class AppTypography {
  AppTypography._();

  static const String _fontFamily = 'PressStart2P';

  /// Large resistance number display (60-100pt).
  static TextStyle resistanceNumber({double fontSize = 80}) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: AppColors.white,
        height: 1,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Timer / BPM numbers.
  static TextStyle number({double fontSize = 20}) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: AppColors.white,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Button labels — always uppercase.
  static TextStyle button({double fontSize = 12, Color? color}) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.nightPlum,
        letterSpacing: 1,
      );

  /// Badge / HUD labels.
  static TextStyle label({double fontSize = 8, Color? color}) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.white,
      );

  /// Secondary / helper text.
  static TextStyle secondary({double fontSize = 8}) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: AppColors.warmCream.withValues(alpha: 0.7),
      );
}
