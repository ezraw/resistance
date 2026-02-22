import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Heart rate zone definition.
class HrZone {
  final int number;
  final String name;
  final double minPercent;
  final double maxPercent;
  final Color color;

  const HrZone({
    required this.number,
    required this.name,
    required this.minPercent,
    required this.maxPercent,
    required this.color,
  });

  /// Standard 5-zone model.
  static const zones = [
    HrZone(number: 1, name: 'WARM UP', minPercent: 0.50, maxPercent: 0.60, color: AppColors.neonCyan),
    HrZone(number: 2, name: 'FAT BURN', minPercent: 0.60, maxPercent: 0.70, color: AppColors.green),
    HrZone(number: 3, name: 'CARDIO', minPercent: 0.70, maxPercent: 0.80, color: AppColors.gold),
    HrZone(number: 4, name: 'HARD', minPercent: 0.80, maxPercent: 0.90, color: Color(0xFFFF8C00)),
    HrZone(number: 5, name: 'PEAK', minPercent: 0.90, maxPercent: 1.00, color: AppColors.hotPink),
  ];
}

/// Data for rendering zone chart: time in seconds per zone.
class HrZoneData {
  final List<int> zoneSeconds;

  const HrZoneData(this.zoneSeconds);

  /// Calculate zone times from a list of heart rate samples (BPM values).
  /// Each sample represents ~1 second.
  factory HrZoneData.fromHeartRates(List<int> heartRates, {int maxHr = 190}) {
    final zoneSecs = List.filled(5, 0);

    for (final hr in heartRates) {
      if (hr <= 0) continue;
      final percent = hr / maxHr;
      if (percent >= 0.90) {
        zoneSecs[4]++;
      } else if (percent >= 0.80) {
        zoneSecs[3]++;
      } else if (percent >= 0.70) {
        zoneSecs[2]++;
      } else if (percent >= 0.60) {
        zoneSecs[1]++;
      } else {
        zoneSecs[0]++;
      }
    }

    return HrZoneData(zoneSecs);
  }

  /// Total seconds across all zones.
  int get totalSeconds => zoneSeconds.fold(0, (sum, s) => sum + s);

  /// Maximum seconds in any single zone (for scaling bars).
  int get maxZoneSeconds {
    int max = 0;
    for (final s in zoneSeconds) {
      if (s > max) max = s;
    }
    return max;
  }

  /// Whether there is any data to display.
  bool get isEmpty => totalSeconds == 0;
}

/// Pixel-art horizontal bar chart showing time in each HR zone.
class HrZoneChartPainter extends CustomPainter {
  final HrZoneData data;

  HrZoneChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    if (data.isEmpty) return;

    const zones = HrZone.zones;
    final maxSecs = data.maxZoneSeconds;
    if (maxSecs <= 0) return;

    final rowHeight = size.height / 5;
    final labelWidth = size.width * 0.30; // zone label area
    final timeWidth = size.width * 0.22; // time label area
    final barAreaWidth = size.width - labelWidth - timeWidth - 8; // bar area with gap

    const pixelSize = 2.0;

    for (int i = 0; i < 5; i++) {
      final zone = zones[i];
      final secs = data.zoneSeconds[i];
      final y = i * rowHeight;
      final barY = y + (rowHeight - pixelSize * 4) / 2;

      // Zone label (text)
      final labelPainter = TextPainter(
        text: TextSpan(
          text: 'Z${zone.number} ${zone.name}',
          style: TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: 6,
            color: zone.color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: labelWidth);
      labelPainter.paint(
        canvas,
        Offset(0, y + (rowHeight - labelPainter.height) / 2),
      );

      // Bar
      final barWidth = maxSecs > 0
          ? (secs / maxSecs) * barAreaWidth
          : 0.0;
      final barPaint = Paint()..color = zone.color;

      // Draw bar as pixel blocks
      final barStartX = labelWidth + 4;
      final effectiveBarWidth = barWidth < pixelSize * 2 ? pixelSize * 2 : barWidth;
      final blocksX = (effectiveBarWidth / pixelSize).floor();
      const blocksY = 4; // 4 pixels tall

      for (int bx = 0; bx < blocksX; bx++) {
        for (int by = 0; by < blocksY; by++) {
          canvas.drawRect(
            Rect.fromLTWH(
              barStartX + bx * pixelSize,
              barY + by * pixelSize,
              pixelSize,
              pixelSize,
            ),
            barPaint,
          );
        }
      }

      // Time label
      final timeStr = _formatSeconds(secs);
      final timePainter = TextPainter(
        text: TextSpan(
          text: timeStr,
          style: TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: 6,
            color: AppColors.warmCream.withValues(alpha: 0.7),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: timeWidth);
      timePainter.paint(
        canvas,
        Offset(
          size.width - timePainter.width,
          y + (rowHeight - timePainter.height) / 2,
        ),
      );
    }
  }

  String _formatSeconds(int totalSeconds) {
    if (totalSeconds <= 0) return '0s';
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    if (m > 0) {
      return '${m}m ${s.toString().padLeft(2, '0')}s';
    }
    return '${s}s';
  }

  @override
  bool shouldRepaint(HrZoneChartPainter oldDelegate) => data != oldDelegate.data;
}
