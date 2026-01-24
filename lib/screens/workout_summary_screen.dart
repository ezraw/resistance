import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/workout_service.dart';
import '../services/ble_service.dart';

class WorkoutSummaryScreen extends StatefulWidget {
  final WorkoutService workoutService;
  final BleService bleService;

  const WorkoutSummaryScreen({
    super.key,
    required this.workoutService,
    required this.bleService,
  });

  @override
  State<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends State<WorkoutSummaryScreen> {
  @override
  void initState() {
    super.initState();
    // Restore system UI for summary screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    super.dispose();
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
      body: SafeArea(
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
    );
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
