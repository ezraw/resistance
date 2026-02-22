import 'package:flutter_test/flutter_test.dart';
import 'package:resistance_app/painters/hr_zone_chart_painter.dart';

void main() {
  group('HrZoneData', () {
    group('fromHeartRates', () {
      test('classifies all zones correctly with default maxHr', () {
        // maxHr = 190 by default
        // Zone boundaries: 50%=95, 60%=114, 70%=133, 80%=152, 90%=171
        final heartRates = [
          100, // Z1: 52.6%
          120, // Z2: 63.2%
          140, // Z3: 73.7%
          160, // Z4: 84.2%
          180, // Z5: 94.7%
        ];

        final data = HrZoneData.fromHeartRates(heartRates);

        expect(data.zoneSeconds[0], 1); // Z1
        expect(data.zoneSeconds[1], 1); // Z2
        expect(data.zoneSeconds[2], 1); // Z3
        expect(data.zoneSeconds[3], 1); // Z4
        expect(data.zoneSeconds[4], 1); // Z5
      });

      test('handles boundary values correctly', () {
        // With maxHr = 200: 60%=120, 70%=140, 80%=160, 90%=180
        final heartRates = [
          119, // Z1: just below 60%
          120, // Z2: exactly 60%
          139, // Z2: just below 70%
          140, // Z3: exactly 70%
          159, // Z3: just below 80%
          160, // Z4: exactly 80%
          179, // Z4: just below 90%
          180, // Z5: exactly 90%
          200, // Z5: 100%
        ];

        final data = HrZoneData.fromHeartRates(heartRates, maxHr: 200);

        expect(data.zoneSeconds[0], 1); // Z1: 119
        expect(data.zoneSeconds[1], 2); // Z2: 120, 139
        expect(data.zoneSeconds[2], 2); // Z3: 140, 159
        expect(data.zoneSeconds[3], 2); // Z4: 160, 179
        expect(data.zoneSeconds[4], 2); // Z5: 180, 200
      });

      test('ignores zero and negative values', () {
        final heartRates = [0, -1, 140, 0];
        final data = HrZoneData.fromHeartRates(heartRates);

        expect(data.totalSeconds, 1);
      });

      test('handles empty list', () {
        final data = HrZoneData.fromHeartRates([]);
        expect(data.isEmpty, isTrue);
        expect(data.totalSeconds, 0);
      });

      test('accepts custom maxHr', () {
        // maxHr = 160, so 90% = 144
        final heartRates = [145, 150, 155, 160];
        final data = HrZoneData.fromHeartRates(heartRates, maxHr: 160);

        expect(data.zoneSeconds[4], 4); // All in Z5 (peak)
      });
    });

    group('computed properties', () {
      test('totalSeconds sums all zones', () {
        const data = HrZoneData([10, 20, 30, 15, 5]);
        expect(data.totalSeconds, 80);
      });

      test('maxZoneSeconds finds largest zone', () {
        const data = HrZoneData([10, 20, 30, 15, 5]);
        expect(data.maxZoneSeconds, 30);
      });

      test('isEmpty is true when all zeros', () {
        const data = HrZoneData([0, 0, 0, 0, 0]);
        expect(data.isEmpty, isTrue);
      });

      test('isEmpty is false when any zone has data', () {
        const data = HrZoneData([0, 0, 1, 0, 0]);
        expect(data.isEmpty, isFalse);
      });
    });
  });

  group('HrZone', () {
    test('has 5 zones', () {
      expect(HrZone.zones.length, 5);
    });

    test('zones cover 50-100% range', () {
      expect(HrZone.zones.first.minPercent, 0.50);
      expect(HrZone.zones.last.maxPercent, 1.00);
    });

    test('zone numbers are sequential 1-5', () {
      for (int i = 0; i < 5; i++) {
        expect(HrZone.zones[i].number, i + 1);
      }
    });
  });

  group('HrZoneChartPainter', () {
    test('shouldRepaint returns true for different data', () {
      final p1 = HrZoneChartPainter(data: const HrZoneData([1, 2, 3, 4, 5]));
      final p2 = HrZoneChartPainter(data: const HrZoneData([5, 4, 3, 2, 1]));
      // Different list instances with different values
      expect(p1.shouldRepaint(p2), isTrue);
    });
  });
}
