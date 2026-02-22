import 'package:flutter_test/flutter_test.dart';
import 'package:resistance_app/models/activity.dart';

void main() {
  group('Activity Model', () {
    final now = DateTime.utc(2026, 2, 22, 12, 0, 0);

    Activity createTestActivity({
      int? id,
      int? avgHeartRate,
      int? maxHeartRate,
      double? avgMph,
    }) {
      return Activity(
        id: id,
        startedAt: now,
        durationSeconds: 1800,
        avgHeartRate: avgHeartRate,
        maxHeartRate: maxHeartRate,
        avgMph: avgMph,
        source: 'resistance_app',
        createdAt: now,
      );
    }

    group('toMap / fromMap roundtrip', () {
      test('preserves all fields', () {
        final activity = Activity(
          id: 1,
          startedAt: now,
          durationSeconds: 3600,
          avgHeartRate: 145,
          maxHeartRate: 178,
          avgWatts: 200,
          maxWatts: 350,
          avgMph: 18.5,
          maxMph: 24.0,
          avgCadence: 85,
          avgResistance: 50,
          calories: 500,
          notes: 'Great workout!',
          source: 'resistance_app',
          createdAt: now,
          updatedAt: now,
        );

        final map = activity.toMap();
        final restored = Activity.fromMap(map);

        expect(restored.id, 1);
        expect(restored.startedAt, now);
        expect(restored.durationSeconds, 3600);
        expect(restored.avgHeartRate, 145);
        expect(restored.maxHeartRate, 178);
        expect(restored.avgWatts, 200);
        expect(restored.maxWatts, 350);
        expect(restored.avgMph, 18.5);
        expect(restored.maxMph, 24.0);
        expect(restored.avgCadence, 85);
        expect(restored.avgResistance, 50);
        expect(restored.calories, 500);
        expect(restored.notes, 'Great workout!');
        expect(restored.source, 'resistance_app');
        expect(restored.createdAt, now);
        expect(restored.updatedAt, now);
      });

      test('handles null optional fields', () {
        final activity = createTestActivity();
        final map = activity.toMap();
        final restored = Activity.fromMap(map);

        expect(restored.avgHeartRate, isNull);
        expect(restored.maxHeartRate, isNull);
        expect(restored.avgWatts, isNull);
        expect(restored.maxWatts, isNull);
        expect(restored.avgMph, isNull);
        expect(restored.maxMph, isNull);
        expect(restored.avgCadence, isNull);
        expect(restored.avgResistance, isNull);
        expect(restored.calories, isNull);
        expect(restored.notes, isNull);
        expect(restored.updatedAt, isNull);
      });

      test('omits id when null', () {
        final activity = createTestActivity();
        final map = activity.toMap();
        expect(map.containsKey('id'), isFalse);
      });

      test('includes id when present', () {
        final activity = createTestActivity(id: 42);
        final map = activity.toMap();
        expect(map['id'], 42);
      });
    });

    group('duration getter', () {
      test('converts seconds to Duration', () {
        final activity = createTestActivity();
        expect(activity.duration, const Duration(seconds: 1800));
      });
    });

    group('fromMap with defaults', () {
      test('defaults source to resistance_app when missing', () {
        final map = {
          'started_at': now.toIso8601String(),
          'duration_seconds': 600,
          'created_at': now.toIso8601String(),
        };
        final activity = Activity.fromMap(map);
        expect(activity.source, 'resistance_app');
      });
    });

    group('toMap serialization', () {
      test('serializes dates as ISO 8601 UTC', () {
        final activity = createTestActivity();
        final map = activity.toMap();
        expect(map['started_at'], contains('T'));
        expect(map['started_at'], endsWith('Z'));
      });

      test('serializes durationSeconds as integer', () {
        final activity = createTestActivity();
        final map = activity.toMap();
        expect(map['duration_seconds'], isA<int>());
        expect(map['duration_seconds'], 1800);
      });
    });
  });
}
