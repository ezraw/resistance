import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import '../services/workout_service.dart';
import '../services/ble_service.dart';
import '../services/health_service.dart';

class WorkoutSummaryScreen extends StatefulWidget {
  final WorkoutService workoutService;
  final BleService bleService;
  final HealthService healthService;

  const WorkoutSummaryScreen({
    super.key,
    required this.workoutService,
    required this.bleService,
    required this.healthService,
  });

  @override
  State<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends State<WorkoutSummaryScreen> {
  late ConfettiController _confettiController;

  // HealthKit save state
  bool _healthSaving = false;
  bool? _healthSaveSuccess;

  @override
  void initState() {
    super.initState();
    // Restore system UI for summary screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Initialize and start confetti animation
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();

    // Auto-save to HealthKit
    _saveToHealthKit();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _saveToHealthKit() async {
    if (!widget.healthService.isAvailable) return;

    final startTime = widget.workoutService.workoutStartTime;
    if (startTime == null) return;

    setState(() {
      _healthSaving = true;
    });

    final success = await widget.healthService.saveWorkout(
      startTime: startTime,
      duration: widget.workoutService.finalDuration,
      heartRateReadings: widget.workoutService.heartRateReadings,
    );

    if (mounted) {
      setState(() {
        _healthSaving = false;
        _healthSaveSuccess = success;
      });
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  void _done() {
    HapticFeedback.mediumImpact();
    widget.workoutService.reset();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.workoutService.finalDuration;
    final avgHr = widget.workoutService.averageHeartRate;
    final maxHr = widget.workoutService.maxHeartRate;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),

                  // Title
                  const Icon(
                    Icons.emoji_events,
                    size: 80,
                    color: Color(0xFFFFD700),
                  ),
              const SizedBox(height: 16),
              const Text(
                'Workout Complete!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 48),

              // Stats
              _buildStatCard(
                icon: Icons.timer,
                label: 'Duration',
                value: _formatDuration(duration),
                color: Colors.blue,
              ),

              const SizedBox(height: 16),

              // Heart rate stats (only show if we have HR data)
              if (avgHr > 0) ...[
                _buildStatCard(
                  icon: Icons.favorite,
                  label: 'Avg Heart Rate',
                  value: '$avgHr bpm',
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                _buildStatCard(
                  icon: Icons.favorite,
                  label: 'Max Heart Rate',
                  value: '$maxHr bpm',
                  color: Colors.orange,
                ),
              ],

              // Placeholder when no HR data
              if (avgHr == 0)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.favorite_border,
                        color: Colors.white.withValues(alpha: 0.3),
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Connect a heart rate monitor during your next workout to track HR data',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // HealthKit save status
              if (widget.healthService.isAvailable) ...[
                const SizedBox(height: 24),
                _buildHealthKitStatus(),
              ],

              const Spacer(),

              // Done button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _done,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1A1A2E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
          ),

          // Confetti animation from top center
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.red,
                Colors.orange,
                Colors.yellow,
                Colors.green,
                Colors.blue,
                Colors.purple,
                Colors.pink,
              ],
              numberOfParticles: 30,
              gravity: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthKitStatus() {
    if (_healthSaving) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white54,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Saving to Apple Health...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    if (_healthSaveSuccess == true) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Saved to Apple Health',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    if (_healthSaveSuccess == false) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.info_outline,
            color: Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Could not save to Apple Health',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
