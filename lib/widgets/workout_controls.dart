import 'package:flutter/material.dart';
import '../services/workout_service.dart';
import '../theme/app_colors.dart';
import '../theme/accessibility.dart';
import 'arcade/arcade_badge.dart';
import 'arcade/arcade_button.dart';
import 'arcade/pixel_icon.dart';

/// Renders workout control buttons based on current workout state.
/// The START button throbs when idle to invite interaction.
class WorkoutControls extends StatefulWidget {
  final WorkoutState workoutState;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onFinish;
  final VoidCallback? onHistory;
  final Duration? elapsed;

  const WorkoutControls({
    super.key,
    required this.workoutState,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onRestart,
    required this.onFinish,
    this.onHistory,
    this.elapsed,
  });

  @override
  State<WorkoutControls> createState() => _WorkoutControlsState();
}

class _WorkoutControlsState extends State<WorkoutControls>
    with SingleTickerProviderStateMixin {
  late AnimationController _throbController;
  late Animation<double> _throbAnimation;

  @override
  void initState() {
    super.initState();
    _throbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _throbAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _throbController, curve: Curves.easeInOut),
    );
    if (widget.workoutState == WorkoutState.idle) {
      _throbController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(WorkoutControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.workoutState == WorkoutState.idle && !_throbController.isAnimating) {
      _throbController.repeat(reverse: true);
    } else if (widget.workoutState != WorkoutState.idle && _throbController.isAnimating) {
      _throbController.stop();
      _throbController.reset();
    }
  }

  @override
  void dispose() {
    _throbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: _buildButtons(context),
      ),
    );
  }

  List<Widget> _buildButtons(BuildContext context) {
    final reduceMotion = Accessibility.reduceMotion(context);

    switch (widget.workoutState) {
      case WorkoutState.idle:
        final startButton = ArcadeButton(
          label: 'START',
          icon: const PixelIcon.play(size: 16, color: AppColors.nightPlum),
          onTap: widget.onStart,
          scheme: ArcadeButtonScheme.gold,
        );
        final throbbing = reduceMotion
            ? startButton
            : AnimatedBuilder(
                animation: _throbAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _throbAnimation.value,
                    child: child,
                  );
                },
                child: startButton,
              );
        return [
          throbbing,
          if (widget.onHistory != null)
            ArcadeButton(
              label: 'HISTORY',
              icon: const PixelIcon.list(size: 16, color: AppColors.nightPlum),
              onTap: widget.onHistory,
              scheme: ArcadeButtonScheme.gold,
              minWidth: 140,
            ),
        ];

      case WorkoutState.active:
        return [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ArcadeButton(
                label: 'PAUSE',
                icon: const PixelIcon.pause(size: 16, color: AppColors.white),
                onTap: widget.onPause,
                scheme: ArcadeButtonScheme.magenta,
                minWidth: 200,
              ),
              if (widget.elapsed != null) ...[
                const SizedBox(height: 8),
                ArcadeBadge(
                  icon: const PixelIcon.stopwatch(size: 12),
                  text: _formatDuration(widget.elapsed!),
                  borderColor: AppColors.electricViolet,
                ),
              ],
            ],
          ),
        ];

      case WorkoutState.paused:
        return [
          ArcadeButton(
            label: 'RESUME',
            icon: const PixelIcon.play(size: 16, color: AppColors.nightPlum),
            onTap: widget.onResume,
            scheme: ArcadeButtonScheme.gold,
          ),
          ArcadeButton(
            label: 'RESTART',
            icon: const PixelIcon.restart(size: 16, color: AppColors.white),
            onTap: widget.onRestart,
            scheme: ArcadeButtonScheme.orange,
            minWidth: 100,
          ),
          ArcadeButton(
            label: 'FINISH',
            icon: const PixelIcon.stop(size: 16, color: AppColors.white),
            onTap: widget.onFinish,
            scheme: ArcadeButtonScheme.red,
            minWidth: 100,
          ),
        ];

      case WorkoutState.finished:
        return [];
    }
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
