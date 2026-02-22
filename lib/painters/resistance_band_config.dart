import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Configuration for background bands at a given resistance level.
class ResistanceBandConfig {
  final List<Color> bandColors;
  final bool showStreaks;
  final double streakIntensity;

  const ResistanceBandConfig({
    required this.bandColors,
    this.showStreaks = true,
    this.streakIntensity = 0.5,
  });

  /// Returns the band configuration for the home screen at a given resistance level.
  static ResistanceBandConfig forResistance(int level, {bool isActive = false}) {
    return ResistanceBandConfig(
      bandColors: AppColors.resistanceBands(level),
      showStreaks: true,
      streakIntensity: isActive ? 0.8 : 0.4,
    );
  }

  /// Scan screen variant: deep indigo, no streaks.
  static const scan = ResistanceBandConfig(
    bandColors: [
      Color(0xFF1A0A3E),
      Color(0xFF150838),
      AppColors.nightPlum,
      Color(0xFF1A0530),
      Color(0xFF100320),
    ],
    showStreaks: false,
    streakIntensity: 0,
  );

  /// Summary screen variant.
  static ResistanceBandConfig get summary => ResistanceBandConfig(
        bandColors: AppColors.resistanceBands(30),
        showStreaks: true,
        streakIntensity: 0.3,
      );

  /// History screen variant: cool violet tones with subtle streaks.
  static const history = ResistanceBandConfig(
    bandColors: [
      Color(0xFF2A0E5C),
      Color(0xFF220B4E),
      Color(0xFF1A0840),
      AppColors.nightPlum,
      Color(0xFF1A0530),
      Color(0xFF120425),
      Color(0xFF0E031C),
    ],
    showStreaks: true,
    streakIntensity: 0.2,
  );
}
