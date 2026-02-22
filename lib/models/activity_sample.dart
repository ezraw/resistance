/// A single time-series sample for an activity (typically 1 per second).
class ActivitySample {
  final int? id;
  final int? activityId;
  final DateTime timestamp;
  final int? heartRate;
  final int? watts;
  final int? cadence;
  final double? speedMph;
  final int? resistance;

  ActivitySample({
    this.id,
    this.activityId,
    required this.timestamp,
    this.heartRate,
    this.watts,
    this.cadence,
    this.speedMph,
    this.resistance,
  });

  /// Create from a database row.
  factory ActivitySample.fromMap(Map<String, dynamic> map) {
    return ActivitySample(
      id: map['id'] as int?,
      activityId: map['activity_id'] as int?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      heartRate: map['heart_rate'] as int?,
      watts: map['watts'] as int?,
      cadence: map['cadence'] as int?,
      speedMph: (map['speed_mph'] as num?)?.toDouble(),
      resistance: map['resistance'] as int?,
    );
  }

  /// Convert to a database row map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (activityId != null) 'activity_id': activityId,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'heart_rate': heartRate,
      'watts': watts,
      'cadence': cadence,
      'speed_mph': speedMph,
      'resistance': resistance,
    };
  }
}
