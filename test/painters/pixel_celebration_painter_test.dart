import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resistance_app/painters/pixel_celebration_painter.dart';

void main() {
  group('PixelCelebrationPainter', () {
    test('shouldRepaint returns true when progress changes', () {
      final a = PixelCelebrationPainter(progress: 0.0);
      final b = PixelCelebrationPainter(progress: 0.5);
      expect(a.shouldRepaint(b), isTrue);
    });

    test('shouldRepaint returns false when progress is the same', () {
      final a = PixelCelebrationPainter(progress: 0.5);
      final b = PixelCelebrationPainter(progress: 0.5);
      expect(a.shouldRepaint(b), isFalse);
    });

    testWidgets('renders without error at start', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 600,
            child: CustomPaint(
              painter: PixelCelebrationPainter(progress: 0.0),
            ),
          ),
        ),
      ));
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders without error at midpoint', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 600,
            child: CustomPaint(
              painter: PixelCelebrationPainter(progress: 0.5),
            ),
          ),
        ),
      ));
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders without error at end', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 600,
            child: CustomPaint(
              painter: PixelCelebrationPainter(progress: 1.0),
            ),
          ),
        ),
      ));
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('handles zero-size canvas', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 0,
            height: 0,
            child: CustomPaint(
              painter: PixelCelebrationPainter(progress: 0.5),
            ),
          ),
        ),
      ));
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
