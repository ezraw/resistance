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

  group('buildPixelBorderPathMultiStep', () {
    test('steps=2 produces same bounds as legacy buildPixelBorderPath', () {
      const rect = Rect.fromLTWH(0, 0, 100, 80);
      final legacyPath = buildPixelBorderPath(rect, 4);
      final multiStepPath =
          buildPixelBorderPathMultiStep(rect, 4, steps: 2);

      final legacyBounds = legacyPath.getBounds();
      final multiStepBounds = multiStepPath.getBounds();

      expect(multiStepBounds.left, closeTo(legacyBounds.left, 0.01));
      expect(multiStepBounds.top, closeTo(legacyBounds.top, 0.01));
      expect(multiStepBounds.right, closeTo(legacyBounds.right, 0.01));
      expect(multiStepBounds.bottom, closeTo(legacyBounds.bottom, 0.01));
    });

    test('steps=3 corner consumes 3*notchSize per axis', () {
      const rect = Rect.fromLTWH(0, 0, 120, 100);
      const notchSize = 4.0;
      final path =
          buildPixelBorderPathMultiStep(rect, notchSize, steps: 3);

      // Center point should be inside
      expect(path.contains(const Offset(60, 50)), isTrue);

      // Corner points should be outside (within 3*4=12px of each corner)
      expect(path.contains(const Offset(0, 0)), isFalse);
      expect(path.contains(const Offset(119.9, 0)), isFalse);
      expect(path.contains(const Offset(0, 99.9)), isFalse);
      expect(path.contains(const Offset(119.9, 99.9)), isFalse);
    });

    test('steps=3 path fits within rect bounds', () {
      const rect = Rect.fromLTWH(0, 0, 120, 100);
      final path =
          buildPixelBorderPathMultiStep(rect, 4, steps: 3);
      final bounds = path.getBounds();

      expect(bounds.left, greaterThanOrEqualTo(rect.left));
      expect(bounds.top, greaterThanOrEqualTo(rect.top));
      expect(bounds.right, lessThanOrEqualTo(rect.right));
      expect(bounds.bottom, lessThanOrEqualTo(rect.bottom));
    });

    test('path bounds shrink with inset for multi-step', () {
      const rect = Rect.fromLTWH(0, 0, 120, 100);
      final pathNormal =
          buildPixelBorderPathMultiStep(rect, 4, steps: 3);
      final pathInset =
          buildPixelBorderPathMultiStep(rect, 4, inset: 3, steps: 3);

      final boundsNormal = pathNormal.getBounds();
      final boundsInset = pathInset.getBounds();

      expect(boundsInset.width, lessThan(boundsNormal.width));
      expect(boundsInset.height, lessThan(boundsNormal.height));
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

    test('shouldRepaint detects steps change', () {
      const painter1 = PixelBorderPainter(
        fillColor: Colors.black,
        borderColor: Colors.white,
        borderWidth: 2,
        notchSize: 4,
        steps: 2,
      );
      const painter2 = PixelBorderPainter(
        fillColor: Colors.black,
        borderColor: Colors.white,
        borderWidth: 2,
        notchSize: 4,
        steps: 3,
      );
      expect(painter1.shouldRepaint(painter2), isTrue);
    });
  });
}
