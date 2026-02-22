import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Pixel-art icon types available in the app.
enum PixelIconType {
  upArrow,
  downArrow,
  heart,
  play,
  pause,
  stop,
  restart,
  stopwatch,
  warning,
  bluetooth,
  signalBars,
  greenDot,
  close,
  check,
  list,
  lightningBolt,
  person,
}

/// Renders pixel-art icons using CustomPainter.
/// All icons are built from straight segments and 90-degree pixel steps.
class PixelIcon extends StatelessWidget {
  final PixelIconType type;
  final double size;
  final Color? color;
  final Color? shadowColor;

  const PixelIcon({
    super.key,
    required this.type,
    this.size = 24,
    this.color,
    this.shadowColor,
  });

  const PixelIcon.upArrow({super.key, this.size = 24, this.color, this.shadowColor})
      : type = PixelIconType.upArrow;

  const PixelIcon.downArrow({super.key, this.size = 24, this.color, this.shadowColor})
      : type = PixelIconType.downArrow;

  const PixelIcon.heart({super.key, this.size = 24, this.color, this.shadowColor})
      : type = PixelIconType.heart;

  const PixelIcon.play({super.key, this.size = 24, this.color, this.shadowColor})
      : type = PixelIconType.play;

  const PixelIcon.pause({super.key, this.size = 24, this.color, this.shadowColor})
      : type = PixelIconType.pause;

  const PixelIcon.stop({super.key, this.size = 24, this.color, this.shadowColor})
      : type = PixelIconType.stop;

  const PixelIcon.restart({super.key, this.size = 24, this.color, this.shadowColor})
      : type = PixelIconType.restart;

  const PixelIcon.stopwatch({super.key, this.size = 24, this.color, this.shadowColor})
      : type = PixelIconType.stopwatch;

  const PixelIcon.warning({super.key, this.size = 24, this.color, this.shadowColor})
      : type = PixelIconType.warning;

  const PixelIcon.bluetooth({super.key, this.size = 24, this.color, this.shadowColor})
      : type = PixelIconType.bluetooth;

  const PixelIcon.signalBars({super.key, this.size = 24, this.color, this.shadowColor})
      : type = PixelIconType.signalBars;

  const PixelIcon.greenDot({super.key, this.size = 24, this.color, this.shadowColor})
      : type = PixelIconType.greenDot;

  const PixelIcon.close({super.key, this.size = 24, this.color, this.shadowColor})
      : type = PixelIconType.close;

  const PixelIcon.check({super.key, this.size = 24, this.color, this.shadowColor})
      : type = PixelIconType.check;

  const PixelIcon.list({super.key, this.size = 24, this.color, this.shadowColor})
      : type = PixelIconType.list;

  const PixelIcon.lightningBolt({super.key, this.size = 24, this.color, this.shadowColor})
      : type = PixelIconType.lightningBolt;

  const PixelIcon.person({super.key, this.size = 24, this.color, this.shadowColor})
      : type = PixelIconType.person;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PixelIconPainter(
          type: type,
          color: color ?? _defaultColor(type),
          shadowColor: shadowColor,
        ),
      ),
    );
  }

  static Color _defaultColor(PixelIconType type) {
    switch (type) {
      case PixelIconType.upArrow:
      case PixelIconType.downArrow:
        return AppColors.gold;
      case PixelIconType.heart:
        return AppColors.red;
      case PixelIconType.play:
      case PixelIconType.stop:
        return AppColors.white;
      case PixelIconType.pause:
        return AppColors.white;
      case PixelIconType.restart:
        return AppColors.white;
      case PixelIconType.stopwatch:
        return AppColors.gold;
      case PixelIconType.warning:
        return AppColors.amber;
      case PixelIconType.bluetooth:
        return AppColors.neonCyan;
      case PixelIconType.signalBars:
        return AppColors.green;
      case PixelIconType.greenDot:
        return AppColors.green;
      case PixelIconType.close:
        return AppColors.warmCream;
      case PixelIconType.check:
        return AppColors.nightPlum;
      case PixelIconType.list:
        return AppColors.warmCream;
      case PixelIconType.lightningBolt:
        return AppColors.gold;
      case PixelIconType.person:
        return AppColors.warmCream;
    }
  }
}

class _PixelIconPainter extends CustomPainter {
  final PixelIconType type;
  final Color color;
  final Color? shadowColor;

