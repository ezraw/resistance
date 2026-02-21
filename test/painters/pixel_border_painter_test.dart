import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resistance_app/painters/pixel_border_painter.dart';

void main() {
  group('buildPixelBorderPath', () {
    test('returns a closed path', () {
      const rect = Rect.fromLTWH(0, 0, 100, 80);
      final path = buildPixelBorderPath(rect, 4);
      // Path should contain the rect area (minus corners)
      expect(path.getBounds(), isNotNull);
      // Verify the path bounds fit within the original rect
      final bounds = path.getBounds();
      expect(bounds.left, greaterThanOrEqualTo(rect.left));
      expect(bounds.top, greaterThanOrEqualTo(rect.top));
      expect(bounds.right, lessThanOrEqualTo(rect.right));
      expect(bounds.bottom, lessThanOrEqualTo(rect.bottom));
    });

    test('path bounds shrink with inset', () {
      const rect = Rect.fromLTWH(0, 0, 100, 80);
      final pathNormal = buildPixelBorderPath(rect, 4);
      final pathInset = buildPixelBorderPath(rect, 4, inset: 3);

      final boundsNormal = pathNormal.getBounds();
      final boundsInset = pathInset.getBounds();

      expect(boundsInset.width, lessThan(boundsNormal.width));
      expect(boundsInset.height, lessThan(boundsNormal.height));
    });

    test('path contains center point', () {
      const rect = Rect.fromLTWH(0, 0, 100, 80);
      final path = buildPixelBorderPath(rect, 4);
      expect(path.contains(const Offset(50, 40)), isTrue);
    });

    test('path excludes corner points', () {
      const rect = Rect.fromLTWH(0, 0, 100, 80);
      final path = buildPixelBorderPath(rect, 4);
      // The exact top-left corner should be outside the stepped path
      expect(path.contains(const Offset(0, 0)), isFalse);
      // The exact bottom-right corner should be outside the stepped path
      expect(path.contains(const Offset(99.9, 79.9)), isFalse);
    });
  });

  group('PixelBorderPainter', () {
    test('shouldRepaint returns true when properties change', () {
      const painter1 = PixelBorderPainter(
        fillColor: Colors.black,
        borderColor: Colors.white,
        borderWidth: 2,
        notchSize: 4,
      );
      const painter2 = PixelBorderPainter(
        fillColor: Colors.red,
        borderColor: Colors.white,
        borderWidth: 2,
        notchSize: 4,
      );
      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('shouldRepaint returns false when properties are the same', () {
      const painter1 = PixelBorderPainter(
        fillColor: Colors.black,
        borderColor: Colors.white,
        borderWidth: 2,
        notchSize: 4,
      );
      const painter2 = PixelBorderPainter(
        fillColor: Colors.black,
        borderColor: Colors.white,
        borderWidth: 2,
        notchSize: 4,
      );
      expect(painter1.shouldRepaint(painter2), isFalse);
    });

    test('shouldRepaint detects borderWidth change', () {
      const painter1 = PixelBorderPainter(
        fillColor: Colors.black,
        borderColor: Colors.white,
        borderWidth: 2,
        notchSize: 4,
      );
      const painter2 = PixelBorderPainter(
        fillColor: Colors.black,
        borderColor: Colors.white,
        borderWidth: 6,
        notchSize: 4,
      );
      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('shouldRepaint detects notchSize change', () {
      const painter1 = PixelBorderPainter(
        fillColor: Colors.black,
        borderColor: Colors.white,
        borderWidth: 2,
        notchSize: 4,
      );
      const painter2 = PixelBorderPainter(
        fillColor: Colors.black,
        borderColor: Colors.white,
        borderWidth: 2,
        notchSize: 3,
      );
      expect(painter1.shouldRepaint(painter2), isTrue);
    });
  });
}
