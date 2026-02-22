import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:resistance_app/services/user_settings_service.dart';
import 'package:resistance_app/screens/user_settings_screen.dart';

void main() {
  late UserSettingsService settingsService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    settingsService = UserSettingsService(prefs);
  });

  group('UserSettingsScreen', () {
    testWidgets('builds successfully with title and back button', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: UserSettingsScreen(userSettingsService: settingsService),
      ));

      expect(find.byType(UserSettingsScreen), findsOneWidget);
      expect(find.text('SETTINGS'), findsOneWidget);
      expect(find.text('BACK'), findsOneWidget);
    });

    testWidgets('shows NOT SET when values are not configured', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: UserSettingsScreen(userSettingsService: settingsService),
      ));

      expect(find.text('NOT SET'), findsNWidgets(2));
      expect(find.text('MAX HEART RATE'), findsOneWidget);
      expect(find.text('FTP'), findsOneWidget);
    });

    testWidgets('shows configured values', (tester) async {
      settingsService.maxHeartRate = 190;
      settingsService.ftp = 250;

      await tester.pumpWidget(MaterialApp(
        home: UserSettingsScreen(userSettingsService: settingsService),
      ));

      expect(find.text('190 BPM'), findsOneWidget);
      expect(find.text('250 W'), findsOneWidget);
    });

    testWidgets('tapping max heart rate row opens edit dialog', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: UserSettingsScreen(userSettingsService: settingsService),
      ));

      await tester.tap(find.text('MAX HEART RATE'));
      await tester.pump();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('SAVE'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);
    });

    testWidgets('tapping FTP row opens edit dialog', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: UserSettingsScreen(userSettingsService: settingsService),
      ));

      await tester.tap(find.text('FTP'));
      await tester.pump();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('saving a valid max heart rate updates the display', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: UserSettingsScreen(userSettingsService: settingsService),
      ));

      await tester.tap(find.text('MAX HEART RATE'));
      await tester.pump();

      await tester.enterText(find.byType(TextField), '185');
      await tester.tap(find.text('SAVE'));
      await tester.pump();

      expect(find.text('185 BPM'), findsOneWidget);
      expect(settingsService.maxHeartRate, 185);
    });

    testWidgets('shows error for out-of-range max heart rate', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: UserSettingsScreen(userSettingsService: settingsService),
      ));

      await tester.tap(find.text('MAX HEART RATE'));
      await tester.pump();

      await tester.enterText(find.byType(TextField), '50');
      await tester.tap(find.text('SAVE'));
      await tester.pump();

      expect(find.text('MUST BE 100-230'), findsOneWidget);
    });

    testWidgets('shows error for empty value', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: UserSettingsScreen(userSettingsService: settingsService),
      ));

      await tester.tap(find.text('MAX HEART RATE'));
      await tester.pump();

      await tester.tap(find.text('SAVE'));
      await tester.pump();

      expect(find.text('ENTER A VALUE'), findsOneWidget);
    });

    testWidgets('CLEAR button removes existing value', (tester) async {
      settingsService.maxHeartRate = 190;

      await tester.pumpWidget(MaterialApp(
        home: UserSettingsScreen(userSettingsService: settingsService),
      ));

      await tester.tap(find.text('MAX HEART RATE'));
      await tester.pump();

      expect(find.text('CLEAR'), findsOneWidget);
      await tester.tap(find.text('CLEAR'));
      await tester.pump();

      expect(settingsService.maxHeartRate, isNull);
    });

    testWidgets('CLEAR button not shown when value is not set', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: UserSettingsScreen(userSettingsService: settingsService),
      ));

      await tester.tap(find.text('MAX HEART RATE'));
      await tester.pump();

      expect(find.text('CLEAR'), findsNothing);
    });

    testWidgets('saving a valid FTP updates the display', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: UserSettingsScreen(userSettingsService: settingsService),
      ));

      await tester.tap(find.text('FTP'));
      await tester.pump();

      await tester.enterText(find.byType(TextField), '200');
      await tester.tap(find.text('SAVE'));
      await tester.pump();

      expect(find.text('200 W'), findsOneWidget);
      expect(settingsService.ftp, 200);
    });

    testWidgets('shows error for out-of-range FTP', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: UserSettingsScreen(userSettingsService: settingsService),
      ));

      await tester.tap(find.text('FTP'));
      await tester.pump();

      await tester.enterText(find.byType(TextField), '600');
      await tester.tap(find.text('SAVE'));
      await tester.pump();

      expect(find.text('MUST BE 50-500'), findsOneWidget);
    });
  });
}
