import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resistance_app/widgets/heart_rate_display.dart';

void main() {
  group('HeartRateDisplay Widget', () {
    Widget buildWidget({
      int? bpm,
      bool isConnected = false,
      VoidCallback? onTap,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: HeartRateDisplay(
            bpm: bpm,
            isConnected: isConnected,
            onTap: onTap,
          ),
        ),
      );
    }

    testWidgets('displays "--" when bpm is null', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(bpm: null));
      expect(find.text('--'), findsOneWidget);
    });

    testWidgets('displays "--" when bpm is 0', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(bpm: 0));
      expect(find.text('--'), findsOneWidget);
    });

    testWidgets('displays heart rate value when valid', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(bpm: 120));
      expect(find.text('120'), findsOneWidget);
    });

    testWidgets('displays "bpm" label', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(bpm: 120));
      expect(find.text('bpm'), findsOneWidget);
    });

    testWidgets('displays heart icon', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(bpm: 120));
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(buildWidget(
        bpm: 120,
        onTap: () => tapped = true,
      ));

      await tester.tap(find.byType(HeartRateDisplay));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('is tappable even when disconnected', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(buildWidget(
        bpm: null,
        isConnected: false,
        onTap: () => tapped = true,
      ));

      await tester.tap(find.byType(HeartRateDisplay));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('displays various heart rates correctly', (WidgetTester tester) async {
      // Test common heart rate values
      for (final hr in [60, 100, 150, 180, 200]) {
        await tester.pumpWidget(buildWidget(bpm: hr));
        expect(find.text('$hr'), findsOneWidget);
      }
    });
  });
}
