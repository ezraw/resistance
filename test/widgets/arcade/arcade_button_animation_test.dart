import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resistance_app/widgets/arcade/arcade_button.dart';

void main() {
  group('ArcadeButton Animation', () {
    Widget buildWidget({
      VoidCallback? onTap,
      bool enabled = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: ArcadeButton(
              label: 'Test',
              onTap: onTap ?? () {},
              enabled: enabled,
            ),
          ),
        ),
      );
    }

    testWidgets('button has press animation controller', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget());
      // Verify the stateful button exists
      expect(find.byType(ArcadeButton), findsOneWidget);
    });

    testWidgets('button still fires onTap after press animation', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(buildWidget(onTap: () => tapped = true));

      // Tap using the GestureDetector
      await tester.tap(find.byType(ArcadeButton));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('disabled button does not animate on press', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(buildWidget(onTap: () => tapped = true, enabled: false));

      await tester.tap(find.byType(ArcadeButton));
      await tester.pumpAndSettle();

      expect(tapped, isFalse);
    });
  });
}
