import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resistance_app/widgets/arcade/arcade_button.dart';

void main() {
  group('ArcadeButton', () {
    Widget buildWidget({
      String label = 'Start',
      VoidCallback? onTap,
      bool enabled = true,
      ArcadeButtonScheme scheme = ArcadeButtonScheme.gold,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ArcadeButton(
            label: label,
            onTap: onTap ?? () {},
            enabled: enabled,
            scheme: scheme,
          ),
        ),
      );
    }

    testWidgets('renders label in uppercase', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(label: 'start'));
      expect(find.text('START'), findsOneWidget);
    });

    testWidgets('fires tap callback when enabled', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(buildWidget(onTap: () => tapped = true));
      await tester.tap(find.byType(ArcadeButton));
      expect(tapped, isTrue);
    });

    testWidgets('does not fire tap when disabled', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildWidget(onTap: () => tapped = true, enabled: false),
      );
      await tester.tap(find.byType(ArcadeButton));
      expect(tapped, isFalse);
    });

    testWidgets('shows reduced opacity when disabled', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(enabled: false));
      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 0.4);
    });

    testWidgets('renders with different schemes', (WidgetTester tester) async {
      for (final scheme in ArcadeButtonScheme.values) {
        await tester.pumpWidget(buildWidget(label: 'Test', scheme: scheme));
        expect(find.text('TEST'), findsOneWidget);
      }
    });
  });
}
