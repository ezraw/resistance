import 'dart:math';

import '../models/activity.dart';
import '../models/activity_sample.dart';
import 'activity_service.dart';

/// Generates realistic seed data for testing the activity history screens.
///
/// Long-press the HISTORY title for 10 seconds to trigger seeding via a
/// confirmation dialog.
class SeedDataService {
  SeedDataService._();

  /// Insert 8 realistic activities into the database.
  /// Returns the number of activities created.
  static Future<int> seed(ActivityService activityService) async {
    final now = DateTime.now().toUtc();
    final rng = Random(42); // fixed seed for reproducibility

    final specs = _activitySpecs(now);
    for (final spec in specs) {
      final hrSamples = spec.hasHr
          ? _generateHrSamples(
              startTime: spec.startedAt,
              durationSeconds: spec.durationSeconds,
              zones: spec.zones,
              rng: rng,
            )
          : <ActivitySample>[];

      final trainerSamples = spec.hasTrainerData
          ? _generateTrainerSamples(
              startTime: spec.startedAt,
              durationSeconds: spec.durationSeconds,
              zones: spec.trainerZones,
              rng: rng,
            )
          : <ActivitySample>[];

      // Merge HR and trainer data into unified samples
      final samples = _mergeSamples(hrSamples, trainerSamples);

      int? avgHr;
      int? maxHr;
      if (hrSamples.isNotEmpty) {
        final hrs = hrSamples.map((s) => s.heartRate!).toList();
        avgHr = (hrs.reduce((a, b) => a + b) / hrs.length).round();
        maxHr = hrs.reduce(max);
      }

      int? avgWatts;
      int? maxWatts;
      int? avgCadence;
      double? avgMph;
      double? maxMph;
      if (trainerSamples.isNotEmpty) {
        final wattsList = trainerSamples.map((s) => s.watts!).toList();
        avgWatts = (wattsList.reduce((a, b) => a + b) / wattsList.length).round();
        maxWatts = wattsList.reduce(max);
        final cadenceList = trainerSamples.map((s) => s.cadence!).toList();
        avgCadence = (cadenceList.reduce((a, b) => a + b) / cadenceList.length).round();
        final speedList = trainerSamples.map((s) => s.speedMph!).toList();
        avgMph = speedList.reduce((a, b) => a + b) / speedList.length;
        maxMph = speedList.reduce((a, b) => a > b ? a : b);
      }

      final activity = Activity(
        startedAt: spec.startedAt,
        durationSeconds: spec.durationSeconds,
        avgHeartRate: avgHr,
        maxHeartRate: maxHr,
        avgWatts: avgWatts,
        maxWatts: maxWatts,
        avgCadence: avgCadence,
        avgMph: avgMph,
        maxMph: maxMph,
        source: 'seed',
        createdAt: now,
      );

      await activityService.insertWithSamples(activity, samples);
    }

    return specs.length;
  }

