import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resistance_app/painters/pixel_border_painter.dart';
import 'package:resistance_app/theme/app_colors.dart';
import 'package:resistance_app/widgets/arcade/arcade_panel.dart';

void main() {
  group('ArcadePanel', () {
    Widget buildWidget({
      Color borderColor = AppColors.magenta,
      Widget? child,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ArcadePanel(
            borderColor: borderColor,
            child: child ?? const Text('Test'),
          ),
        ),
      );
    }

    testWidgets('renders child', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(child: const Text('Hello')));
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('renders with PixelBorderPainter', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget());
      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(ArcadePanel),
          matching: find.byType(CustomPaint),
        ),
      );
      final painter = customPaint.painter as PixelBorderPainter;
      expect(painter.fillColor, AppColors.nightPlum);
      expect(painter.borderColor, AppColors.magenta);
      expect(painter.borderWidth, 6);
      expect(painter.notchSize, 4);
    });

    testWidgets('renders with custom border color', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(borderColor: AppColors.neonCyan));
      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(ArcadePanel),
          matching: find.byType(CustomPaint),
        ),
      );
      final painter = customPaint.painter as PixelBorderPainter;
      expect(painter.borderColor, AppColors.neonCyan);
    });

    testWidgets('secondary variant renders with thinner border', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ArcadePanel.secondary(
            child: Text('Secondary'),
          ),
        ),
      ));
      expect(find.text('Secondary'), findsOneWidget);
      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(ArcadePanel),
          matching: find.byType(CustomPaint),
        ),
      );
      final painter = customPaint.painter as PixelBorderPainter;
      expect(painter.borderWidth, 2);
      expect(painter.notchSize, 3);
    });
  });
}
