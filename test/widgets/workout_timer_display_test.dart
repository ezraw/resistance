import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resistance_app/widgets/workout_timer_display.dart';

void main() {
  group('WorkoutTimerDisplay Widget', () {
    Widget buildWidget(Duration elapsed) {
      return MaterialApp(
        home: Scaffold(
          body: WorkoutTimerDisplay(elapsed: elapsed),
        ),
      );
    }

    testWidgets('displays zero time correctly', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(Duration.zero));
      expect(find.text('00:00'), findsOneWidget);
    });

    testWidgets('displays seconds correctly', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(const Duration(seconds: 45)));
      expect(find.text('00:45'), findsOneWidget);
    });

    testWidgets('displays minutes correctly', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(const Duration(minutes: 5, seconds: 30)));
      expect(find.text('05:30'), findsOneWidget);
    });

    testWidgets('displays hours when present', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(const Duration(hours: 1, minutes: 23, seconds: 45)));
      expect(find.text('01:23:45'), findsOneWidget);
    });

    testWidgets('pads single digits with zeros', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(const Duration(minutes: 1, seconds: 5)));
      expect(find.text('01:05'), findsOneWidget);
    });

    testWidgets('handles 59 minutes correctly', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(const Duration(minutes: 59, seconds: 59)));
      expect(find.text('59:59'), findsOneWidget);
    });

    testWidgets('handles multi-hour durations', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(const Duration(hours: 10, minutes: 5, seconds: 3)));
      expect(find.text('10:05:03'), findsOneWidget);
    });

    testWidgets('uses custom style when provided', (WidgetTester tester) async {
      const customStyle = TextStyle(fontSize: 48, color: Colors.red);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WorkoutTimerDisplay(
              elapsed: Duration(minutes: 5),
              style: customStyle,
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('05:00'));
      expect(textWidget.style?.fontSize, 48);
      expect(textWidget.style?.color, Colors.red);
    });
  });
}