  static List<_ActivitySpec> _activitySpecs(DateTime now) {
    return [
      // 1: 3 weeks ago, morning — 20 min easy ride, Z1-Z2
      _ActivitySpec(
        startedAt: now.subtract(const Duration(days: 21, hours: -8)),
        durationSeconds: 20 * 60,
        hasHr: true,
        zones: const [_Zone(90, 115, 0.15), _Zone(110, 135, 0.70), _Zone(100, 115, 0.15)],
        hasTrainerData: true,
        trainerZones: const [
          _TrainerZone(80, 110, 60, 75, 15.0, 22.0, 0.15),
          _TrainerZone(100, 140, 70, 85, 20.0, 28.0, 0.70),
          _TrainerZone(80, 110, 60, 75, 15.0, 22.0, 0.15),
        ],
      ),
      // 2: 2.5 weeks ago, evening — 45 min steady Z2-Z3
      _ActivitySpec(
        startedAt: now.subtract(const Duration(days: 17, hours: -18)),
        durationSeconds: 45 * 60,
        hasHr: true,
        zones: const [_Zone(85, 120, 0.15), _Zone(125, 155, 0.70), _Zone(110, 125, 0.15)],
        hasTrainerData: true,
        trainerZones: const [
          _TrainerZone(90, 120, 65, 80, 18.0, 24.0, 0.15),
          _TrainerZone(140, 200, 78, 92, 25.0, 32.0, 0.70),
          _TrainerZone(100, 130, 65, 78, 18.0, 24.0, 0.15),
        ],
      ),
      // 3: 2 weeks ago, morning — 60 min endurance with Z3-Z4 intervals
      _ActivitySpec(
        startedAt: now.subtract(const Duration(days: 14, hours: -7)),
        durationSeconds: 60 * 60,
        hasHr: true,
        zones: const [_Zone(88, 125, 0.12), _Zone(140, 172, 0.76), _Zone(115, 130, 0.12)],
        hasTrainerData: true,
        trainerZones: const [
          _TrainerZone(85, 120, 65, 78, 17.0, 23.0, 0.12),
          _TrainerZone(160, 250, 80, 95, 27.0, 35.0, 0.76),
          _TrainerZone(100, 140, 68, 80, 20.0, 26.0, 0.12),
        ],
      ),
      // 4: 11 days ago, afternoon — 30 min, no HR, no trainer data
      _ActivitySpec(
        startedAt: now.subtract(const Duration(days: 11, hours: -14)),
        durationSeconds: 30 * 60,
        hasHr: false,
        zones: const [],
      ),
      // 5: 1 week ago, morning — 75 min big session, Z1-Z5
      _ActivitySpec(
        startedAt: now.subtract(const Duration(days: 7, hours: -9)),
        durationSeconds: 75 * 60,
        hasHr: true,
        zones: const [_Zone(85, 115, 0.12), _Zone(130, 185, 0.76), _Zone(110, 125, 0.12)],
        hasTrainerData: true,
        trainerZones: const [
          _TrainerZone(80, 110, 60, 75, 15.0, 22.0, 0.12),
          _TrainerZone(180, 300, 82, 100, 28.0, 38.0, 0.76),
          _TrainerZone(100, 140, 65, 80, 18.0, 25.0, 0.12),
        ],
      ),
      // 6: 5 days ago, evening — 15 min intense, Z4-Z5
      _ActivitySpec(
        startedAt: now.subtract(const Duration(days: 5, hours: -19)),
        durationSeconds: 15 * 60,
        hasHr: true,
        zones: const [_Zone(90, 140, 0.15), _Zone(165, 192, 0.70), _Zone(140, 160, 0.15)],
        hasTrainerData: true,
        trainerZones: const [
          _TrainerZone(100, 150, 70, 85, 20.0, 27.0, 0.15),
          _TrainerZone(220, 320, 85, 100, 30.0, 38.0, 0.70),
          _TrainerZone(140, 190, 75, 88, 24.0, 30.0, 0.15),
        ],
      ),
      // 7: 2 days ago, morning — 50 min moderate, smooth warmup/cooldown (HR only, no trainer)
      _ActivitySpec(
        startedAt: now.subtract(const Duration(days: 2, hours: -8)),
        durationSeconds: 50 * 60,
        hasHr: true,
        zones: const [_Zone(80, 120, 0.20), _Zone(135, 160, 0.60), _Zone(110, 130, 0.20)],
      ),
      // 8: Yesterday, evening — 40 min interval training, alternating Z2/Z4
      _ActivitySpec(
        startedAt: now.subtract(const Duration(days: 1, hours: -18)),
        durationSeconds: 40 * 60,
        hasHr: true,
        zones: const [_Zone(85, 115, 0.10), _Zone(120, 170, 0.80), _Zone(110, 125, 0.10)],
        hasTrainerData: true,
        trainerZones: const [
          _TrainerZone(85, 120, 65, 78, 17.0, 24.0, 0.10),
          _TrainerZone(150, 260, 78, 95, 25.0, 34.0, 0.80),
          _TrainerZone(100, 140, 65, 80, 18.0, 25.0, 0.10),
        ],
      ),
    ];
  }

  /// Generate per-second HR samples with warmup / main / cooldown phases.
  static List<ActivitySample> _generateHrSamples({
    required DateTime startTime,
    required int durationSeconds,
    required List<_Zone> zones,
    required Random rng,
  }) {
    final samples = <ActivitySample>[];
    final warmupEnd = (durationSeconds * zones[0].fraction).round();
    final cooldownStart = durationSeconds - (durationSeconds * zones[2].fraction).round();

    double currentHr = zones[0].minBpm.toDouble();

    for (int s = 0; s < durationSeconds; s++) {
      double targetHr;

      if (s < warmupEnd) {
        // Warmup: ramp from zone[0].min toward zone[1].min
        final progress = s / warmupEnd;
        targetHr = zones[0].minBpm + (zones[1].minBpm - zones[0].minBpm) * progress;
      } else if (s >= cooldownStart) {
        // Cooldown: drop from zone[1].min back toward zone[2].min
        final progress = (s - cooldownStart) / (durationSeconds - cooldownStart);
        targetHr = zones[1].minBpm - (zones[1].minBpm - zones[2].minBpm) * progress;
      } else {
        // Main phase: vary within zone bounds
        final mainZone = zones[1];
        final mid = (mainZone.minBpm + mainZone.maxBpm) / 2;
        final range = (mainZone.maxBpm - mainZone.minBpm) / 2;
        // Slow sine wave + random jitter
        targetHr = mid + range * sin(s * 0.01) * 0.7;
      }

      // Jitter ±4 BPM
      targetHr += (rng.nextDouble() - 0.5) * 8;

      // Smooth toward target (simulate physiological lag)
      currentHr += (targetHr - currentHr) * 0.15;

      final hr = currentHr.round().clamp(60, 200);

      samples.add(ActivitySample(
        timestamp: startTime.add(Duration(seconds: s)),
        heartRate: hr,
      ));
    }

    return samples;
  }

