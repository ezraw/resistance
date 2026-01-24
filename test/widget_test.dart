import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:resistance_app/widgets/resistance_control.dart';

void main() {
  group('ResistanceControl Widget', () {
    // Helper to build widget
    Widget buildWidget(int level, {VoidCallback? onIncrease, VoidCallback? onDecrease}) {
      return MaterialApp(
        home: Scaffold(
          body: ResistanceControl(
            currentLevel: level,
            onIncrease: onIncrease ?? () {},
            onDecrease: onDecrease ?? () {},
          ),
        ),
      );
    }

    testWidgets('displays current level', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildWidget(5));
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('displays level 1 correctly', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildWidget(1));
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('displays level 10 correctly', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildWidget(10));
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('calls onIncrease when up arrow is tapped', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      bool increased = false;

      await tester.pumpWidget(
        buildWidget(5, onIncrease: () => increased = true),
      );

      // Find the up caret icon and tap it
      final upArrow = find.byWidgetPredicate(
        (widget) => widget is FaIcon && widget.icon == FontAwesomeIcons.caretUp,
      );
      await tester.tap(upArrow);
      await tester.pump();

      expect(increased, isTrue);
    });

    testWidgets('calls onDecrease when down arrow is tapped', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      bool decreased = false;

      await tester.pumpWidget(
        buildWidget(5, onDecrease: () => decreased = true),
      );

      // Find the down caret icon and tap it
      final downArrow = find.byWidgetPredicate(
        (widget) => widget is FaIcon && widget.icon == FontAwesomeIcons.caretDown,
      );
      await tester.tap(downArrow);
      await tester.pump();

      expect(decreased, isTrue);
    });

    testWidgets('does not call onIncrease at level 10', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      bool increased = false;

      await tester.pumpWidget(
        buildWidget(10, onIncrease: () => increased = true),
      );

      final upArrow = find.byWidgetPredicate(
        (widget) => widget is FaIcon && widget.icon == FontAwesomeIcons.caretUp,
      );
      await tester.tap(upArrow);
      await tester.pump();

      expect(increased, isFalse);
    });

    testWidgets('does not call onDecrease at level 1', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      bool decreased = false;

      await tester.pumpWidget(
        buildWidget(1, onDecrease: () => decreased = true),
      );

      final downArrow = find.byWidgetPredicate(
        (widget) => widget is FaIcon && widget.icon == FontAwesomeIcons.caretDown,
      );
      await tester.tap(downArrow);
      await tester.pump();

      expect(decreased, isFalse);
    });
  });
}
