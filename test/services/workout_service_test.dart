import 'package:flutter_test/flutter_test.dart';
import 'package:resistance_app/services/workout_service.dart';

void main() {
  group('WorkoutService', () {
    late WorkoutService service;

    setUp(() {
      service = WorkoutService();
    });

    tearDown(() {
      service.dispose();
    });

    group('State Machine', () {
      test('starts in idle state', () {
        expect(service.currentState, WorkoutState.idle);
      });

      test('transitions to active when started', () async {
        final states = <WorkoutState>[];
        service.stateStream.listen(states.add);

        service.start();
        await Future.delayed(const Duration(milliseconds: 10));

        expect(service.currentState, WorkoutState.active);
        expect(states, contains(WorkoutState.active));
      });

      test('transitions to paused when paused', () async {
        service.start();
        await Future.delayed(const Duration(milliseconds: 10));

        service.pause();
        expect(service.currentState, WorkoutState.paused);
      });

      test('transitions back to active when resumed', () async {
        service.start();
        await Future.delayed(const Duration(milliseconds: 10));
        service.pause();

        service.resume();
        expect(service.currentState, WorkoutState.active);
      });

      test('transitions to finished when finished', () async {
        service.start();
        await Future.delayed(const Duration(milliseconds: 10));

        service.finish();
        expect(service.currentState, WorkoutState.finished);
      });

      test('transitions back to idle when reset', () async {
        service.start();
        await Future.delayed(const Duration(milliseconds: 10));
        service.finish();

        service.reset();
        expect(service.currentState, WorkoutState.idle);
      });

      test('start does nothing if not idle', () async {
        service.start();
        await Future.delayed(const Duration(milliseconds: 10));
        service.pause();

        final stateBeforeStart = service.currentState;
        service.start(); // Should do nothing
        expect(service.currentState, stateBeforeStart);
      });

      test('pause does nothing if not active', () {
        service.pause(); // Should do nothing
        expect(service.currentState, WorkoutState.idle);
      });

      test('resume does nothing if not paused', () {
        service.resume(); // Should do nothing
        expect(service.currentState, WorkoutState.idle);
      });
    });

    group('Timer', () {
      test('elapsed is zero initially', () {
        expect(service.elapsed, Duration.zero);
      });

      test('elapsed increases after starting', () async {
        service.start();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(service.elapsed.inMilliseconds, greaterThan(50));
      });

      test('elapsed stops when paused', () async {
        service.start();
        await Future.delayed(const Duration(milliseconds: 100));
        service.pause();

        final elapsedAtPause = service.elapsed;
        await Future.delayed(const Duration(milliseconds: 100));

        // Elapsed should not have increased significantly
        expect(
          (service.elapsed - elapsedAtPause).inMilliseconds,
          lessThan(50),
        );
      });

      test('elapsed continues from pause point when resumed', () async {
        service.start();
        await Future.delayed(const Duration(milliseconds: 100));
        service.pause();
        final elapsedAtPause = service.elapsed;

        service.resume();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(
          service.elapsed.inMilliseconds,
          greaterThan(elapsedAtPause.inMilliseconds + 50),
        );
      });

      test('elapsed resets on restart', () async {
        service.start();
        await Future.delayed(const Duration(milliseconds: 100));

        service.restart();
        await Future.delayed(const Duration(milliseconds: 10));

        // After restart, elapsed should be very small
        expect(service.elapsed.inMilliseconds, lessThan(50));
      });

      test('finalDuration is captured when finished', () async {
        service.start();
        await Future.delayed(const Duration(milliseconds: 100));

        service.finish();
        expect(service.finalDuration.inMilliseconds, greaterThan(50));
      });

      test('emits elapsed updates via stream', () async {
        final durations = <Duration>[];
        service.elapsedStream.listen(durations.add);

        service.start();
        await Future.delayed(const Duration(seconds: 2, milliseconds: 100));
        service.pause();

        // Should have received at least 2 updates (at least one per second)
        expect(durations.length, greaterThanOrEqualTo(2));
      });
    });

    group('Heart Rate Recording', () {
      test('records heart rate readings during workout', () async {
        service.start();
        await Future.delayed(const Duration(milliseconds: 10));

        service.recordHeartRate(120);
        service.recordHeartRate(130);
        service.recordHeartRate(125);

        expect(service.averageHeartRate, equals(125));
      });

      test('tracks max heart rate', () async {
        service.start();
        await Future.delayed(const Duration(milliseconds: 10));

        service.recordHeartRate(100);
        service.recordHeartRate(150);
        service.recordHeartRate(120);

        expect(service.maxHeartRate, equals(150));
      });

      test('ignores invalid heart rate values', () async {
        service.start();
        await Future.delayed(const Duration(milliseconds: 10));

        service.recordHeartRate(0);
        service.recordHeartRate(-10);
        service.recordHeartRate(100);

        expect(service.averageHeartRate, equals(100));
        expect(service.maxHeartRate, equals(100));
      });

      test('does not record heart rate when not in progress', () {
        service.recordHeartRate(120);

        expect(service.averageHeartRate, equals(0));
        expect(service.maxHeartRate, equals(0));
      });

      test('heart rate stats reset on restart', () async {
        service.start();
        await Future.delayed(const Duration(milliseconds: 10));
        service.recordHeartRate(120);

        service.restart();

        expect(service.averageHeartRate, equals(0));
        expect(service.maxHeartRate, equals(0));
      });

      test('heartRateReadings returns list with timestamps', () async {
        service.start();
        await Future.delayed(const Duration(milliseconds: 10));

        final beforeRecord = DateTime.now();
        service.recordHeartRate(120);
        final afterRecord = DateTime.now();

        expect(service.heartRateReadings.length, equals(1));
        expect(service.heartRateReadings.first.bpm, equals(120));
        expect(
          service.heartRateReadings.first.timestamp.isAfter(beforeRecord.subtract(const Duration(seconds: 1))),
          isTrue,
        );
        expect(
          service.heartRateReadings.first.timestamp.isBefore(afterRecord.add(const Duration(seconds: 1))),
          isTrue,
        );
      });

      test('heartRateReadings returns unmodifiable list', () async {
        service.start();
        await Future.delayed(const Duration(milliseconds: 10));
        service.recordHeartRate(120);

        final readings = service.heartRateReadings;
        expect(() => readings.add(HeartRateReading(bpm: 130, timestamp: DateTime.now())), throwsUnsupportedError);
      });
    });

    group('Workout Timestamps for HealthKit', () {
      test('workoutStartTime is null initially', () {
        expect(service.workoutStartTime, isNull);
      });

      test('workoutStartTime is set when workout starts', () async {
        final beforeStart = DateTime.now();
        service.start();
        await Future.delayed(const Duration(milliseconds: 10));
        final afterStart = DateTime.now();

        expect(service.workoutStartTime, isNotNull);
        expect(
          service.workoutStartTime!.isAfter(beforeStart.subtract(const Duration(seconds: 1))),
          isTrue,
        );
        expect(
          service.workoutStartTime!.isBefore(afterStart.add(const Duration(seconds: 1))),
          isTrue,
        );
      });

      test('workoutStartTime is reset on restart', () async {
        service.start();
        await Future.delayed(const Duration(milliseconds: 50));
        final firstStartTime = service.workoutStartTime;

        service.restart();
        await Future.delayed(const Duration(milliseconds: 10));

        expect(service.workoutStartTime, isNotNull);
        expect(service.workoutStartTime!.isAfter(firstStartTime!), isTrue);
      });

      test('workoutStartTime is cleared on reset', () async {
        service.start();
        await Future.delayed(const Duration(milliseconds: 10));
        service.finish();
        service.reset();

        expect(service.workoutStartTime, isNull);
      });
    });

    group('Helper Properties', () {
      test('isActive returns true when active', () async {
        service.start();
        await Future.delayed(const Duration(milliseconds: 10));

        expect(service.isActive, isTrue);
      });

      test('isActive returns false when paused', () async {
        service.start();
        await Future.delayed(const Duration(milliseconds: 10));
        service.pause();

        expect(service.isActive, isFalse);
      });

      test('isInProgress returns true when active', () async {
        service.start();
        await Future.delayed(const Duration(milliseconds: 10));

        expect(service.isInProgress, isTrue);
      });

      test('isInProgress returns true when paused', () async {
        service.start();
        await Future.delayed(const Duration(milliseconds: 10));
        service.pause();

        expect(service.isInProgress, isTrue);
      });

      test('isInProgress returns false when idle', () {
        expect(service.isInProgress, isFalse);
      });

      test('isInProgress returns false when finished', () async {
        service.start();
        await Future.delayed(const Duration(milliseconds: 10));
        service.finish();

        expect(service.isInProgress, isFalse);
      });
    });
  });
}
