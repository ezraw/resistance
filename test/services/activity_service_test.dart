import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:resistance_app/models/activity.dart';
import 'package:resistance_app/models/activity_sample.dart';
import 'package:resistance_app/services/activity_service.dart';

void main() {
  // Initialize sqflite_common_ffi for desktop testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late ActivityService service;

  setUp(() async {
    // Use in-memory database for each test
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

  Activity createTestActivity({
    DateTime? startedAt,
    int durationSeconds = 1800,
    int? avgHeartRate,
    int? maxHeartRate,
  }) {
    final now = DateTime.utc(2026, 2, 22, 12, 0, 0);
    return Activity(
      startedAt: startedAt ?? now,
      durationSeconds: durationSeconds,
      avgHeartRate: avgHeartRate,
      maxHeartRate: maxHeartRate,
      source: 'resistance_app',
      createdAt: now,
    );
  }

  group('ActivityService', () {
    test('isInitialized returns true after construction with database', () {
      expect(service.isInitialized, isTrue);
    });

    group('insertWithSamples', () {
      test('inserts activity and returns id', () async {
        final activity = createTestActivity(avgHeartRate: 145, maxHeartRate: 178);
        final id = await service.insertWithSamples(activity, []);
        expect(id, greaterThan(0));
      });

      test('inserts activity with samples in one transaction', () async {
        final now = DateTime.utc(2026, 2, 22, 12, 0, 0);
        final activity = createTestActivity(avgHeartRate: 145);
        final samples = List.generate(
          60,
          (i) => ActivitySample(
            timestamp: now.add(Duration(seconds: i)),
            heartRate: 130 + (i % 20),
          ),
        );

        final id = await service.insertWithSamples(activity, samples);
        expect(id, greaterThan(0));

        final retrieved = await service.getSamples(id);
        expect(retrieved.length, 60);
        expect(retrieved.first.heartRate, 130);
        expect(retrieved.first.activityId, id);
      });
    });

    group('getAll', () {
      test('returns empty list when no activities', () async {
        final result = await service.getAll();
        expect(result, isEmpty);
      });

      test('returns activities ordered by start time descending', () async {
        final t1 = DateTime.utc(2026, 2, 20, 10, 0, 0);
        final t2 = DateTime.utc(2026, 2, 21, 10, 0, 0);
        final t3 = DateTime.utc(2026, 2, 22, 10, 0, 0);

        await service.insertWithSamples(createTestActivity(startedAt: t1), []);
        await service.insertWithSamples(createTestActivity(startedAt: t3), []);
        await service.insertWithSamples(createTestActivity(startedAt: t2), []);

        final result = await service.getAll();
        expect(result.length, 3);
        expect(result[0].startedAt, t3);
        expect(result[1].startedAt, t2);
        expect(result[2].startedAt, t1);
      });

      test('supports pagination with limit and offset', () async {
        for (int i = 0; i < 5; i++) {
          await service.insertWithSamples(
            createTestActivity(
              startedAt: DateTime.utc(2026, 2, 20 + i),
              durationSeconds: (i + 1) * 600,
            ),
            [],
          );
        }

        final page1 = await service.getAll(limit: 2);
        expect(page1.length, 2);

        final page2 = await service.getAll(limit: 2, offset: 2);
        expect(page2.length, 2);

        final page3 = await service.getAll(limit: 2, offset: 4);
        expect(page3.length, 1);
      });
    });

    group('getById', () {
      test('returns activity when found', () async {
        final activity = createTestActivity(avgHeartRate: 160);
        final id = await service.insertWithSamples(activity, []);

        final result = await service.getById(id);
        expect(result, isNotNull);
        expect(result!.id, id);
        expect(result.avgHeartRate, 160);
      });

      test('returns null when not found', () async {
        final result = await service.getById(999);
        expect(result, isNull);
      });
    });

    group('getSamples', () {
      test('returns samples ordered by timestamp', () async {
        final now = DateTime.utc(2026, 2, 22, 12, 0, 0);
        final activity = createTestActivity();
        final samples = [
          ActivitySample(timestamp: now.add(const Duration(seconds: 2)), heartRate: 142),
          ActivitySample(timestamp: now, heartRate: 140),
          ActivitySample(timestamp: now.add(const Duration(seconds: 1)), heartRate: 141),
        ];

        final id = await service.insertWithSamples(activity, samples);
        final result = await service.getSamples(id);

        expect(result.length, 3);
        expect(result[0].heartRate, 140);
        expect(result[1].heartRate, 141);
        expect(result[2].heartRate, 142);
      });

      test('returns empty list for activity with no samples', () async {
        final id = await service.insertWithSamples(createTestActivity(), []);
        final result = await service.getSamples(id);
        expect(result, isEmpty);
      });
    });

    group('delete', () {
      test('removes activity', () async {
        final id = await service.insertWithSamples(createTestActivity(), []);
        expect(await service.count(), 1);

        await service.delete(id);
        expect(await service.count(), 0);
      });

      test('cascades delete to samples', () async {
        final now = DateTime.utc(2026, 2, 22, 12, 0, 0);
        final samples = [
          ActivitySample(timestamp: now, heartRate: 140),
          ActivitySample(timestamp: now.add(const Duration(seconds: 1)), heartRate: 141),
        ];
        final id = await service.insertWithSamples(createTestActivity(), samples);

        // Verify samples exist
        expect((await service.getSamples(id)).length, 2);

        await service.delete(id);

        // Samples should be gone too
        expect((await service.getSamples(id)).length, 0);
      });
    });

    group('count', () {
      test('returns 0 for empty database', () async {
        expect(await service.count(), 0);
      });

      test('returns correct count after inserts', () async {
        await service.insertWithSamples(createTestActivity(), []);
        await service.insertWithSamples(createTestActivity(), []);
        await service.insertWithSamples(createTestActivity(), []);
        expect(await service.count(), 3);
      });

      test('decrements after delete', () async {
        final id = await service.insertWithSamples(createTestActivity(), []);
        await service.insertWithSamples(createTestActivity(), []);
        expect(await service.count(), 2);

        await service.delete(id);
        expect(await service.count(), 1);
      });
    });
  });
}
