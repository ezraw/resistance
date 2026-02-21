import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../services/ble_service.dart';
import '../services/workout_service.dart';
import '../services/hr_service.dart';
import '../services/health_service.dart';
import '../theme/app_colors.dart';
import '../theme/page_transitions.dart';
import '../widgets/resistance_control.dart';
import '../widgets/workout_stats_bar.dart';
import '../widgets/workout_controls.dart';
import '../widgets/arcade_background.dart';
import '../widgets/arcade/arcade_badge.dart';
import '../widgets/arcade/pixel_icon.dart';
import 'scan_screen.dart';
import 'workout_summary_screen.dart';
import 'hr_scan_sheet.dart';

class HomeScreen extends StatefulWidget {
  final BleService bleService;
  final WorkoutService workoutService;
  final HrService hrService;
  final HealthService healthService;

  const HomeScreen({
    super.key,
    required this.bleService,
    required this.workoutService,
    required this.hrService,
    required this.healthService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentLevel;
  StreamSubscription<TrainerConnectionState>? _connectionSubscription;
  StreamSubscription<int>? _resistanceSubscription;
  StreamSubscription<WorkoutState>? _workoutStateSubscription;
  StreamSubscription<Duration>? _elapsedSubscription;
  StreamSubscription<HrConnectionState>? _hrConnectionSubscription;
  StreamSubscription<int>? _hrSubscription;
  Timer? _debounceTimer;
  int _pendingLevel = 0;
  bool _hasPendingUpdate = false;

  TrainerConnectionState _trainerState = TrainerConnectionState.connected;
  WorkoutState _workoutState = WorkoutState.idle;
  Duration _elapsed = Duration.zero;
  int? _heartRate;
  bool _hrConnected = false;

  @override
  void initState() {
    super.initState();
    _currentLevel = widget.bleService.currentResistanceLevel;
    _workoutState = widget.workoutService.currentState;
    _hrConnected = widget.hrService.isConnected;
    _heartRate = widget.hrService.isConnected ? widget.hrService.currentHeartRate : null;

    _connectionSubscription = widget.bleService.connectionState.listen(_onConnectionStateChanged);
    _resistanceSubscription = widget.bleService.resistanceLevel.listen(_onResistanceLevelChanged);
    _workoutStateSubscription = widget.workoutService.stateStream.listen(_onWorkoutStateChanged);
    _elapsedSubscription = widget.workoutService.elapsedStream.listen(_onElapsedChanged);
    _hrConnectionSubscription = widget.hrService.connectionState.listen(_onHrConnectionStateChanged);
    _hrSubscription = widget.hrService.heartRate.listen(_onHeartRateChanged);

    // Hide status bar for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Keep screen awake during use
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    // Restore status bar when leaving
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // Allow screen to sleep again
    WakelockPlus.disable();
    _connectionSubscription?.cancel();
    _resistanceSubscription?.cancel();
    _workoutStateSubscription?.cancel();
    _elapsedSubscription?.cancel();
    _hrConnectionSubscription?.cancel();
    _hrSubscription?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onConnectionStateChanged(TrainerConnectionState state) {
    if (!mounted) return;

    // Force rebuild for any connection state change (including degraded)
    setState(() {});

    if (state == TrainerConnectionState.degraded) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resistance control lost. Attempting recovery...'),
          backgroundColor: Colors.amber,
          duration: Duration(seconds: 4),
        ),
      );
    } else if (state == TrainerConnectionState.connected &&
        _trainerState == TrainerConnectionState.degraded) {
      // Recovered from degraded
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection recovered.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else if (state == TrainerConnectionState.disconnected) {
      // Pause workout if trainer disconnects
      if (_workoutState == WorkoutState.active) {
        widget.workoutService.pause();
        _showDisconnectWarning();
      } else {
        // Go back to scan screen
        Navigator.of(context).pushReplacement(
          ArcadePageRoute(
            page: ScanScreen(
              bleService: widget.bleService,
              workoutService: widget.workoutService,
              hrService: widget.hrService,
              healthService: widget.healthService,
            ),
            transition: ArcadeTransition.fadeScale,
          ),
        );
      }
    }

    _trainerState = state;
  }

  void _showDisconnectWarning() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Trainer disconnected. Workout paused.'),
        backgroundColor: Colors.orange,
        action: SnackBarAction(
          label: 'Reconnect',
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => ScanScreen(
                  bleService: widget.bleService,
                  workoutService: widget.workoutService,
                  hrService: widget.hrService,
                  healthService: widget.healthService,
                ),
              ),
            );
          },
        ),
        duration: const Duration(seconds: 10),
      ),
    );
  }

  void _onResistanceLevelChanged(int level) {
    // Ignore BLE confirmations while we have a pending debounced update
    // to prevent the display from bouncing during rapid tapping
    if (_hasPendingUpdate) return;

    if (mounted) {
      setState(() {
        _currentLevel = level;
      });
    }
  }

  void _onWorkoutStateChanged(WorkoutState state) {
    if (!mounted) return;

    setState(() {
      _workoutState = state;
    });

    if (state == WorkoutState.finished) {
      _navigateToSummary();
    }
  }

  void _onElapsedChanged(Duration elapsed) {
    if (mounted) {
      setState(() {
        _elapsed = elapsed;
      });
    }
  }

  void _onHrConnectionStateChanged(HrConnectionState state) {
    if (mounted) {
      setState(() {
        _hrConnected = state == HrConnectionState.connected;
        if (!_hrConnected) {
          _heartRate = null;
        }
      });
    }
  }

  void _onHeartRateChanged(int hr) {
    if (mounted) {
      setState(() {
        _heartRate = hr > 0 ? hr : null;
      });

      // Record HR for workout stats if workout is in progress
      if (widget.workoutService.isInProgress && hr > 0) {
        widget.workoutService.recordHeartRate(hr);
      }
    }
  }

  void _navigateToSummary() {
    Navigator.of(context).push(
      ArcadePageRoute(
        page: WorkoutSummaryScreen(
          workoutService: widget.workoutService,
          bleService: widget.bleService,
          healthService: widget.healthService,
        ),
        transition: ArcadeTransition.slideUp,
      ),
    );
  }

  void _openHrScanSheet() {
    HrScanSheet.show(context, widget.hrService);
  }

  void _increaseResistance() {
    if (_currentLevel >= 100) return;

    // Immediate haptic feedback (light is faster than medium)
    HapticFeedback.lightImpact();

    // Immediate UI update
    setState(() {
      _currentLevel = (_currentLevel + 5).clamp(0, 100);
    });

    // Debounced BLE update - wait for rapid taps to finish
    _scheduleBleUpdate(_currentLevel);
  }

  void _decreaseResistance() {
    if (_currentLevel <= 0) return;

    // Immediate haptic feedback (light is faster than medium)
    HapticFeedback.lightImpact();

    // Immediate UI update
    setState(() {
      _currentLevel = (_currentLevel - 5).clamp(0, 100);
    });

    // Debounced BLE update - wait for rapid taps to finish
    _scheduleBleUpdate(_currentLevel);
  }

  void _scheduleBleUpdate(int level) {
    _pendingLevel = level;
    _hasPendingUpdate = true;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      _sendBleUpdate(_pendingLevel);
    });
  }

  Future<void> _sendBleUpdate(int level) async {
    final success = await widget.bleService.setResistanceLevel(level);
    _hasPendingUpdate = false;
    if (!success && mounted) {
      // Revert to actual trainer level on failure
      setState(() {
        _currentLevel = widget.bleService.currentResistanceLevel;
      });
      // Show failure feedback (only if not already in degraded state to avoid spam)
      if (!widget.bleService.isDegraded) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to set resistance'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _disconnect() async {
    await widget.bleService.disconnect();
  }

  void _showDisconnectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect'),
        content: Text(_workoutState == WorkoutState.idle
            ? 'Disconnect from trainer?'
            : 'Disconnect from trainer? Your workout will be paused.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _disconnect();
            },
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }

  // Workout control handlers
  void _startWorkout() {
    HapticFeedback.mediumImpact();
    widget.workoutService.start();
  }

  void _pauseWorkout() {
    HapticFeedback.lightImpact();
    widget.workoutService.pause();
  }

  void _resumeWorkout() {
    HapticFeedback.mediumImpact();
    widget.workoutService.resume();
  }

  void _restartWorkout() {
    HapticFeedback.mediumImpact();
    widget.workoutService.restart();
  }

  void _finishWorkout() {
    HapticFeedback.heavyImpact();
    widget.workoutService.finish();
  }

  @override
  Widget build(BuildContext context) {
    final isWorkoutInProgress = widget.workoutService.isInProgress;

    return Scaffold(
      body: ArcadeBackground(
        resistanceLevel: _currentLevel,
        isActive: _workoutState == WorkoutState.active,
        child: Stack(
          children: [
            // Main resistance control (full screen)
            ResistanceControl(
              currentLevel: _currentLevel,
              onIncrease: _increaseResistance,
              onDecrease: _decreaseResistance,
            ),

            // Workout stats bar (top) - only show during workout
            if (isWorkoutInProgress)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: WorkoutStatsBar(
                  elapsed: _elapsed,
                  heartRate: _heartRate,
                  hrConnected: _hrConnected,
                  isConnectionDegraded: widget.bleService.isDegraded,
                  onHrTap: _openHrScanSheet,
                ),
              ),

            // Connection indicator (top-left) - only show when not in workout
            if (!isWorkoutInProgress)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                child: GestureDetector(
                  onLongPress: _showDisconnectDialog,
                  child: _buildConnectionIndicator(),
                ),
              ),

            // HR indicator (top-right) - only show when not in workout
            if (!isWorkoutInProgress)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 16,
                child: GestureDetector(
                  onTap: _openHrScanSheet,
                  child: _buildHrIndicator(),
                ),
              ),

            // Workout controls (bottom)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 0,
              right: 0,
              child: WorkoutControls(
                workoutState: _workoutState,
                onStart: _startWorkout,
                onPause: _pauseWorkout,
                onResume: _resumeWorkout,
                onRestart: _restartWorkout,
                onFinish: _finishWorkout,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionIndicator() {
    final String label;
    final Color borderColor;
    final PixelIcon icon;
    if (widget.bleService.isDegraded) {
      label = 'RECONNECTING';
      borderColor = AppColors.amber;
      icon = const PixelIcon.warning(size: 12, color: AppColors.amber);
    } else if (widget.bleService.isConnected) {
      label = 'CONNECTED';
      borderColor = AppColors.green;
      icon = const PixelIcon.greenDot(size: 12, color: AppColors.green);
    } else {
      label = 'DISCONNECTED';
      borderColor = AppColors.red;
      icon = const PixelIcon.greenDot(size: 12, color: AppColors.red);
    }

    return ArcadeBadge(
      icon: icon,
      text: label,
      borderColor: borderColor,
    );
  }

  Widget _buildHrIndicator() {
    return ArcadeBadge(
      icon: PixelIcon.heart(
        size: 14,
        color: _hrConnected ? AppColors.red : AppColors.white.withValues(alpha: 0.5),
      ),
      text: _hrConnected && _heartRate != null ? '$_heartRate BPM' : 'HR',
      borderColor: AppColors.magenta,
    );
  }
}
