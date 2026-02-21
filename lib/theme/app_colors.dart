import 'package:flutter/material.dart';

/// Strict 8-color palette + extended functional colors for the arcade aesthetic.
class AppColors {
  AppColors._();

  // === Core 8-Color Palette ===
  static const Color hotPink = Color(0xFFF21695);
  static const Color magenta = Color(0xFFDE1070);
  static const Color purpleMagenta = Color(0xFF9E0EAB);
  static const Color electricViolet = Color(0xFF6A0FC6);
  static const Color deepViolet = Color(0xFF5609B1);
  static const Color nightPlum = Color(0xFF29045C);
  static const Color neonCyan = Color(0xFF2BD1C2);
  static const Color warmCream = Color(0xFFFCEED0);

  // === Extended Functional Colors ===
  static const Color white = Color(0xFFFFFFFF);
  static const Color gold = Color(0xFFFFD700);
  static const Color goldDark = Color(0xFFCC9900);
  static const Color amber = Color(0xFFFFBF00);
  static const Color green = Color(0xFF00FF66);
  static const Color red = Color(0xFFFF3344);

  /// Returns the top band color for a given resistance level (0-100).
  static Color resistanceBandColor(int level) {
    if (level <= 20) return neonCyan;
    if (level <= 45) return hotPink;
    if (level <= 70) return const Color(0xFFFF8800); // orange-hot pink
    if (level <= 90) return const Color(0xFFFF4400); // deep orange-red
    return red;
  }

  /// Returns a list of band colors for the background gradient at a given resistance level.
  static List<Color> resistanceBands(int level) {
    final topColor = resistanceBandColor(level);
    if (level <= 20) {
      return [neonCyan, hotPink, magenta, purpleMagenta, electricViolet, deepViolet, nightPlum];
    } else if (level <= 45) {
      return [hotPink, magenta, purpleMagenta, electricViolet, deepViolet, nightPlum];
    } else if (level <= 70) {
      return [topColor, hotPink, magenta, purpleMagenta, electricViolet, deepViolet, nightPlum];
    } else if (level <= 90) {
      return [topColor, const Color(0xFFFF8800), hotPink, magenta, purpleMagenta, deepViolet, nightPlum];
    } else {
      return [red, topColor, hotPink, magenta, purpleMagenta, deepViolet, nightPlum];
    }
  }
}
