import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resistance_app/painters/background_band_painter.dart';
import 'package:resistance_app/theme/app_colors.dart';

void main() {
  group('BackgroundBandPainter', () {
    test('shouldRepaint returns true when colors change', () {
      final a = BackgroundBandPainter(
        bandColors: [AppColors.hotPink, AppColors.nightPlum],
      );
      final b = BackgroundBandPainter(
        bandColors: [AppColors.neonCyan, AppColors.nightPlum],
      );
      expect(a.shouldRepaint(b), isTrue);
    });

    test('shouldRepaint returns false when colors are the same', () {
      final a = BackgroundBandPainter(
        bandColors: [AppColors.hotPink, AppColors.nightPlum],
      );
      final b = BackgroundBandPainter(
        bandColors: [AppColors.hotPink, AppColors.nightPlum],
      );
      expect(a.shouldRepaint(b), isFalse);
    });

    test('shouldRepaint returns true when band count changes', () {
      final a = BackgroundBandPainter(
        bandColors: [AppColors.hotPink],
      );
      final b = BackgroundBandPainter(
        bandColors: [AppColors.hotPink, AppColors.nightPlum],
      );
      expect(a.shouldRepaint(b), isTrue);
    });

    testWidgets('renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CustomPaint(
            painter: BackgroundBandPainter(
              bandColors: AppColors.resistanceBands(50),
            ),
            size: const Size(400, 800),
          ),
        ),
      ));
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
