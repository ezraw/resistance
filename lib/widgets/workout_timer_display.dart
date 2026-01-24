import 'package:flutter/material.dart';

/// Displays elapsed workout time in MM:SS or HH:MM:SS format
class WorkoutTimerDisplay extends StatelessWidget {
  final Duration elapsed;
  final TextStyle? style;

  const WorkoutTimerDisplay({
    super.key,
    required this.elapsed,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatDuration(elapsed),
      style: style ?? const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        fontFeatures: [FontFeature.tabularFigures()],
        color: Colors.white,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}
