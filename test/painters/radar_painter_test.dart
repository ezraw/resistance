import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resistance_app/painters/radar_painter.dart';

void main() {
  group('RadarPainter', () {
    test('shouldRepaint returns true when sweep angle changes', () {
      final a = RadarPainter(sweepAngle: 0.0, ringPhase: 0.0);
      final b = RadarPainter(sweepAngle: 0.5, ringPhase: 0.0);
      expect(a.shouldRepaint(b), isTrue);
    });

    test('shouldRepaint returns true when ring phase changes', () {
      final a = RadarPainter(sweepAngle: 0.0, ringPhase: 0.0);
      final b = RadarPainter(sweepAngle: 0.0, ringPhase: 0.5);
      expect(a.shouldRepaint(b), isTrue);
    });

    test('shouldRepaint returns false when values are the same', () {
      final a = RadarPainter(sweepAngle: 0.5, ringPhase: 0.3);
      final b = RadarPainter(sweepAngle: 0.5, ringPhase: 0.3);
      expect(a.shouldRepaint(b), isFalse);
    });

    testWidgets('renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 200,
            child: CustomPaint(
              painter: RadarPainter(sweepAngle: 0.5, ringPhase: 0.3),
            ),
          ),
        ),
      ));
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
