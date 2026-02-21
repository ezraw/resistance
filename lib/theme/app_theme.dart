import 'package:flutter/material.dart';
import 'app_colors.dart';

/// MaterialApp ThemeData for the retro arcade aesthetic.
class AppTheme {
  AppTheme._();

  static ThemeData get data => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.nightPlum,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.magenta,
          secondary: AppColors.neonCyan,
          surface: AppColors.nightPlum,
          error: AppColors.red,
          onPrimary: AppColors.white,
          onSecondary: AppColors.nightPlum,
          onSurface: AppColors.white,
          onError: AppColors.white,
        ),
        useMaterial3: true,
        fontFamily: 'PressStart2P',
      );
}
