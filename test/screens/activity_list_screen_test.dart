import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:resistance_app/services/activity_service.dart';
import 'package:resistance_app/services/user_settings_service.dart';
import 'package:resistance_app/screens/activity_list_screen.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late ActivityService service;
  late UserSettingsService userSettingsService;

  Future<ActivityService> createService() async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE activities (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              started_at TEXT NOT NULL,
              duration_seconds INTEGER NOT NULL,
              avg_heart_rate INTEGER,
              max_heart_rate INTEGER,
              avg_watts INTEGER,
              max_watts INTEGER,
              avg_mph REAL,
              max_mph REAL,
              avg_cadence INTEGER,
              avg_resistance INTEGER,
              calories INTEGER,
              notes TEXT,
              source TEXT DEFAULT 'resistance_app',
              created_at TEXT NOT NULL,
              updated_at TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE activity_samples (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              activity_id INTEGER NOT NULL,
              timestamp TEXT NOT NULL,
              heart_rate INTEGER,
              watts INTEGER,
              cadence INTEGER,
              speed_mph REAL,
              resistance INTEGER,
              FOREIGN KEY (activity_id) REFERENCES activities(id) ON DELETE CASCADE
            )
          ''');
        },
      ),
    );
    return ActivityService(database: db);
  }

  setUp(() async {
    service = await createService();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    userSettingsService = UserSettingsService(prefs);
  });

  tearDown(() async {
    await service.dispose();
  });

  group('ActivityListScreen', () {
    // Note: Full widget tests are limited because ArcadeBackground uses an
    // infinite AnimationController. We verify the widget builds and contains
    // expected structural elements. Async data loading is tested via the
    // ActivityService unit tests.

    testWidgets('builds successfully with title and back button', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ActivityListScreen(
          activityService: service,
          userSettingsService: userSettingsService,
        ),
      ));

      expect(find.byType(ActivityListScreen), findsOneWidget);
      expect(find.text('HISTORY'), findsOneWidget);
      expect(find.text('BACK'), findsOneWidget);
    });
  });
}
