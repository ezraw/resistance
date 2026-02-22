import 'package:flutter_test/flutter_test.dart';
import 'package:resistance_app/services/ble_service.dart';

void main() {
  group('FTMS Indoor Bike Data Parsing', () {
    late BleService bleService;
    late List<TrainerData> emittedData;

    setUp(() {
      bleService = BleService();
      emittedData = [];
      bleService.trainerData.listen(emittedData.add);
    });

    tearDown(() {
      bleService.dispose();
    });

    /// Helper to build an FTMS Indoor Bike Data packet.
    ///
    /// Flags (uint16 LE):
    ///   Bit 0: More Data — INVERTED (0 = speed present)
    ///   Bit 2: Instantaneous Cadence Present
    ///   Bit 6: Instantaneous Power Present
    List<int> buildPacket({
      int? speedRaw,       // uint16, resolution 0.01 km/h
      int? avgSpeedRaw,    // uint16 (bit 1)
      int? cadenceRaw,     // uint16, resolution 0.5 RPM
      int? avgCadenceRaw,  // uint16 (bit 3)
      int? distanceRaw,    // uint24 (bit 4)
      int? resistanceRaw,  // sint16 (bit 5)
      int? powerRaw,       // sint16, resolution 1W (bit 6)
    }) {
      int flags = 0;
      final fields = <int>[];

      // Bit 0: speed present when flag = 0 (inverted)
      if (speedRaw != null) {
        // Leave bit 0 as 0 to indicate speed is present
        fields.add(speedRaw & 0xFF);
        fields.add((speedRaw >> 8) & 0xFF);
      } else {
        flags |= 0x01; // Set bit 0 to indicate speed absent
      }

      // Bit 1: Average Speed
      if (avgSpeedRaw != null) {
        flags |= 0x02;
        fields.add(avgSpeedRaw & 0xFF);
        fields.add((avgSpeedRaw >> 8) & 0xFF);
      }

      // Bit 2: Cadence
      if (cadenceRaw != null) {
        flags |= 0x04;
        fields.add(cadenceRaw & 0xFF);
        fields.add((cadenceRaw >> 8) & 0xFF);
      }

      // Bit 3: Average Cadence
      if (avgCadenceRaw != null) {
        flags |= 0x08;
        fields.add(avgCadenceRaw & 0xFF);
        fields.add((avgCadenceRaw >> 8) & 0xFF);
      }

      // Bit 4: Total Distance (uint24)
      if (distanceRaw != null) {
        flags |= 0x10;
        fields.add(distanceRaw & 0xFF);
        fields.add((distanceRaw >> 8) & 0xFF);
        fields.add((distanceRaw >> 16) & 0xFF);
      }

      // Bit 5: Resistance Level
      if (resistanceRaw != null) {
        flags |= 0x20;
        fields.add(resistanceRaw & 0xFF);
        fields.add((resistanceRaw >> 8) & 0xFF);
      }

      // Bit 6: Instantaneous Power
      if (powerRaw != null) {
        flags |= 0x40;
        fields.add(powerRaw & 0xFF);
        fields.add((powerRaw >> 8) & 0xFF);
      }

      return [flags & 0xFF, (flags >> 8) & 0xFF, ...fields];
    }

    test('parses speed, cadence, and power from typical Wahoo packet', () async {
      // Speed: 2500 raw = 25.00 km/h
      // Cadence: 170 raw = 85.0 RPM (resolution 0.5)
      // Power: 200W
      final packet = buildPacket(
        speedRaw: 2500,
        cadenceRaw: 170,
        powerRaw: 200,
      );

      bleService.onIndoorBikeData(packet);
      await Future.delayed(Duration.zero);

      expect(emittedData.length, 1);
      expect(emittedData[0].speedKmh, closeTo(25.0, 0.01));
      expect(emittedData[0].cadenceRpm, closeTo(85.0, 0.01));
      expect(emittedData[0].watts, 200);
    });

    test('parses packet with only speed (no cadence, no power)', () async {
      final packet = buildPacket(speedRaw: 3000); // 30.00 km/h

      bleService.onIndoorBikeData(packet);
      await Future.delayed(Duration.zero);

      expect(emittedData.length, 1);
      expect(emittedData[0].speedKmh, closeTo(30.0, 0.01));
      expect(emittedData[0].cadenceRpm, 0.0);
      expect(emittedData[0].watts, 0);
    });

    test('parses packet with no speed, cadence and power only', () async {
      // Flags: bit 0 = 1 (no speed), bit 2 = 1 (cadence), bit 6 = 1 (power)
      // cadence 160 raw = 80 RPM, power 150W
      final packet = buildPacket(
        cadenceRaw: 160,
        powerRaw: 150,
      );

      bleService.onIndoorBikeData(packet);
      await Future.delayed(Duration.zero);

      expect(emittedData.length, 1);
      expect(emittedData[0].speedKmh, 0.0);
      expect(emittedData[0].cadenceRpm, closeTo(80.0, 0.01));
      expect(emittedData[0].watts, 150);
    });

    test('skips intervening fields correctly (avg speed, avg cadence, distance, resistance)', () async {
      // All optional fields present between speed and power
      final packet = buildPacket(
        speedRaw: 2000,      // 20.00 km/h
        avgSpeedRaw: 1800,   // skip
        cadenceRaw: 180,     // 90 RPM
        avgCadenceRaw: 170,  // skip
        distanceRaw: 50000,  // skip (uint24)
        resistanceRaw: 50,   // skip
        powerRaw: 250,       // 250W
      );

      bleService.onIndoorBikeData(packet);
      await Future.delayed(Duration.zero);

      expect(emittedData.length, 1);
      expect(emittedData[0].speedKmh, closeTo(20.0, 0.01));
      expect(emittedData[0].cadenceRpm, closeTo(90.0, 0.01));
      expect(emittedData[0].watts, 250);
    });

    test('handles empty data gracefully', () async {
      bleService.onIndoorBikeData([]);
      await Future.delayed(Duration.zero);

      expect(emittedData, isEmpty);
    });

    test('handles single byte gracefully', () async {
      bleService.onIndoorBikeData([0x00]);
      await Future.delayed(Duration.zero);

      expect(emittedData, isEmpty);
    });

    test('handles flags-only packet (no speed present due to bit 0 = 1)', () async {
      // Flags: 0x01 (bit 0 set = no speed, no other flags)
      bleService.onIndoorBikeData([0x01, 0x00]);
      await Future.delayed(Duration.zero);

      expect(emittedData.length, 1);
      expect(emittedData[0].speedKmh, 0.0);
      expect(emittedData[0].cadenceRpm, 0.0);
      expect(emittedData[0].watts, 0);
    });

    test('clamps negative power to 0', () async {
      // Power as sint16: -10 = 0xFFF6
      final packet = buildPacket(powerRaw: 0xFFF6);

      bleService.onIndoorBikeData(packet);
      await Future.delayed(Duration.zero);

      expect(emittedData.length, 1);
      expect(emittedData[0].watts, 0);
    });

    test('updates currentTrainerData on each notification', () async {
      expect(bleService.currentTrainerData, isNull);

      final packet = buildPacket(speedRaw: 2500, cadenceRaw: 170, powerRaw: 200);
      bleService.onIndoorBikeData(packet);
      await Future.delayed(Duration.zero);

      expect(bleService.currentTrainerData, isNotNull);
      expect(bleService.currentTrainerData!.watts, 200);

      // Second update overwrites
      final packet2 = buildPacket(speedRaw: 3000, cadenceRaw: 180, powerRaw: 300);
      bleService.onIndoorBikeData(packet2);
      await Future.delayed(Duration.zero);

      expect(bleService.currentTrainerData!.watts, 300);
    });

    test('handles high speed values', () async {
      // 5000 raw = 50.00 km/h
      final packet = buildPacket(speedRaw: 5000);

      bleService.onIndoorBikeData(packet);
      await Future.delayed(Duration.zero);

      expect(emittedData[0].speedKmh, closeTo(50.0, 0.01));
    });

    test('handles zero values', () async {
      final packet = buildPacket(speedRaw: 0, cadenceRaw: 0, powerRaw: 0);

      bleService.onIndoorBikeData(packet);
      await Future.delayed(Duration.zero);

      expect(emittedData.length, 1);
      expect(emittedData[0].speedKmh, 0.0);
      expect(emittedData[0].cadenceRpm, 0.0);
      expect(emittedData[0].watts, 0);
    });
  });
}
