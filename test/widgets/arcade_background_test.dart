import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resistance_app/widgets/arcade_background.dart';

void main() {
  group('ArcadeBackground', () {
    testWidgets('builds successfully', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ArcadeBackground(
            resistanceLevel: 50,
            child: Text('Content'),
          ),
        ),
      ));
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('accepts resistance level 0', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ArcadeBackground(
            resistanceLevel: 0,
            child: SizedBox(),
          ),
        ),
      ));
      expect(find.byType(ArcadeBackground), findsOneWidget);
    });

    testWidgets('accepts resistance level 100', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ArcadeBackground(
            resistanceLevel: 100,
            child: SizedBox(),
          ),
        ),
      ));
      expect(find.byType(ArcadeBackground), findsOneWidget);
    });

    testWidgets('renders with isActive flag', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ArcadeBackground(
            resistanceLevel: 50,
            isActive: true,
            child: SizedBox(),
          ),
        ),
      ));
      expect(find.byType(ArcadeBackground), findsOneWidget);
    });
  });
}
