import 'dart:async';

/// Workout state machine
enum WorkoutState {
  idle,
  active,
  paused,
  finished,
}

/// Service for managing workout timer and state
class WorkoutService {
  final _stateController = StreamController<WorkoutState>.broadcast();
  final _elapsedController = StreamController<Duration>.broadcast();

  WorkoutState _currentState = WorkoutState.idle;
  Timer? _timer;
  DateTime? _startTime;
  Duration _accumulated = Duration.zero;
  Duration _finalDuration = Duration.zero;

  // Heart rate tracking
  final List<int> _heartRateReadings = [];
  int _maxHeartRate = 0;

  /// Stream of workout state changes
  Stream<WorkoutState> get stateStream => _stateController.stream;

  /// Stream of elapsed time updates (emits every second while active)
  Stream<Duration> get elapsedStream => _elapsedController.stream;

  /// Current workout state
  WorkoutState get currentState => _currentState;

  /// Current elapsed time
  Duration get elapsed => _accumulated +
      (_startTime != null ? DateTime.now().difference(_startTime!) : Duration.zero);

  /// Final workout duration (only valid after finishing)
  Duration get finalDuration => _finalDuration;

  /// Average heart rate during workout (0 if no readings)
  int get averageHeartRate {
    if (_heartRateReadings.isEmpty) return 0;
    return (_heartRateReadings.reduce((a, b) => a + b) / _heartRateReadings.length).round();
  }

  /// Maximum heart rate during workout
  int get maxHeartRate => _maxHeartRate;

  /// Whether workout is currently active (not paused)
  bool get isActive => _currentState == WorkoutState.active;

  /// Whether workout is in progress (active or paused)
  bool get isInProgress =>
      _currentState == WorkoutState.active || _currentState == WorkoutState.paused;

  /// Start the workout
  void start() {
    if (_currentState != WorkoutState.idle) return;

    _startTime = DateTime.now();
    _accumulated = Duration.zero;
    _heartRateReadings.clear();
    _maxHeartRate = 0;
    _updateState(WorkoutState.active);
    _startTimer();
  }

  /// Pause the workout
  void pause() {
    if (_currentState != WorkoutState.active) return;

    // Accumulate elapsed time
    if (_startTime != null) {
      _accumulated += DateTime.now().difference(_startTime!);
      _startTime = null;
    }
    _stopTimer();
    _updateState(WorkoutState.paused);
  }

  /// Resume a paused workout
  void resume() {
    if (_currentState != WorkoutState.paused) return;

    _startTime = DateTime.now();
    _updateState(WorkoutState.active);
    _startTimer();
  }

  /// Restart the workout (reset timer and state)
  void restart() {
    _stopTimer();
    _startTime = DateTime.now();
    _accumulated = Duration.zero;
    _heartRateReadings.clear();
    _maxHeartRate = 0;
    _updateState(WorkoutState.active);
    _elapsedController.add(Duration.zero);
    _startTimer();
  }

  /// Finish the workout
  void finish() {
    if (_currentState == WorkoutState.idle || _currentState == WorkoutState.finished) {
      return;
    }

    // Calculate final duration
    _finalDuration = elapsed;
    _stopTimer();
    _startTime = null;
    _accumulated = Duration.zero;
    _updateState(WorkoutState.finished);
  }

  /// Reset to idle state (after viewing summary)
  void reset() {
    _stopTimer();
    _startTime = null;
    _accumulated = Duration.zero;
    _finalDuration = Duration.zero;
    _heartRateReadings.clear();
    _maxHeartRate = 0;
    _updateState(WorkoutState.idle);
  }

  /// Record a heart rate reading (call this when HR updates during workout)
  void recordHeartRate(int bpm) {
    if (!isInProgress || bpm <= 0) return;

    _heartRateReadings.add(bpm);
    if (bpm > _maxHeartRate) {
      _maxHeartRate = bpm;
    }
  }

  /// Clean up resources
  void dispose() {
    _stopTimer();
    _stateController.close();
    _elapsedController.close();
  }

  // Private methods

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedController.add(elapsed);
    });
    // Emit immediately
    _elapsedController.add(elapsed);
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _updateState(WorkoutState state) {
    _currentState = state;
    _stateController.add(state);
  }
}
