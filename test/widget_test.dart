import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resistance_app/widgets/resistance_control.dart';

void main() {
  group('ResistanceControl Widget', () {
    testWidgets('displays current level', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResistanceControl(
              currentLevel: 5,
              onIncrease: () {},
              onDecrease: () {},
            ),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('displays different levels correctly', (WidgetTester tester) async {
      for (int level = 1; level <= 10; level++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResistanceControl(
                currentLevel: level,
                onIncrease: () {},
                onDecrease: () {},
              ),
            ),
          ),
        );

        expect(find.text('$level'), findsOneWidget);
      }
    });

    testWidgets('calls onIncrease when up arrow is tapped', (WidgetTester tester) async {
      bool increased = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResistanceControl(
              currentLevel: 5,
              onIncrease: () => increased = true,
              onDecrease: () {},
            ),
          ),
        ),
      );

      // Find the up arrow icon and tap it
      final upArrow = find.byIcon(Icons.keyboard_arrow_up);
      await tester.tap(upArrow);
      await tester.pump();

      expect(increased, isTrue);
    });

    testWidgets('calls onDecrease when down arrow is tapped', (WidgetTester tester) async {
      bool decreased = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResistanceControl(
              currentLevel: 5,
              onIncrease: () {},
              onDecrease: () => decreased = true,
            ),
          ),
        ),
      );

      // Find the down arrow icon and tap it
      final downArrow = find.byIcon(Icons.keyboard_arrow_down);
      await tester.tap(downArrow);
      await tester.pump();

      expect(decreased, isTrue);
    });

    testWidgets('does not call onIncrease at level 10', (WidgetTester tester) async {
      bool increased = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResistanceControl(
              currentLevel: 10,
              onIncrease: () => increased = true,
              onDecrease: () {},
            ),
          ),
        ),
      );

      final upArrow = find.byIcon(Icons.keyboard_arrow_up);
      await tester.tap(upArrow);
      await tester.pump();

      expect(increased, isFalse);
    });

    testWidgets('does not call onDecrease at level 1', (WidgetTester tester) async {
      bool decreased = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResistanceControl(
              currentLevel: 1,
              onIncrease: () {},
              onDecrease: () => decreased = true,
            ),
          ),
        ),
      );

      final downArrow = find.byIcon(Icons.keyboard_arrow_down);
      await tester.tap(downArrow);
      await tester.pump();

      expect(decreased, isFalse);
    });

    testWidgets('does not respond when isUpdating is true', (WidgetTester tester) async {
      bool increased = false;
      bool decreased = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResistanceControl(
              currentLevel: 5,
              onIncrease: () => increased = true,
              onDecrease: () => decreased = true,
              isUpdating: true,
            ),
          ),
        ),
      );

      final upArrow = find.byIcon(Icons.keyboard_arrow_up);
      final downArrow = find.byIcon(Icons.keyboard_arrow_down);

      await tester.tap(upArrow);
      await tester.tap(downArrow);
      await tester.pump();

      expect(increased, isFalse);
      expect(decreased, isFalse);
    });
  });
}
