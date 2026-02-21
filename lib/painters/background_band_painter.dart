import 'package:flutter/material.dart';
import 'bayer_dither.dart';

/// CustomPainter that draws stacked horizontal color bands with Bayer dithering
/// at the transitions.
class BackgroundBandPainter extends CustomPainter {
  final List<Color> bandColors;
  final int pixelScale;

  BackgroundBandPainter({
    required this.bandColors,
    this.pixelScale = 2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (bandColors.isEmpty || size.width <= 0 || size.height <= 0) return;
    if (bandColors.length == 1) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = bandColors[0],
      );
      return;
    }

    final bandCount = bandColors.length;
    final bandHeight = size.height / bandCount;
    // Dither transition strip is ~8% of screen height
    final ditherHeight = size.height * 0.08;

    for (int i = 0; i < bandCount; i++) {
      final bandTop = i * bandHeight;
      final bandBottom = bandTop + bandHeight;

      // Draw solid center of band
      final solidTop = i == 0 ? 0.0 : bandTop + ditherHeight / 2;
      final solidBottom =
          i == bandCount - 1 ? size.height : bandBottom - ditherHeight / 2;

      if (solidBottom > solidTop) {
        canvas.drawRect(
          Rect.fromLTWH(0, solidTop, size.width, solidBottom - solidTop),
          Paint()..color = bandColors[i],
        );
      }

      // Draw dithered transition to next band
      if (i < bandCount - 1) {
        final transitionTop = bandBottom - ditherHeight / 2;
        final transitionBottom = bandBottom + ditherHeight / 2;
        final colorA = bandColors[i];
        final colorB = bandColors[i + 1];

        _drawDitheredTransition(
          canvas,
          size.width,
          transitionTop,
          transitionBottom,
          colorA,
          colorB,
        );
      }
    }
  }

  void _drawDitheredTransition(
    Canvas canvas,
    double width,
    double top,
    double bottom,
    Color colorA,
    Color colorB,
  ) {
    final scale = pixelScale.toDouble();
    final height = bottom - top;

    for (double y = top; y < bottom; y += scale) {
      // Mix ratio: 0 at top, 1 at bottom
      final mix = (y - top) / height;

      for (double x = 0; x < width; x += scale) {
        final px = (x / scale).floor();
        final py = (y / scale).floor();

        final useB = BayerDither.shouldUseColorB(px, py, mix);
        final color = useB ? colorB : colorA;

        canvas.drawRect(
          Rect.fromLTWH(x, y, scale, scale),
          Paint()..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(BackgroundBandPainter oldDelegate) {
    if (bandColors.length != oldDelegate.bandColors.length) return true;
    for (int i = 0; i < bandColors.length; i++) {
      if (bandColors[i] != oldDelegate.bandColors[i]) return true;
    }
    return pixelScale != oldDelegate.pixelScale;
  }
}
