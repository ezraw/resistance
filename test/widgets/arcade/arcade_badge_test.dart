import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resistance_app/painters/pixel_border_painter.dart';
import 'package:resistance_app/widgets/arcade/arcade_badge.dart';
import 'package:resistance_app/widgets/arcade/pixel_icon.dart';

void main() {
  group('ArcadeBadge', () {
    testWidgets('renders text', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ArcadeBadge(text: 'CONNECTED'),
        ),
      ));
      expect(find.text('CONNECTED'), findsOneWidget);
    });

    testWidgets('renders icon and text', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ArcadeBadge(
            icon: PixelIcon.heart(size: 16),
            text: '120',
          ),
        ),
      ));
      expect(find.text('120'), findsOneWidget);
      expect(find.byType(PixelIcon), findsOneWidget);
    });

    testWidgets('fires onTap callback', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ArcadeBadge(
            text: 'TAP ME',
            onTap: () => tapped = true,
          ),
        ),
      ));
      await tester.tap(find.byType(ArcadeBadge));
      expect(tapped, isTrue);
    });

    testWidgets('uses PixelBorderPainter with notchSize 2', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ArcadeBadge(text: 'TEST'),
        ),
      ));
      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(ArcadeBadge),
          matching: find.byType(CustomPaint),
        ),
      );
      final painter = customPaint.painter as PixelBorderPainter;
      expect(painter.notchSize, 2);
      expect(painter.borderWidth, 2);
    });
  });
}
