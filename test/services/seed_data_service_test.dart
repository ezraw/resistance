import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:resistance_app/services/activity_service.dart';
import 'package:resistance_app/services/seed_data_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late ActivityService service;

  setUp(() async {
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
          await db.execute(
            'CREATE INDEX idx_activities_started_at ON activities(started_at DESC)',
          );
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
          await db.execute(
            'CREATE INDEX idx_samples_activity_id ON activity_samples(activity_id)',
          );
          await db.execute(
            'CREATE INDEX idx_samples_timestamp ON activity_samples(activity_id, timestamp)',
          );
        },
      ),
    );
    service = ActivityService(database: db);
  });

  tearDown(() async {
    await service.dispose();
  });

  group('SeedDataService', () {
    test('seed creates 8 activities', () async {
      final count = await SeedDataService.seed(service);
      expect(count, 8);
      expect(await service.count(), 8);
    });

    test('activities are ordered newest first', () async {
      await SeedDataService.seed(service);
      final activities = await service.getAll();
      expect(activities.length, 8);

      for (int i = 0; i < activities.length - 1; i++) {
        expect(
          activities[i].startedAt.isAfter(activities[i + 1].startedAt),
          isTrue,
          reason:
              'Activity $i (${activities[i].startedAt}) should be after '
              'activity ${i + 1} (${activities[i + 1].startedAt})',
        );
      }
    });

    test('7 of 8 activities have HR data, 1 has none', () async {
      await SeedDataService.seed(service);
      final activities = await service.getAll();

      int withHr = 0;
      int withoutHr = 0;
      for (final activity in activities) {
        if (activity.avgHeartRate != null) {
          withHr++;
        } else {
          withoutHr++;
        }
      }

      expect(withHr, 7);
      expect(withoutHr, 1);
    });

    test('HR samples fall in realistic BPM range (60-200)', () async {
      await SeedDataService.seed(service);
      final activities = await service.getAll();

      for (final activity in activities) {
        final samples = await service.getSamples(activity.id!);
        for (final sample in samples) {
          if (sample.heartRate != null) {
            expect(
              sample.heartRate,
              inInclusiveRange(60, 200),
              reason:
                  'HR sample ${sample.heartRate} out of range for '
                  'activity ${activity.id}',
            );
          }
        }
      }
    });

    test('activity without HR has no samples', () async {
      await SeedDataService.seed(service);
      final activities = await service.getAll();
      final noHr = activities.firstWhere((a) => a.avgHeartRate == null);
      final samples = await service.getSamples(noHr.id!);
      expect(samples, isEmpty);
    });

    test('activities with HR have per-second samples matching duration',
        () async {
      await SeedDataService.seed(service);
      final activities = await service.getAll();

      for (final activity in activities) {
        if (activity.avgHeartRate != null) {
          final samples = await service.getSamples(activity.id!);
          expect(
            samples.length,
            activity.durationSeconds,
            reason:
                'Activity ${activity.id} should have '
                '${activity.durationSeconds} samples but has ${samples.length}',
          );
        }
      }
    });

    test('seeding twice creates 16 total (no constraint violations)', () async {
      await SeedDataService.seed(service);
      await SeedDataService.seed(service);
      expect(await service.count(), 16);
    });

    test('seed returns count of created activities', () async {
      final count = await SeedDataService.seed(service);
      expect(count, 8);
    });

    test('avgHeartRate and maxHeartRate computed from samples', () async {
      await SeedDataService.seed(service);
      final activities = await service.getAll();

      for (final activity in activities) {
        if (activity.avgHeartRate != null) {
          final samples = await service.getSamples(activity.id!);
          final hrs = samples.map((s) => s.heartRate!).toList();
          final expectedAvg = (hrs.reduce((a, b) => a + b) / hrs.length).round();
          final expectedMax = hrs.reduce((a, b) => a > b ? a : b);

          expect(activity.avgHeartRate, expectedAvg);
          expect(activity.maxHeartRate, expectedMax);
        }
      }
    });
  });
}
