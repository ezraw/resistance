import 'dart:async';

/// Workout state machine
enum WorkoutState {
  idle,
  active,
  paused,
  finished,
}

/// Heart rate reading with timestamp for HealthKit integration
class HeartRateReading {
  final int bpm;
  final DateTime timestamp;

  HeartRateReading({required this.bpm, required this.timestamp});
}

/// Trainer data reading with timestamp for activity history
class TrainerDataReading {
  final int watts;
  final double cadenceRpm;
  final double speedKmh;
  final DateTime timestamp;

  TrainerDataReading({
    required this.watts,
    required this.cadenceRpm,
    required this.speedKmh,
    required this.timestamp,
  });
}

/// Service for managing workout timer and state
class WorkoutService {
  final _stateController = StreamController<WorkoutState>.broadcast();
  final _elapsedController = StreamController<Duration>.broadcast();

  WorkoutState _currentState = WorkoutState.idle;
  Timer? _timer;
  DateTime? _startTime;
  DateTime? _workoutStartTime;  // Track absolute start time for HealthKit
  Duration _accumulated = Duration.zero;
  Duration _finalDuration = Duration.zero;

  // Heart rate tracking with timestamps for HealthKit
  final List<HeartRateReading> _heartRateReadings = [];
  int _maxHeartRate = 0;

  // Trainer data tracking (power, cadence, speed)
  final List<TrainerDataReading> _trainerDataReadings = [];
  int _maxWatts = 0;

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
    final sum = _heartRateReadings.fold(0, (sum, reading) => sum + reading.bpm);
    return (sum / _heartRateReadings.length).round();
  }

  /// Maximum heart rate during workout
  int get maxHeartRate => _maxHeartRate;

  /// Heart rate readings with timestamps for HealthKit
  List<HeartRateReading> get heartRateReadings => List.unmodifiable(_heartRateReadings);

  /// Trainer data readings with timestamps for activity history
  List<TrainerDataReading> get trainerDataReadings => List.unmodifiable(_trainerDataReadings);

  /// Average watts during workout (0 if no readings)
  int get averageWatts {
    if (_trainerDataReadings.isEmpty) return 0;
    final sum = _trainerDataReadings.fold(0, (sum, r) => sum + r.watts);
    return (sum / _trainerDataReadings.length).round();
  }

  /// Maximum watts during workout
  int get maxWatts => _maxWatts;

  /// Average cadence during workout (0 if no readings)
  int get averageCadence {
    if (_trainerDataReadings.isEmpty) return 0;
    final sum = _trainerDataReadings.fold(0.0, (sum, r) => sum + r.cadenceRpm);
    return (sum / _trainerDataReadings.length).round();
  }

  /// Average speed in mph during workout (0 if no readings)
  double get averageSpeedMph {
    if (_trainerDataReadings.isEmpty) return 0.0;
    final sum = _trainerDataReadings.fold(0.0, (sum, r) => sum + r.speedKmh);
    final avgKmh = sum / _trainerDataReadings.length;
    return avgKmh * 0.621371;
  }

  /// Maximum speed in mph during workout
  double get maxSpeedMph {
    if (_trainerDataReadings.isEmpty) return 0.0;
    final maxKmh = _trainerDataReadings.fold(0.0, (max, r) => r.speedKmh > max ? r.speedKmh : max);
    return maxKmh * 0.621371;
  }

  /// Workout start time for HealthKit
  DateTime? get workoutStartTime => _workoutStartTime;

  /// Whether workout is currently active (not paused)
  bool get isActive => _currentState == WorkoutState.active;

  /// Whether workout is in progress (active or paused)
  bool get isInProgress =>
      _currentState == WorkoutState.active || _currentState == WorkoutState.paused;

  /// Start the workout
  void start() {
    if (_currentState != WorkoutState.idle) return;

    final now = DateTime.now();
    _startTime = now;
    _workoutStartTime = now;  // Track for HealthKit
    _accumulated = Duration.zero;
    _heartRateReadings.clear();
    _maxHeartRate = 0;
    _trainerDataReadings.clear();
    _maxWatts = 0;
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
    final now = DateTime.now();
    _startTime = now;
    _workoutStartTime = now;  // Track for HealthKit
    _accumulated = Duration.zero;
    _heartRateReadings.clear();
    _maxHeartRate = 0;
    _trainerDataReadings.clear();
    _maxWatts = 0;
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
    _workoutStartTime = null;
    _accumulated = Duration.zero;
    _finalDuration = Duration.zero;
    _heartRateReadings.clear();
    _maxHeartRate = 0;
    _trainerDataReadings.clear();
    _maxWatts = 0;
    _updateState(WorkoutState.idle);
  }

  /// Record a heart rate reading with timestamp (call this when HR updates during workout)
  void recordHeartRate(int bpm) {
    if (!isInProgress || bpm <= 0) return;

    _heartRateReadings.add(HeartRateReading(bpm: bpm, timestamp: DateTime.now()));
    if (bpm > _maxHeartRate) {
      _maxHeartRate = bpm;
    }
  }

  /// Record a trainer data reading with timestamp (call this when trainer data updates during workout)
  void recordTrainerData(int watts, double cadenceRpm, double speedKmh) {
    if (!isInProgress || watts <= 0) return;

    _trainerDataReadings.add(TrainerDataReading(
      watts: watts,
      cadenceRpm: cadenceRpm,
      speedKmh: speedKmh,
      timestamp: DateTime.now(),
    ));
    if (watts > _maxWatts) {
      _maxWatts = watts;
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