  /// Generate per-second trainer data samples with warmup / main / cooldown phases.
  static List<ActivitySample> _generateTrainerSamples({
    required DateTime startTime,
    required int durationSeconds,
    required List<_TrainerZone> zones,
    required Random rng,
  }) {
    final samples = <ActivitySample>[];
    final warmupEnd = (durationSeconds * zones[0].fraction).round();
    final cooldownStart = durationSeconds - (durationSeconds * zones[2].fraction).round();

    double currentWatts = zones[0].minWatts.toDouble();
    double currentCadence = zones[0].minCadence.toDouble();
    double currentSpeed = zones[0].minSpeedKmh;

    for (int s = 0; s < durationSeconds; s++) {
      double targetWatts;
      double targetCadence;
      double targetSpeed;

      if (s < warmupEnd) {
        final progress = s / warmupEnd;
        targetWatts = zones[0].minWatts + (zones[1].minWatts - zones[0].minWatts) * progress;
        targetCadence = zones[0].minCadence + (zones[1].minCadence - zones[0].minCadence) * progress;
        targetSpeed = zones[0].minSpeedKmh + (zones[1].minSpeedKmh - zones[0].minSpeedKmh) * progress;
      } else if (s >= cooldownStart) {
        final progress = (s - cooldownStart) / (durationSeconds - cooldownStart);
        targetWatts = zones[1].minWatts - (zones[1].minWatts - zones[2].minWatts) * progress;
        targetCadence = zones[1].minCadence - (zones[1].minCadence - zones[2].minCadence) * progress;
        targetSpeed = zones[1].minSpeedKmh - (zones[1].minSpeedKmh - zones[2].minSpeedKmh) * progress;
      } else {
        final z = zones[1];
        final midW = (z.minWatts + z.maxWatts) / 2;
        final rangeW = (z.maxWatts - z.minWatts) / 2;
        targetWatts = midW + rangeW * sin(s * 0.01) * 0.7;

        final midC = (z.minCadence + z.maxCadence) / 2;
        final rangeC = (z.maxCadence - z.minCadence) / 2;
        targetCadence = midC + rangeC * sin(s * 0.012) * 0.7;

        final midS = (z.minSpeedKmh + z.maxSpeedKmh) / 2;
        final rangeS = (z.maxSpeedKmh - z.minSpeedKmh) / 2;
        targetSpeed = midS + rangeS * sin(s * 0.011) * 0.7;
      }

      // Jitter
      targetWatts += (rng.nextDouble() - 0.5) * 10;
      targetCadence += (rng.nextDouble() - 0.5) * 4;
      targetSpeed += (rng.nextDouble() - 0.5) * 2;

      // Smooth toward target
      currentWatts += (targetWatts - currentWatts) * 0.15;
      currentCadence += (targetCadence - currentCadence) * 0.15;
      currentSpeed += (targetSpeed - currentSpeed) * 0.15;

      final watts = currentWatts.round().clamp(50, 500);
      final cadence = currentCadence.round().clamp(40, 120);
      final speedKmh = currentSpeed.clamp(10.0, 50.0);
      final speedMph = speedKmh * 0.621371;

      samples.add(ActivitySample(
        timestamp: startTime.add(Duration(seconds: s)),
        watts: watts,
        cadence: cadence,
        speedMph: double.parse(speedMph.toStringAsFixed(1)),
      ));
    }

    return samples;
  }

  /// Merge HR-only and trainer-only samples into unified samples by timestamp.
  static List<ActivitySample> _mergeSamples(
    List<ActivitySample> hrSamples,
    List<ActivitySample> trainerSamples,
  ) {
    if (trainerSamples.isEmpty) return hrSamples;
    if (hrSamples.isEmpty) return trainerSamples;

    // Both lists are per-second starting at the same time, so zip them
    final length = hrSamples.length; // Both should be same length
    return List.generate(length, (i) {
      final hr = hrSamples[i];
      final tr = i < trainerSamples.length ? trainerSamples[i] : null;
      return ActivitySample(
        timestamp: hr.timestamp,
        heartRate: hr.heartRate,
        watts: tr?.watts,
        cadence: tr?.cadence,
        speedMph: tr?.speedMph,
      );
    });
  }
}

class _ActivitySpec {
  final DateTime startedAt;
  final int durationSeconds;
  final bool hasHr;
  final List<_Zone> zones;
  final bool hasTrainerData;
  final List<_TrainerZone> trainerZones;

  const _ActivitySpec({
    required this.startedAt,
    required this.durationSeconds,
    required this.hasHr,
    required this.zones,
    this.hasTrainerData = false,
    this.trainerZones = const [],
  });
}

/// Describes a HR zone phase: [minBpm, maxBpm] and what fraction of total
/// duration it occupies.
class _Zone {
  final int minBpm;
  final int maxBpm;
  final double fraction;

  const _Zone(this.minBpm, this.maxBpm, this.fraction);
}

/// Describes a trainer data zone phase with power, cadence, and speed ranges.
class _TrainerZone {
  final int minWatts;
  final int maxWatts;
  final int minCadence;
  final int maxCadence;
  final double minSpeedKmh;
  final double maxSpeedKmh;
  final double fraction;

  const _TrainerZone(
    this.minWatts, this.maxWatts,
    this.minCadence, this.maxCadence,
    this.minSpeedKmh, this.maxSpeedKmh,
    this.fraction,
  );
}
