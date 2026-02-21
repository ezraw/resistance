import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resistance_app/widgets/arcade/pixel_icon.dart';

void main() {
  group('PixelIcon', () {
    for (final type in PixelIconType.values) {
      testWidgets('${type.name} renders at expected size', (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: PixelIcon(type: type, size: 32),
          ),
        ));

        final sizedBox = tester.widget<SizedBox>(
          find.descendant(
            of: find.byType(PixelIcon),
            matching: find.byType(SizedBox),
          ),
        );
        expect(sizedBox.width, 32);
        expect(sizedBox.height, 32);
      });
    }

    testWidgets('renders with default size 24', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: PixelIcon.heart(),
        ),
      ));

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(PixelIcon),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.width, 24);
      expect(sizedBox.height, 24);
    });

    testWidgets('named constructors create correct types', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              PixelIcon.upArrow(),
              PixelIcon.downArrow(),
              PixelIcon.heart(),
              PixelIcon.play(),
              PixelIcon.pause(),
              PixelIcon.stop(),
              PixelIcon.restart(),
              PixelIcon.stopwatch(),
              PixelIcon.warning(),
              PixelIcon.bluetooth(),
              PixelIcon.close(),
              PixelIcon.check(),
            ],
          ),
        ),
      ));
      // All 12 should render
      expect(find.byType(PixelIcon), findsNWidgets(12));
    });
  });
}
