import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resistance_app/painters/particle_painter.dart';

void main() {
  group('ParticlePainter', () {
    test('shouldRepaint returns true when time changes', () {
      final a = ParticlePainter(time: 0.0);
      final b = ParticlePainter(time: 1.0);
      expect(a.shouldRepaint(b), isTrue);
    });

    test('shouldRepaint returns false when time is the same', () {
      final a = ParticlePainter(time: 1.0);
      final b = ParticlePainter(time: 1.0);
      expect(a.shouldRepaint(b), isFalse);
    });

    testWidgets('renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CustomPaint(
            painter: ParticlePainter(time: 0),
            size: const Size(400, 800),
          ),
        ),
      ));
      expect(find.byType(CustomPaint), findsWidgets);
    });

    test('default particle count is 80', () {
      final painter = ParticlePainter(time: 0);
      expect(painter.particleCount, 80);
    });
  });
}
