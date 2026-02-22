import 'package:flutter_test/flutter_test.dart';
import 'package:resistance_app/painters/power_zone_chart_painter.dart';

void main() {
  group('PowerZoneData', () {
    group('fromWatts', () {
      test('classifies all 7 zones correctly with default ftp', () {
        // ftp = 100 by default
        // Z1: <55W, Z2: 55-75W, Z3: 75-90W, Z4: 90-105W,
        // Z5: 105-120W, Z6: 120-150W, Z7: >150W
        final watts = [
          40,  // Z1: 40% of FTP
          65,  // Z2: 65%
          80,  // Z3: 80%
          95,  // Z4: 95%
          110, // Z5: 110%
          130, // Z6: 130%
          160, // Z7: 160%
        ];

        final data = PowerZoneData.fromWatts(watts);

        expect(data.zoneSeconds[0], 1); // Z1
        expect(data.zoneSeconds[1], 1); // Z2
        expect(data.zoneSeconds[2], 1); // Z3
        expect(data.zoneSeconds[3], 1); // Z4
        expect(data.zoneSeconds[4], 1); // Z5
        expect(data.zoneSeconds[5], 1); // Z6
        expect(data.zoneSeconds[6], 1); // Z7
      });

      test('handles boundary values correctly', () {
        // ftp = 200: Z1<110, Z2=110-150, Z3=150-180, Z4=180-210,
        // Z5=210-240, Z6=240-300, Z7>300
        final watts = [
          109, // Z1: just below 55%
          110, // Z2: exactly 55%
          149, // Z2: just below 75%
          150, // Z3: exactly 75%
          179, // Z3: just below 90%
          180, // Z4: exactly 90%
          209, // Z4: just below 105%
          210, // Z5: exactly 105%
          239, // Z5: just below 120%
          240, // Z6: exactly 120%
          299, // Z6: just below 150%
          300, // Z7: exactly 150%
          400, // Z7: 200%
        ];

        final data = PowerZoneData.fromWatts(watts, ftp: 200);

        expect(data.zoneSeconds[0], 1); // Z1: 109
        expect(data.zoneSeconds[1], 2); // Z2: 110, 149
        expect(data.zoneSeconds[2], 2); // Z3: 150, 179
        expect(data.zoneSeconds[3], 2); // Z4: 180, 209
        expect(data.zoneSeconds[4], 2); // Z5: 210, 239
        expect(data.zoneSeconds[5], 2); // Z6: 240, 299
        expect(data.zoneSeconds[6], 2); // Z7: 300, 400
      });

      test('ignores zero and negative values', () {
        final watts = [0, -1, 80, 0, -50];
        final data = PowerZoneData.fromWatts(watts);

        expect(data.totalSeconds, 1);
      });

      test('handles empty list', () {
        final data = PowerZoneData.fromWatts([]);
        expect(data.isEmpty, isTrue);
        expect(data.totalSeconds, 0);
      });

      test('accepts custom ftp parameter', () {
        // ftp = 50, so 150% = 75W
        final watts = [80, 85, 90];
        final data = PowerZoneData.fromWatts(watts, ftp: 50);

        expect(data.zoneSeconds[6], 3); // All in Z7 (neuro)
      });

      test('all zero watts results in empty data', () {
        final data = PowerZoneData.fromWatts([0, 0, 0]);
        expect(data.isEmpty, isTrue);
      });
    });

    group('computed properties', () {
      test('totalSeconds sums all zones', () {
        const data = PowerZoneData([10, 20, 30, 15, 5, 8, 12]);
        expect(data.totalSeconds, 100);
      });

      test('maxZoneSeconds finds largest zone', () {
        const data = PowerZoneData([10, 20, 30, 15, 5, 8, 12]);
        expect(data.maxZoneSeconds, 30);
      });

      test('isEmpty is true when all zeros', () {
        const data = PowerZoneData([0, 0, 0, 0, 0, 0, 0]);
        expect(data.isEmpty, isTrue);
      });

      test('isEmpty is false when any zone has data', () {
        const data = PowerZoneData([0, 0, 0, 1, 0, 0, 0]);
        expect(data.isEmpty, isFalse);
      });
    });
  });

  group('PowerZone', () {
    test('has 7 zones', () {
      expect(PowerZone.zones.length, 7);
    });

    test('zones start at 0% and last zone extends to infinity', () {
      expect(PowerZone.zones.first.minPercent, 0.00);
      expect(PowerZone.zones.last.maxPercent, double.infinity);
    });

    test('zone numbers are sequential 1-7', () {
      for (int i = 0; i < 7; i++) {
        expect(PowerZone.zones[i].number, i + 1);
      }
    });

    test('zone boundaries are contiguous', () {
      for (int i = 0; i < 6; i++) {
        expect(PowerZone.zones[i].maxPercent, PowerZone.zones[i + 1].minPercent);
      }
    });
  });

  group('PowerZoneChartPainter', () {
    test('shouldRepaint returns true for different data', () {
      final p1 = PowerZoneChartPainter(data: const PowerZoneData([1, 2, 3, 4, 5, 6, 7]));
      final p2 = PowerZoneChartPainter(data: const PowerZoneData([7, 6, 5, 4, 3, 2, 1]));
      expect(p1.shouldRepaint(p2), isTrue);
    });
  });
}
