import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resistance_app/widgets/app_top_bar.dart';
import 'package:resistance_app/widgets/arcade/arcade_badge.dart';

void main() {
  group('AppTopBar', () {
    testWidgets('renders YOU badge', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppTopBar(onYouTap: () {}),
        ),
      ));

      expect(find.text('YOU'), findsOneWidget);
    });

    testWidgets('renders left badge when provided', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppTopBar(
            leftBadge: const ArcadeBadge(text: 'CONNECTED'),
            onYouTap: () {},
          ),
        ),
      ));

      expect(find.text('CONNECTED'), findsOneWidget);
      expect(find.text('YOU'), findsOneWidget);
    });

    testWidgets('renders SizedBox.shrink when no left badge', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppTopBar(onYouTap: () {}),
        ),
      ));

      // Should still render without error
      expect(find.byType(AppTopBar), findsOneWidget);
    });

    testWidgets('YOU badge fires onYouTap callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppTopBar(onYouTap: () => tapped = true),
        ),
      ));

      await tester.tap(find.text('YOU'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
