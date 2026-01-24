import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HR Data Parsing', () {
    // Test the heart rate parsing logic directly
    // This mirrors the _parseHeartRate method in HrService

    int parseHeartRate(List<int> data) {
      if (data.isEmpty) return 0;

      final flags = data[0];
      final is16Bit = (flags & 0x01) != 0;

      if (is16Bit && data.length >= 3) {
        // 16-bit heart rate value (little-endian)
        return data[1] | (data[2] << 8);
      }

      // 8-bit heart rate value
      return data.length >= 2 ? data[1] : 0;
    }

    test('parses 8-bit heart rate correctly', () {
      // Flags: 0x00 indicates 8-bit HR format
      // HR value: 120 bpm
      final data = [0x00, 120];
      expect(parseHeartRate(data), 120);
    });

    test('parses 16-bit heart rate correctly', () {
      // Flags: 0x01 indicates 16-bit HR format
      // HR value: 256 bpm (0x0100 in little-endian)
      final data = [0x01, 0x00, 0x01];
      expect(parseHeartRate(data), 256);
    });

    test('parses 16-bit heart rate with typical value', () {
      // Flags: 0x01 indicates 16-bit HR format
      // HR value: 150 (0x0096 in little-endian = [0x96, 0x00])
      final data = [0x01, 0x96, 0x00];
      expect(parseHeartRate(data), 150);
    });

    test('returns 0 for empty data', () {
      expect(parseHeartRate([]), 0);
    });

    test('returns 0 for data with only flags', () {
      expect(parseHeartRate([0x00]), 0);
    });

    test('handles 16-bit flag with insufficient data', () {
      // Flags say 16-bit but only one byte of HR data
      final data = [0x01, 0x60];
      // Should fall through to 8-bit parsing
      expect(parseHeartRate(data), 0x60);
    });

    test('parses common heart rate values correctly', () {
      // Test common workout heart rates (8-bit format)
      expect(parseHeartRate([0x00, 60]), 60);   // Resting
      expect(parseHeartRate([0x00, 100]), 100); // Light activity
      expect(parseHeartRate([0x00, 150]), 150); // Moderate activity
      expect(parseHeartRate([0x00, 180]), 180); // Intense activity
    });

    test('handles other flags correctly with 8-bit HR', () {
      // Flags can have other bits set (like sensor contact, energy expended)
      // As long as bit 0 is 0, it's 8-bit HR
      final data = [0x06, 130]; // Flags: 0x06 (bits 1 and 2 set, but not bit 0)
      expect(parseHeartRate(data), 130);
    });

    test('handles other flags correctly with 16-bit HR', () {
      // Flags with bit 0 set plus other bits
      final data = [0x07, 0x82, 0x00]; // Flags: 0x07, HR: 130
      expect(parseHeartRate(data), 130);
    });
  });
}