  _PixelIconPainter({
    required this.type,
    required this.color,
    this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = size.width / 16; // pixel unit (icon drawn on 16x16 grid)
    final paint = Paint()..color = color;
    final shadow = Paint()..color = shadowColor ?? color.withValues(alpha: 0.4);

    switch (type) {
      case PixelIconType.upArrow:
        _drawUpArrow(canvas, p, paint, shadow);
        break;
      case PixelIconType.downArrow:
        _drawDownArrow(canvas, p, paint, shadow);
        break;
      case PixelIconType.heart:
        _drawHeart(canvas, p, paint, shadow);
        break;
      case PixelIconType.play:
        _drawPlay(canvas, p, paint);
        break;
      case PixelIconType.pause:
        _drawPause(canvas, p, paint);
        break;
      case PixelIconType.stop:
        _drawStop(canvas, p, paint);
        break;
      case PixelIconType.restart:
        _drawRestart(canvas, p, paint);
        break;
      case PixelIconType.stopwatch:
        _drawStopwatch(canvas, p, paint);
        break;
      case PixelIconType.warning:
        _drawWarning(canvas, p, paint);
        break;
      case PixelIconType.bluetooth:
        _drawBluetooth(canvas, p, paint);
        break;
      case PixelIconType.signalBars:
        _drawSignalBars(canvas, p, paint);
        break;
      case PixelIconType.greenDot:
        _drawGreenDot(canvas, p, paint);
        break;
      case PixelIconType.close:
        _drawClose(canvas, p, paint);
        break;
      case PixelIconType.check:
        _drawCheck(canvas, p, paint);
        break;
      case PixelIconType.list:
        _drawList(canvas, p, paint);
        break;
      case PixelIconType.lightningBolt:
        _drawLightningBolt(canvas, p, paint);
        break;
      case PixelIconType.person:
        _drawPerson(canvas, p, paint);
        break;
    }
  }

  void _drawUpArrow(Canvas canvas, double p, Paint paint, Paint shadow) {
    // Shadow offset
    canvas.save();
    canvas.translate(0, p);
    _drawUpArrowShape(canvas, p, shadow);
    canvas.restore();
    // Main
    _drawUpArrowShape(canvas, p, paint);
  }

  void _drawUpArrowShape(Canvas canvas, double p, Paint paint) {
    // Chunky up arrow: pointed at top, wide base
    final path = Path()
      ..moveTo(8 * p, 2 * p)
      ..lineTo(10 * p, 4 * p)
      ..lineTo(10 * p, 6 * p)
      ..lineTo(12 * p, 6 * p)
      ..lineTo(12 * p, 8 * p)
      ..lineTo(10 * p, 8 * p)
      ..lineTo(10 * p, 14 * p)
      ..lineTo(6 * p, 14 * p)
      ..lineTo(6 * p, 8 * p)
      ..lineTo(4 * p, 8 * p)
      ..lineTo(4 * p, 6 * p)
      ..lineTo(6 * p, 6 * p)
      ..lineTo(6 * p, 4 * p)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawDownArrow(Canvas canvas, double p, Paint paint, Paint shadow) {
    canvas.save();
    canvas.translate(0, p);
    _drawDownArrowShape(canvas, p, shadow);
    canvas.restore();
    _drawDownArrowShape(canvas, p, paint);
  }

  void _drawDownArrowShape(Canvas canvas, double p, Paint paint) {
    final path = Path()
      ..moveTo(6 * p, 2 * p)
      ..lineTo(10 * p, 2 * p)
      ..lineTo(10 * p, 8 * p)
      ..lineTo(12 * p, 8 * p)
      ..lineTo(12 * p, 10 * p)
      ..lineTo(10 * p, 10 * p)
      ..lineTo(10 * p, 12 * p)
      ..lineTo(8 * p, 14 * p)
      ..lineTo(6 * p, 12 * p)
      ..lineTo(6 * p, 10 * p)
      ..lineTo(4 * p, 10 * p)
      ..lineTo(4 * p, 8 * p)
      ..lineTo(6 * p, 8 * p)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawHeart(Canvas canvas, double p, Paint paint, Paint shadow) {
    // Shadow
    canvas.save();
    canvas.translate(0, p * 0.5);
    _drawHeartShape(canvas, p, shadow);
    canvas.restore();
    _drawHeartShape(canvas, p, paint);
  }

  void _drawHeartShape(Canvas canvas, double p, Paint paint) {
    // Pixel heart: two bumps on top, pointed at bottom
    final rects = <Rect>[
      // Top-left bump
      Rect.fromLTWH(3 * p, 3 * p, 2 * p, 2 * p),
      Rect.fromLTWH(2 * p, 4 * p, 1 * p, 3 * p),
      Rect.fromLTWH(5 * p, 3 * p, 1 * p, 3 * p),
      // Top-right bump
      Rect.fromLTWH(9 * p, 3 * p, 2 * p, 2 * p),
      Rect.fromLTWH(11 * p, 4 * p, 2 * p, 3 * p),
      Rect.fromLTWH(8 * p, 3 * p, 1 * p, 3 * p),
      // Center fill
      Rect.fromLTWH(3 * p, 5 * p, 8 * p, 3 * p),
      Rect.fromLTWH(4 * p, 8 * p, 6 * p, 2 * p),
      Rect.fromLTWH(5 * p, 10 * p, 4 * p, 1 * p),
      Rect.fromLTWH(6 * p, 11 * p, 2 * p, 1 * p),
      Rect.fromLTWH(7 * p, 12 * p, 1 * p, 1 * p),
    ];
    for (final rect in rects) {
      canvas.drawRect(rect, paint);
    }
  }

  void _drawPlay(Canvas canvas, double p, Paint paint) {
    // Right-pointing triangle made of pixel steps
    final path = Path()
      ..moveTo(5 * p, 3 * p)
      ..lineTo(5 * p, 13 * p)
      ..lineTo(12 * p, 8 * p)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawPause(Canvas canvas, double p, Paint paint) {
    // Two vertical bars
    canvas.drawRect(Rect.fromLTWH(4 * p, 3 * p, 3 * p, 10 * p), paint);
    canvas.drawRect(Rect.fromLTWH(9 * p, 3 * p, 3 * p, 10 * p), paint);
  }

  void _drawStop(Canvas canvas, double p, Paint paint) {
    canvas.drawRect(Rect.fromLTWH(3 * p, 3 * p, 10 * p, 10 * p), paint);
  }

  void _drawRestart(Canvas canvas, double p, Paint paint) {
    // Circular arrow (simplified pixel art)
    final strokePaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = p * 2;
    // Arc
    canvas.drawArc(
      Rect.fromLTWH(3 * p, 3 * p, 10 * p, 10 * p),
      -0.5,
      5.0,
      false,
      strokePaint,
    );
    // Arrow head
    final arrowPath = Path()
      ..moveTo(8 * p, 1 * p)
      ..lineTo(12 * p, 3 * p)
      ..lineTo(8 * p, 5 * p)
      ..close();
    canvas.drawPath(arrowPath, paint);
  }

  void _drawStopwatch(Canvas canvas, double p, Paint paint) {
    final strokePaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = p * 1.5;
    // Body circle
    canvas.drawCircle(Offset(8 * p, 9 * p), 5 * p, strokePaint);
    // Top stem
    canvas.drawRect(Rect.fromLTWH(7 * p, 2 * p, 2 * p, 2 * p), paint);
    // Hands
    canvas.drawLine(
      Offset(8 * p, 9 * p),
      Offset(8 * p, 6 * p),
      Paint()..color = paint.color..strokeWidth = p,
    );
    canvas.drawLine(
      Offset(8 * p, 9 * p),
      Offset(10.5 * p, 9 * p),
      Paint()..color = paint.color..strokeWidth = p,
    );
  }

  void _drawWarning(Canvas canvas, double p, Paint paint) {
    // Triangle
    final path = Path()
      ..moveTo(8 * p, 2 * p)
      ..lineTo(14 * p, 13 * p)
      ..lineTo(2 * p, 13 * p)
      ..close();
    canvas.drawPath(path, paint);
    // Exclamation (cutout in dark)
    final darkPaint = Paint()..color = AppColors.nightPlum;
    canvas.drawRect(Rect.fromLTWH(7 * p, 5 * p, 2 * p, 4 * p), darkPaint);
    canvas.drawRect(Rect.fromLTWH(7 * p, 10 * p, 2 * p, 2 * p), darkPaint);
  }

  void _drawBluetooth(Canvas canvas, double p, Paint paint) {
    final strokePaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = p * 1.5;
    // Central vertical line
    canvas.drawLine(Offset(8 * p, 2 * p), Offset(8 * p, 14 * p), strokePaint);
    // Top-right arrow
    canvas.drawLine(Offset(8 * p, 2 * p), Offset(11 * p, 5 * p), strokePaint);
    canvas.drawLine(Offset(11 * p, 5 * p), Offset(5 * p, 11 * p), strokePaint);
    // Bottom-right arrow
    canvas.drawLine(Offset(8 * p, 14 * p), Offset(11 * p, 11 * p), strokePaint);
    canvas.drawLine(Offset(11 * p, 11 * p), Offset(5 * p, 5 * p), strokePaint);
  }

  void _drawSignalBars(Canvas canvas, double p, Paint paint) {
    // 4 bars increasing height
    canvas.drawRect(Rect.fromLTWH(2 * p, 11 * p, 2 * p, 3 * p), paint);
    canvas.drawRect(Rect.fromLTWH(5 * p, 9 * p, 2 * p, 5 * p), paint);
    canvas.drawRect(Rect.fromLTWH(8 * p, 6 * p, 2 * p, 8 * p), paint);
    canvas.drawRect(Rect.fromLTWH(11 * p, 3 * p, 2 * p, 11 * p), paint);
  }

  void _drawGreenDot(Canvas canvas, double p, Paint paint) {
    canvas.drawCircle(Offset(8 * p, 8 * p), 3 * p, paint);
  }

  void _drawClose(Canvas canvas, double p, Paint paint) {
    // Pixel X shape using rectangles on diagonal
    // Top-left to bottom-right diagonal
    canvas.drawRect(Rect.fromLTWH(3 * p, 3 * p, 2 * p, 2 * p), paint);
    canvas.drawRect(Rect.fromLTWH(5 * p, 5 * p, 2 * p, 2 * p), paint);
    canvas.drawRect(Rect.fromLTWH(7 * p, 7 * p, 2 * p, 2 * p), paint);
    canvas.drawRect(Rect.fromLTWH(9 * p, 9 * p, 2 * p, 2 * p), paint);
    canvas.drawRect(Rect.fromLTWH(11 * p, 11 * p, 2 * p, 2 * p), paint);
    // Top-right to bottom-left diagonal
    canvas.drawRect(Rect.fromLTWH(11 * p, 3 * p, 2 * p, 2 * p), paint);
    canvas.drawRect(Rect.fromLTWH(9 * p, 5 * p, 2 * p, 2 * p), paint);
    // center already drawn above (7,7)
    canvas.drawRect(Rect.fromLTWH(5 * p, 9 * p, 2 * p, 2 * p), paint);
    canvas.drawRect(Rect.fromLTWH(3 * p, 11 * p, 2 * p, 2 * p), paint);
  }

  void _drawCheck(Canvas canvas, double p, Paint paint) {
    // Pixel checkmark: short left leg, tall right leg
    canvas.drawRect(Rect.fromLTWH(2 * p, 8 * p, 2 * p, 2 * p), paint);
    canvas.drawRect(Rect.fromLTWH(4 * p, 10 * p, 2 * p, 2 * p), paint);
    canvas.drawRect(Rect.fromLTWH(6 * p, 8 * p, 2 * p, 2 * p), paint);
    canvas.drawRect(Rect.fromLTWH(8 * p, 6 * p, 2 * p, 2 * p), paint);
    canvas.drawRect(Rect.fromLTWH(10 * p, 4 * p, 2 * p, 2 * p), paint);
    canvas.drawRect(Rect.fromLTWH(12 * p, 2 * p, 2 * p, 2 * p), paint);
  }

  void _drawList(Canvas canvas, double p, Paint paint) {
    // Three horizontal bars at y=4, y=8, y=12 (widths 10, 8, 6 pixels, each 2px tall)
    canvas.drawRect(Rect.fromLTWH(3 * p, 4 * p, 10 * p, 2 * p), paint);
    canvas.drawRect(Rect.fromLTWH(4 * p, 8 * p, 8 * p, 2 * p), paint);
    canvas.drawRect(Rect.fromLTWH(5 * p, 12 * p, 6 * p, 2 * p), paint);
  }

  void _drawLightningBolt(Canvas canvas, double p, Paint paint) {
    // Jagged lightning bolt: wide top → narrow bottom point
    final path = Path()
      ..moveTo(9 * p, 1 * p)
      ..lineTo(12 * p, 1 * p)
      ..lineTo(8 * p, 7 * p)
      ..lineTo(11 * p, 7 * p)
      ..lineTo(6 * p, 15 * p)
      ..lineTo(7 * p, 9 * p)
      ..lineTo(4 * p, 9 * p)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawPerson(Canvas canvas, double p, Paint paint) {
    // Head block: 4x4 centered at columns 6-9, rows 2-5
    canvas.drawRect(Rect.fromLTWH(6 * p, 2 * p, 4 * p, 4 * p), paint);
    // Neck: 2x1 centered
    canvas.drawRect(Rect.fromLTWH(7 * p, 6 * p, 2 * p, 1 * p), paint);
    // Shoulders and torso: rows 7-10
    canvas.drawRect(Rect.fromLTWH(3 * p, 7 * p, 10 * p, 2 * p), paint);
    canvas.drawRect(Rect.fromLTWH(4 * p, 9 * p, 8 * p, 2 * p), paint);
    canvas.drawRect(Rect.fromLTWH(5 * p, 11 * p, 6 * p, 2 * p), paint);
  }

  @override
  bool shouldRepaint(_PixelIconPainter oldDelegate) =>
      type != oldDelegate.type ||
      color != oldDelegate.color ||
      shadowColor != oldDelegate.shadowColor;
}
