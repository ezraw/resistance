import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/workout_service.dart';
import '../services/ble_service.dart';
import '../services/health_service.dart';
import '../services/activity_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/arcade_background.dart';
import '../widgets/arcade/arcade_panel.dart';
import '../widgets/arcade/arcade_button.dart';
import '../widgets/arcade/pixel_icon.dart';
import '../models/activity.dart';
import '../models/activity_sample.dart';
import '../painters/resistance_band_config.dart';
import '../painters/pixel_celebration_painter.dart';
import '../theme/page_transitions.dart';
import 'activity_list_screen.dart';

class WorkoutSummaryScreen extends StatefulWidget {
  final WorkoutService workoutService;
  final BleService bleService;
  final HealthService healthService;
  final ActivityService activityService;

  const WorkoutSummaryScreen({
    super.key,
    required this.workoutService,
    required this.bleService,
    required this.healthService,
    required this.activityService,
  });

  @override
  State<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends State<WorkoutSummaryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _celebrationController;
  late String _affirmation;

  bool _healthSaving = false;
  bool? _healthSaveSuccess;

  static const _affirmations = [
    'GREAT JOB OUT THERE TODAY!',
    'I SEE YOU PUTTING IN THE WORK!',
    'ANOTHER ONE IN THE BOOKS!',
    'YOU SHOWED UP AND THAT MATTERS!',
    'STRONGER EVERY SESSION!',
    'CONSISTENCY IS YOUR SUPERPOWER!',
    'YOU CRUSHED IT!',
    'THAT WAS ALL YOU!',
    'HARD WORK LOOKS GOOD ON YOU!',
    'RESPECT THE GRIND!',
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _affirmation = _affirmations[Random().nextInt(_affirmations.length)];

    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    _saveToHealthKit();
    _saveToActivityHistory();
  }

