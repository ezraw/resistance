import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'workout_service.dart';

/// Service for saving workout data to Apple HealthKit
class HealthService {
  bool _authorized = false;
  bool _authRequested = false;

  /// Whether HealthKit is available on this device
  bool get isAvailable => Platform.isIOS;

  /// Whether we have HealthKit authorization
  bool get isAuthorized => _authorized;

  /// Request authorization to read/write workout and heart rate data
  Future<bool> requestAuthorization() async {
    if (!isAvailable) return false;
    if (_authRequested && _authorized) return true;

    _authRequested = true;

    try {
      // Configure the health plugin
      await Health().configure();

      // Request authorization for workout and heart rate data
      _authorized = await Health().requestAuthorization(
        [
          HealthDataType.WORKOUT,
          HealthDataType.HEART_RATE,
        ],
        permissions: [
          HealthDataAccess.READ_WRITE,
          HealthDataAccess.READ_WRITE,
        ],
      );

      debugPrint('HealthKit authorization result: $_authorized');
      return _authorized;
    } catch (e) {
      debugPrint('HealthKit authorization error: $e');
      _authorized = false;
      return false;
    }
  }

  /// Save a completed workout to HealthKit
  /// Returns true if save was successful, false otherwise
  Future<bool> saveWorkout({
    required DateTime startTime,
    required Duration duration,
    required List<HeartRateReading> heartRateReadings,
  }) async {
    if (!isAvailable) return false;

    // Request authorization if not already done
    if (!_authorized) {
      final granted = await requestAuthorization();
      if (!granted) return false;
    }

    try {
      final endTime = startTime.add(duration);

      debugPrint('HealthKit: Saving workout from $startTime to $endTime');

      // Save the workout (BIKING maps to Cycling on iOS)
      final workoutSuccess = await Health().writeWorkoutData(
        activityType: HealthWorkoutActivityType.BIKING,
        start: startTime,
        end: endTime,
      );

      debugPrint('HealthKit: Workout save result: $workoutSuccess');

      if (!workoutSuccess) return false;

      // Save heart rate samples if we have any
      if (heartRateReadings.isNotEmpty) {
        debugPrint('HealthKit: Saving ${heartRateReadings.length} HR samples');
        for (final reading in heartRateReadings) {
          // Each HR reading is saved as a point sample
          await Health().writeHealthData(
            value: reading.bpm.toDouble(),
            type: HealthDataType.HEART_RATE,
            startTime: reading.timestamp,
            endTime: reading.timestamp,
            unit: HealthDataUnit.BEATS_PER_MINUTE,
          );
        }
      }

      return true;
    } catch (e) {
      debugPrint('HealthKit: Save error: $e');
      return false;
    }
  }
}
