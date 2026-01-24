import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ble_service.dart';
import '../services/workout_service.dart';
import '../services/hr_service.dart';
import '../services/health_service.dart';
import '../widgets/resistance_control.dart';
import '../widgets/workout_stats_bar.dart';
import '../widgets/workout_controls.dart';
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
  }

  @override
  void dispose() {
    // Restore status bar when leaving
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
    if (state == TrainerConnectionState.disconnected && mounted) {
      // Pause workout if trainer disconnects
      if (_workoutState == WorkoutState.active) {
        widget.workoutService.pause();
        _showDisconnectWarning();
      } else {
        // Go back to scan screen
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
      }
    }
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
      MaterialPageRoute(
        builder: (context) => WorkoutSummaryScreen(
          workoutService: widget.workoutService,
          bleService: widget.bleService,
          healthService: widget.healthService,
        ),
      ),
    );
  }

  void _openHrScanSheet() {
    HrScanSheet.show(context, widget.hrService);
  }

  void _increaseResistance() {
    if (_currentLevel >= 10) return;

    // Immediate haptic feedback (light is faster than medium)
    HapticFeedback.lightImpact();

    // Immediate UI update
    setState(() {
      _currentLevel = (_currentLevel + 1).clamp(1, 10);
    });

    // Debounced BLE update - wait for rapid taps to finish
    _scheduleBleUpdate(_currentLevel);
  }

  void _decreaseResistance() {
    if (_currentLevel <= 1) return;

    // Immediate haptic feedback (light is faster than medium)
    HapticFeedback.lightImpact();

    // Immediate UI update
    setState(() {
      _currentLevel = (_currentLevel - 1).clamp(1, 10);
    });

    // Debounced BLE update - wait for rapid taps to finish
    _scheduleBleUpdate(_currentLevel);
  }

  void _scheduleBleUpdate(int level) {
    _pendingLevel = level;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      _sendBleUpdate(_pendingLevel);
    });
  }

  Future<void> _sendBleUpdate(int level) async {
    final success = await widget.bleService.setResistanceLevel(level);
    if (!success && mounted) {
      // Revert to actual trainer level on failure
      setState(() {
        _currentLevel = widget.bleService.currentResistanceLevel;
      });
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
      body: Stack(
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
    );
  }

  Widget _buildConnectionIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.bleService.isConnected ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            widget.bleService.isConnected ? 'Connected' : 'Disconnected',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHrIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _hrConnected ? Icons.favorite : Icons.favorite_border,
            color: _hrConnected ? Colors.red : Colors.white.withValues(alpha: 0.7),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            _hrConnected && _heartRate != null ? '$_heartRate bpm' : 'HR',
            style: TextStyle(
              color: _hrConnected ? Colors.white : Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