  @override
  void dispose() {
    _celebrationController.dispose();
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

  Future<void> _saveToActivityHistory() async {
    try {
      final activity = Activity.fromWorkout(widget.workoutService);
      final samples = _mergeReadingsIntoSamples();
      await widget.activityService.insertWithSamples(activity, samples);
    } catch (e) {
      debugPrint('Failed to save activity history: $e');
    }
  }

  /// Merge HR readings and trainer data readings into unified per-second ActivitySamples.
  ///
  /// HR and trainer data arrive from different BLE devices at potentially different rates.
  /// We floor each timestamp to the nearest second and merge into one sample per second.
  List<ActivitySample> _mergeReadingsIntoSamples() {
    final sampleMap = <int, _MergedSample>{};

    // Add HR readings
    for (final r in widget.workoutService.heartRateReadings) {
      final key = r.timestamp.millisecondsSinceEpoch ~/ 1000;
      final existing = sampleMap[key];
      if (existing != null) {
        existing.heartRate = r.bpm;
      } else {
        sampleMap[key] = _MergedSample(
          timestamp: DateTime.fromMillisecondsSinceEpoch(key * 1000, isUtc: r.timestamp.isUtc),
          heartRate: r.bpm,
        );
      }
    }

    // Add trainer data readings
    for (final r in widget.workoutService.trainerDataReadings) {
      final key = r.timestamp.millisecondsSinceEpoch ~/ 1000;
      final existing = sampleMap[key];
      if (existing != null) {
        existing.watts = r.watts;
        existing.cadence = r.cadenceRpm.round();
        existing.speedMph = r.speedKmh * 0.621371;
      } else {
        sampleMap[key] = _MergedSample(
          timestamp: DateTime.fromMillisecondsSinceEpoch(key * 1000, isUtc: r.timestamp.isUtc),
          watts: r.watts,
          cadence: r.cadenceRpm.round(),
          speedMph: r.speedKmh * 0.621371,
        );
      }
    }

    // Sort by timestamp and convert to ActivitySample
    final sortedKeys = sampleMap.keys.toList()..sort();
    return sortedKeys.map((key) {
      final m = sampleMap[key]!;
      return ActivitySample(
        timestamp: m.timestamp,
        heartRate: m.heartRate,
        watts: m.watts,
        cadence: m.cadence,
        speedMph: m.speedMph,
      );
    }).toList();
  }

  void _openHistory() {
    Navigator.of(context).push(
      ArcadePageRoute(
        page: ActivityListScreen(activityService: widget.activityService),
        transition: ArcadeTransition.slideRight,
      ),
    );
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
      body: Stack(
        children: [
          // Arcade background
          ArcadeBackground(
            config: ResistanceBandConfig.summary,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Scrollable content area
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Title — dominant element
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'WORKOUT\nCOMPLETE!',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.button(fontSize: 32, color: AppColors.gold),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _affirmation,
                                textAlign: TextAlign.center,
                                style: AppTypography.secondary(fontSize: 8),
                              ),

                              const SizedBox(height: 32),

                              // Stats
                              _buildStatCard(
                                icon: const PixelIcon.stopwatch(size: 24),
                                label: 'DURATION',
                                value: _formatDuration(duration),
                                borderColor: AppColors.neonCyan,
                              ),

                              const SizedBox(height: 12),

                              if (avgHr > 0) ...[
                                _buildStatCard(
                                  icon: const PixelIcon.heart(size: 24),
                                  label: 'AVG HEART RATE',
                                  value: '$avgHr BPM',
                                  borderColor: AppColors.magenta,
                                ),
                                const SizedBox(height: 12),
                                _buildStatCard(
                                  icon: const PixelIcon.heart(size: 24),
                                  label: 'MAX HEART RATE',
                                  value: '$maxHr BPM',
                                  borderColor: AppColors.hotPink,
                                ),
                              ],

                              if (avgHr == 0)
                                ArcadePanel.secondary(
                                  borderColor: AppColors.electricViolet.withValues(alpha: 0.3),
                                  child: Row(
                                    children: [
                                      PixelIcon.heart(
                                        size: 20,
                                        color: AppColors.white.withValues(alpha: 0.3),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'CONNECT A HEART RATE MONITOR\nDURING YOUR NEXT WORKOUT',
                                          style: AppTypography.secondary(fontSize: 6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // HealthKit save status
                              if (widget.healthService.isAvailable) ...[
                                const SizedBox(height: 20),
                                _buildHealthKitStatus(),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Done + History buttons — pinned at bottom
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ArcadeButton(
                          label: 'DONE',
                          icon: const PixelIcon.check(size: 16, color: AppColors.nightPlum),
                          onTap: _done,
                          scheme: ArcadeButtonScheme.gold,
                          minWidth: 140,
                        ),
                        const SizedBox(width: 12),
                        ArcadeButton(
                          label: 'HISTORY',
                          icon: const PixelIcon.list(size: 16, color: AppColors.nightPlum),
                          onTap: _openHistory,
                          scheme: ArcadeButtonScheme.gold,
                          minWidth: 140,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Pixel celebration
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _celebrationController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: PixelCelebrationPainter(
                      progress: _celebrationController.value,
                    ),
                  );
                },
              ),
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
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.warmCream,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'SAVING TO APPLE HEALTH...',
            style: AppTypography.secondary(fontSize: 7),
          ),
        ],
      );
    }

    if (_healthSaveSuccess == true) {
      return Text(
        'SAVED TO APPLE HEALTH',
        style: AppTypography.label(fontSize: 7, color: AppColors.green),
      );
    }

    if (_healthSaveSuccess == false) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const PixelIcon.warning(size: 12),
          const SizedBox(width: 8),
          Text(
            'COULD NOT SAVE TO APPLE HEALTH',
            style: AppTypography.label(fontSize: 7, color: AppColors.amber),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildStatCard({
    required Widget icon,
    required String label,
    required String value,
    required Color borderColor,
  }) {
    return ArcadePanel.secondary(
      borderColor: borderColor,
      child: Row(
        children: [
          icon,
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.secondary(fontSize: 7),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTypography.number(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Mutable container for merging HR and trainer data by second.
class _MergedSample {
  final DateTime timestamp;
  int? heartRate;
  int? watts;
  int? cadence;
  double? speedMph;

  _MergedSample({
    required this.timestamp,
    this.heartRate,
    this.watts,
    this.cadence,
    this.speedMph,
  });
}
