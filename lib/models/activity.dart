import '../services/workout_service.dart';

/// A completed workout activity stored in the local database.
class Activity {
  final int? id;
  final DateTime startedAt;
  final int durationSeconds;
  final int? avgHeartRate;
  final int? maxHeartRate;
  final int? avgWatts;
  final int? maxWatts;
  final double? avgMph;
  final double? maxMph;
  final int? avgCadence;
  final int? avgResistance;
  final int? calories;
  final String? notes;
  final String source;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Activity({
    this.id,
    required this.startedAt,
    required this.durationSeconds,
    this.avgHeartRate,
    this.maxHeartRate,
    this.avgWatts,
    this.maxWatts,
    this.avgMph,
    this.maxMph,
    this.avgCadence,
    this.avgResistance,
    this.calories,
    this.notes,
    this.source = 'resistance_app',
    required this.createdAt,
    this.updatedAt,
  });

  /// Duration as a Dart Duration object.
  Duration get duration => Duration(seconds: durationSeconds);

  /// Create an Activity from a completed workout.
  factory Activity.fromWorkout(WorkoutService workoutService) {
    final now = DateTime.now().toUtc();
    final startTime = workoutService.workoutStartTime ?? now;
    final avgHr = workoutService.averageHeartRate;
    final maxHr = workoutService.maxHeartRate;
    final avgW = workoutService.averageWatts;
    final maxW = workoutService.maxWatts;
    final avgCad = workoutService.averageCadence;
    final avgSpd = workoutService.averageSpeedMph;
    final maxSpd = workoutService.maxSpeedMph;

    return Activity(
      startedAt: startTime.toUtc(),
      durationSeconds: workoutService.finalDuration.inSeconds,
      avgHeartRate: avgHr > 0 ? avgHr : null,
      maxHeartRate: maxHr > 0 ? maxHr : null,
      avgWatts: avgW > 0 ? avgW : null,
      maxWatts: maxW > 0 ? maxW : null,
      avgCadence: avgCad > 0 ? avgCad : null,
      avgMph: avgSpd > 0 ? avgSpd : null,
      maxMph: maxSpd > 0 ? maxSpd : null,
      source: 'resistance_app',
      createdAt: now,
    );
  }

  /// Create an Activity from a database row.
  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'] as int?,
      startedAt: DateTime.parse(map['started_at'] as String),
      durationSeconds: map['duration_seconds'] as int,
      avgHeartRate: map['avg_heart_rate'] as int?,
      maxHeartRate: map['max_heart_rate'] as int?,
      avgWatts: map['avg_watts'] as int?,
      maxWatts: map['max_watts'] as int?,
      avgMph: (map['avg_mph'] as num?)?.toDouble(),
      maxMph: (map['max_mph'] as num?)?.toDouble(),
      avgCadence: map['avg_cadence'] as int?,
      avgResistance: map['avg_resistance'] as int?,
      calories: map['calories'] as int?,
      notes: map['notes'] as String?,
      source: map['source'] as String? ?? 'resistance_app',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  /// Convert to a database row map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'started_at': startedAt.toUtc().toIso8601String(),
      'duration_seconds': durationSeconds,
      'avg_heart_rate': avgHeartRate,
      'max_heart_rate': maxHeartRate,
      'avg_watts': avgWatts,
      'max_watts': maxWatts,
      'avg_mph': avgMph,
      'max_mph': maxMph,
      'avg_cadence': avgCadence,
      'avg_resistance': avgResistance,
      'calories': calories,
      'notes': notes,
      'source': source,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt?.toUtc().toIso8601String(),
    };
  }
}
