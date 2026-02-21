import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resistance_app/theme/app_colors.dart';

void main() {
  group('AppColors', () {
    test('core palette hex values are correct', () {
      expect(AppColors.hotPink, const Color(0xFFF21695));
      expect(AppColors.magenta, const Color(0xFFDE1070));
      expect(AppColors.purpleMagenta, const Color(0xFF9E0EAB));
      expect(AppColors.electricViolet, const Color(0xFF6A0FC6));
      expect(AppColors.deepViolet, const Color(0xFF5609B1));
      expect(AppColors.nightPlum, const Color(0xFF29045C));
      expect(AppColors.neonCyan, const Color(0xFF2BD1C2));
      expect(AppColors.warmCream, const Color(0xFFFCEED0));
    });

    test('functional colors hex values are correct', () {
      expect(AppColors.gold, const Color(0xFFFFD700));
      expect(AppColors.goldDark, const Color(0xFFCC9900));
      expect(AppColors.amber, const Color(0xFFFFBF00));
      expect(AppColors.green, const Color(0xFF00FF66));
      expect(AppColors.red, const Color(0xFFFF3344));
    });

    group('resistanceBandColor', () {
      test('returns cyan for 0-20%', () {
        expect(AppColors.resistanceBandColor(0), AppColors.neonCyan);
        expect(AppColors.resistanceBandColor(10), AppColors.neonCyan);
        expect(AppColors.resistanceBandColor(20), AppColors.neonCyan);
      });

      test('returns hot pink for 25-45%', () {
        expect(AppColors.resistanceBandColor(25), AppColors.hotPink);
        expect(AppColors.resistanceBandColor(35), AppColors.hotPink);
        expect(AppColors.resistanceBandColor(45), AppColors.hotPink);
      });

      test('returns orange for 50-70%', () {
        final color = AppColors.resistanceBandColor(50);
        expect(color, isNot(AppColors.hotPink));
        expect(color, isNot(AppColors.red));
      });

      test('returns deep orange-red for 75-90%', () {
        final color = AppColors.resistanceBandColor(80);
        expect(color, isNot(AppColors.neonCyan));
      });

      test('returns red for 95-100%', () {
        expect(AppColors.resistanceBandColor(95), AppColors.red);
        expect(AppColors.resistanceBandColor(100), AppColors.red);
      });
    });

    group('resistanceBands', () {
      test('returns list of colors for low resistance', () {
        final bands = AppColors.resistanceBands(10);
        expect(bands, isNotEmpty);
        expect(bands.first, AppColors.neonCyan);
        expect(bands.last, AppColors.nightPlum);
      });

      test('returns list of colors for high resistance', () {
        final bands = AppColors.resistanceBands(100);
        expect(bands, isNotEmpty);
        expect(bands.first, AppColors.red);
        expect(bands.last, AppColors.nightPlum);
      });

      test('always ends with nightPlum', () {
        for (final level in [0, 25, 50, 75, 100]) {
          final bands = AppColors.resistanceBands(level);
          expect(bands.last, AppColors.nightPlum,
              reason: 'bands for level $level should end with nightPlum');
        }
      });
    });
  });
}
