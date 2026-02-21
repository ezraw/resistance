import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'arcade/arcade_badge.dart';
import 'arcade/pixel_icon.dart';

/// Top bar showing workout timer and heart rate using arcade badges.
class WorkoutStatsBar extends StatelessWidget {
  final Duration elapsed;
  final int? heartRate;
  final bool hrConnected;
  final bool isConnectionDegraded;
  final VoidCallback? onHrTap;

  const WorkoutStatsBar({
    super.key,
    required this.elapsed,
    this.heartRate,
    this.hrConnected = false,
    this.isConnectionDegraded = false,
    this.onHrTap,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Padding(
      padding: EdgeInsets.only(
        top: topPadding + 8,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Timer badge
          ArcadeBadge(
            icon: const PixelIcon.stopwatch(size: 16),
            text: _formatDuration(elapsed),
            borderColor: AppColors.electricViolet,
          ),

          // Connection warning
          if (isConnectionDegraded)
            const ArcadeBadge(
              icon: PixelIcon.warning(size: 16),
              text: '',
              borderColor: AppColors.amber,
            ),

          // Heart Rate badge
          ArcadeBadge(
            icon: PixelIcon.heart(
              size: 16,
              color: hrConnected ? AppColors.red : AppColors.white.withValues(alpha: 0.5),
            ),
            text: heartRate != null && heartRate! > 0 ? '$heartRate' : '--',
            borderColor: AppColors.magenta,
            onTap: onHrTap,
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
