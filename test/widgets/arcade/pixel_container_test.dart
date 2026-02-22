import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resistance_app/painters/pixel_border_painter.dart';
import 'package:resistance_app/widgets/arcade/pixel_container.dart';

void main() {
  group('PixelContainer', () {
    testWidgets('renders child widget', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: PixelContainer(
            fillColor: Colors.black,
            borderColor: Colors.white,
            child: Text('Hello'),
          ),
        ),
      ));
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('contains CustomPaint with PixelBorderPainter', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: PixelContainer(
            fillColor: Colors.black,
            borderColor: Colors.red,
            borderWidth: 3,
            notchSize: 4,
            child: Text('Test'),
          ),
        ),
      ));

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(PixelContainer),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(customPaint.painter, isA<PixelBorderPainter>());
      final painter = customPaint.painter as PixelBorderPainter;
      expect(painter.fillColor, Colors.black);
      expect(painter.borderColor, Colors.red);
      expect(painter.borderWidth, 3);
      expect(painter.notchSize, 4);
    });

    testWidgets('contains ClipPath for child clipping', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: PixelContainer(
            fillColor: Colors.black,
            borderColor: Colors.white,
            child: Text('Clipped'),
          ),
        ),
      ));
      expect(find.byType(ClipPath), findsOneWidget);
    });

    testWidgets('applies padding to child', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: PixelContainer(
            fillColor: Colors.black,
            borderColor: Colors.white,
            padding: EdgeInsets.all(20),
            child: Text('Padded'),
          ),
        ),
      ));
      final padding = tester.widget<Padding>(find.byType(Padding).last);
      expect(padding.padding, const EdgeInsets.all(20));
    });

    testWidgets('steps parameter is forwarded to PixelBorderPainter',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: PixelContainer(
            fillColor: Colors.black,
            borderColor: Colors.white,
            steps: 3,
            child: Text('Steps'),
          ),
        ),
      ));

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(PixelContainer),
          matching: find.byType(CustomPaint),
        ),
      );
      final painter = customPaint.painter as PixelBorderPainter;
      expect(painter.steps, 3);
    });
  });
}
