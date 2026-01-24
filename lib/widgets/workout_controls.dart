import 'package:flutter/material.dart';
import '../services/workout_service.dart';

/// Renders workout control buttons based on current workout state
class WorkoutControls extends StatelessWidget {
  final WorkoutState workoutState;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onFinish;

  const WorkoutControls({
    super.key,
    required this.workoutState,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onRestart,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: _buildButtons(),
      ),
    );
  }

  List<Widget> _buildButtons() {
    switch (workoutState) {
      case WorkoutState.idle:
        return [
          _WorkoutButton(
            icon: Icons.play_arrow_rounded,
            label: 'Start',
            onTap: onStart,
            isPrimary: true,
          ),
        ];

      case WorkoutState.active:
        // Only show Pause when running - Finish requires pausing first
        return [
          _WorkoutButton(
            icon: Icons.pause_rounded,
            label: 'Pause',
            onTap: onPause,
            isPrimary: true,
          ),
        ];

      case WorkoutState.paused:
        return [
          _WorkoutButton(
            icon: Icons.play_arrow_rounded,
            label: 'Resume',
            onTap: onResume,
            isPrimary: true,
          ),
          _WorkoutButton(
            icon: Icons.restart_alt_rounded,
            label: 'Restart',
            onTap: onRestart,
            isPrimary: false,
          ),
          _WorkoutButton(
            icon: Icons.stop_rounded,
            label: 'Finish',
            onTap: onFinish,
            isPrimary: false,
          ),
        ];

      case WorkoutState.finished:
        return [];
    }
  }
}

class _WorkoutButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _WorkoutButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withValues(alpha: isPrimary ? 0.4 : 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
