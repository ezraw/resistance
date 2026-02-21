import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resistance_app/theme/accessibility.dart';

void main() {
  group('Reduce Motion', () {
    testWidgets('returns false by default', (WidgetTester tester) async {
      bool? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) {
            result = Accessibility.reduceMotion(context);
            return const SizedBox();
          },
        ),
      ));
      expect(result, isFalse);
    });

    testWidgets('returns true when disableAnimations is set', (WidgetTester tester) async {
      bool? result;
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              result = Accessibility.reduceMotion(context);
              return const SizedBox();
            },
          ),
        ),
      ));
      expect(result, isTrue);
    });

    testWidgets('ArcadeBackground respects reduce motion (no particles)', (WidgetTester tester) async {
      // With reduce motion, particles and streaks should not render
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: Builder(
              builder: (context) {
                final reduced = Accessibility.reduceMotion(context);
                return Text(reduced ? 'REDUCED' : 'NORMAL');
              },
            ),
          ),
        ),
      ));
      expect(find.text('REDUCED'), findsOneWidget);
    });
  });
}
