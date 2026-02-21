import 'package:flutter_test/flutter_test.dart';
import 'package:resistance_app/painters/bayer_dither.dart';

void main() {
  group('BayerDither', () {
    test('matrix has correct dimensions', () {
      expect(BayerDither.matrix4x4.length, 4);
      for (final row in BayerDither.matrix4x4) {
        expect(row.length, 4);
      }
    });

    test('all matrix values are in 0.0-1.0 range', () {
      for (final row in BayerDither.matrix4x4) {
        for (final val in row) {
          expect(val, greaterThanOrEqualTo(0.0));
          expect(val, lessThan(1.0));
        }
      }
    });

    test('threshold wraps coordinates to 4x4', () {
      expect(BayerDither.threshold(0, 0), BayerDither.threshold(4, 4));
      expect(BayerDither.threshold(1, 2), BayerDither.threshold(5, 6));
    });

    test('shouldUseColorB returns false at mixRatio 0', () {
      for (int x = 0; x < 4; x++) {
        for (int y = 0; y < 4; y++) {
          expect(BayerDither.shouldUseColorB(x, y, 0.0), isFalse);
        }
      }
    });

    test('shouldUseColorB returns true for most at mixRatio near 1', () {
      int trueCount = 0;
      for (int x = 0; x < 4; x++) {
        for (int y = 0; y < 4; y++) {
          if (BayerDither.shouldUseColorB(x, y, 0.99)) trueCount++;
        }
      }
      expect(trueCount, greaterThan(12)); // most of 16 pixels
    });

    test('shouldUseColorB returns ~50% at mixRatio 0.5', () {
      int trueCount = 0;
      for (int x = 0; x < 4; x++) {
        for (int y = 0; y < 4; y++) {
          if (BayerDither.shouldUseColorB(x, y, 0.5)) trueCount++;
        }
      }
      expect(trueCount, greaterThan(4));
      expect(trueCount, lessThan(12));
    });
  });
}
