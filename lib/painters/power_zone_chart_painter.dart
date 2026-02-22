import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Power zone definition using the 7-zone Coggan model.
class PowerZone {
  final int number;
  final String name;
  final double minPercent;
  final double maxPercent;
  final Color color;

  const PowerZone({
    required this.number,
    required this.name,
    required this.minPercent,
    required this.maxPercent,
    required this.color,
  });

  /// Standard 7-zone Coggan model (percent of FTP).
  static const zones = [
    PowerZone(number: 1, name: 'RECOVERY', minPercent: 0.00, maxPercent: 0.55, color: AppColors.neonCyan),
    PowerZone(number: 2, name: 'ENDURANCE', minPercent: 0.55, maxPercent: 0.75, color: AppColors.green),
    PowerZone(number: 3, name: 'TEMPO', minPercent: 0.75, maxPercent: 0.90, color: AppColors.gold),
    PowerZone(number: 4, name: 'THRESHOLD', minPercent: 0.90, maxPercent: 1.05, color: AppColors.amber),
    PowerZone(number: 5, name: 'VO2MAX', minPercent: 1.05, maxPercent: 1.20, color: Color(0xFFFF8C00)),
    PowerZone(number: 6, name: 'ANAEROBIC', minPercent: 1.20, maxPercent: 1.50, color: AppColors.hotPink),
    PowerZone(number: 7, name: 'NEURO', minPercent: 1.50, maxPercent: double.infinity, color: AppColors.red),
  ];
}

/// Data for rendering power zone chart: time in seconds per zone.
class PowerZoneData {
  final List<int> zoneSeconds;

  const PowerZoneData(this.zoneSeconds);

  /// Calculate zone times from a list of watt readings.
  /// Each reading represents ~1 second.
  factory PowerZoneData.fromWatts(List<int> watts, {int ftp = 100}) {
    final zoneSecs = List.filled(7, 0);

    for (final w in watts) {
      if (w <= 0) continue;
      final percent = w / ftp;
      if (percent >= 1.50) {
        zoneSecs[6]++;
      } else if (percent >= 1.20) {
        zoneSecs[5]++;
      } else if (percent >= 1.05) {
        zoneSecs[4]++;
      } else if (percent >= 0.90) {
        zoneSecs[3]++;
      } else if (percent >= 0.75) {
        zoneSecs[2]++;
      } else if (percent >= 0.55) {
        zoneSecs[1]++;
      } else {
        zoneSecs[0]++;
      }
    }

    return PowerZoneData(zoneSecs);
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

/// Pixel-art horizontal bar chart showing time in each power zone.
class PowerZoneChartPainter extends CustomPainter {
  final PowerZoneData data;

  PowerZoneChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    if (data.isEmpty) return;

    const zones = PowerZone.zones;
    final maxSecs = data.maxZoneSeconds;
    if (maxSecs <= 0) return;

    final rowHeight = size.height / 7;
    final labelWidth = size.width * 0.30; // zone label area
    final timeWidth = size.width * 0.22; // time label area
    final barAreaWidth = size.width - labelWidth - timeWidth - 8; // bar area with gap

    const pixelSize = 2.0;

    for (int i = 0; i < 7; i++) {
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
  bool shouldRepaint(PowerZoneChartPainter oldDelegate) => data != oldDelegate.data;
}
