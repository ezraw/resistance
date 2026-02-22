import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resistance_app/widgets/arcade/resistance_arrow.dart';
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

    testWidgets('displays level 0 correctly', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildWidget(0));
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('displays level 100 correctly', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildWidget(100));
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('contains ResistanceArrow up and down', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildWidget(50));
      final arrows = tester.widgetList<ResistanceArrow>(find.byType(ResistanceArrow));
      final directions = arrows.map((a) => a.direction).toList();
      expect(directions, contains(ArrowDirection.up));
      expect(directions, contains(ArrowDirection.down));
    });

    testWidgets('calls onIncrease when up arrow area is tapped', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      bool increased = false;

      await tester.pumpWidget(
        buildWidget(5, onIncrease: () => increased = true),
      );

      // Tap the up arrow (first ResistanceArrow)
      final upArrow = find.byType(ResistanceArrow).first;
      await tester.tap(upArrow);
      await tester.pump();

      expect(increased, isTrue);
    });

    testWidgets('calls onDecrease when down arrow area is tapped', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      bool decreased = false;

      await tester.pumpWidget(
        buildWidget(5, onDecrease: () => decreased = true),
      );

      // Tap the down arrow (last ResistanceArrow)
      final downArrow = find.byType(ResistanceArrow).last;
      await tester.tap(downArrow);
      await tester.pump();

      expect(decreased, isTrue);
    });

    testWidgets('disabled state shows reduced opacity at level 100', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildWidget(100));

      // Find Opacity widgets — at level 100, the up arrow/badge should be dimmed
      final opacityWidgets = tester.widgetList<Opacity>(find.byType(Opacity));
      final dimmed = opacityWidgets.where((o) => o.opacity < 1.0);
      expect(dimmed, isNotEmpty);
    });

    testWidgets('disabled state shows reduced opacity at level 0', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildWidget(0));

      // Find Opacity widgets — at level 0, the down arrow/badge should be dimmed
      final opacityWidgets = tester.widgetList<Opacity>(find.byType(Opacity));
      final dimmed = opacityWidgets.where((o) => o.opacity < 1.0);
      expect(dimmed, isNotEmpty);
    });
  });
}
