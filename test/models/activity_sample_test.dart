import 'package:flutter_test/flutter_test.dart';
import 'package:resistance_app/models/activity_sample.dart';

void main() {
  group('ActivitySample Model', () {
    final now = DateTime.utc(2026, 2, 22, 12, 0, 0);

    group('toMap / fromMap roundtrip', () {
      test('preserves all fields', () {
        final sample = ActivitySample(
          id: 1,
          activityId: 10,
          timestamp: now,
          heartRate: 145,
          watts: 200,
          cadence: 85,
          speedMph: 18.5,
          resistance: 50,
        );

        final map = sample.toMap();
        final restored = ActivitySample.fromMap(map);

        expect(restored.id, 1);
        expect(restored.activityId, 10);
        expect(restored.timestamp, now);
        expect(restored.heartRate, 145);
        expect(restored.watts, 200);
        expect(restored.cadence, 85);
        expect(restored.speedMph, 18.5);
        expect(restored.resistance, 50);
      });

      test('handles null optional fields', () {
        final sample = ActivitySample(timestamp: now);
        final map = sample.toMap();
        final restored = ActivitySample.fromMap(map);

        expect(restored.id, isNull);
        expect(restored.activityId, isNull);
        expect(restored.heartRate, isNull);
        expect(restored.watts, isNull);
        expect(restored.cadence, isNull);
        expect(restored.speedMph, isNull);
        expect(restored.resistance, isNull);
      });

      test('omits id and activity_id when null', () {
        final sample = ActivitySample(timestamp: now);
        final map = sample.toMap();
        expect(map.containsKey('id'), isFalse);
        expect(map.containsKey('activity_id'), isFalse);
      });
    });

    group('toMap serialization', () {
      test('serializes timestamp as ISO 8601 UTC', () {
        final sample = ActivitySample(timestamp: now);
        final map = sample.toMap();
        expect(map['timestamp'], contains('T'));
        expect(map['timestamp'], endsWith('Z'));
      });
    });
  });
}
