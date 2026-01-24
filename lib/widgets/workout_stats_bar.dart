import 'package:flutter/material.dart';
import 'workout_timer_display.dart';
import 'heart_rate_display.dart';

/// Top bar showing workout timer and heart rate
class WorkoutStatsBar extends StatelessWidget {
  final Duration elapsed;
  final int? heartRate;
  final bool hrConnected;
  final VoidCallback? onHrTap;

  const WorkoutStatsBar({
    super.key,
    required this.elapsed,
    this.heartRate,
    this.hrConnected = false,
    this.onHrTap,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.only(
        top: topPadding + 8,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.5),
            Colors.black.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.timer_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                WorkoutTimerDisplay(
                  elapsed: elapsed,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Heart Rate
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: HeartRateDisplay(
              bpm: heartRate,
              isConnected: hrConnected,
              onTap: onHrTap,
            ),
          ),
        ],
      ),
    );
  }
}
