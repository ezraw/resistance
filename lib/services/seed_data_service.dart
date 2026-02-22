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
      final samples = spec.hasHr
          ? _generateHrSamples(
              startTime: spec.startedAt,
              durationSeconds: spec.durationSeconds,
              zones: spec.zones,
              rng: rng,
            )
          : <ActivitySample>[];

      int? avgHr;
      int? maxHr;
      if (samples.isNotEmpty) {
        final hrs = samples.map((s) => s.heartRate!).toList();
        avgHr = (hrs.reduce((a, b) => a + b) / hrs.length).round();
        maxHr = hrs.reduce(max);
      }

      final activity = Activity(
        startedAt: spec.startedAt,
        durationSeconds: spec.durationSeconds,
        avgHeartRate: avgHr,
        maxHeartRate: maxHr,
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
      ),
      // 2: 2.5 weeks ago, evening — 45 min steady Z2-Z3
      _ActivitySpec(
        startedAt: now.subtract(const Duration(days: 17, hours: -18)),
        durationSeconds: 45 * 60,
        hasHr: true,
        zones: const [_Zone(85, 120, 0.15), _Zone(125, 155, 0.70), _Zone(110, 125, 0.15)],
      ),
      // 3: 2 weeks ago, morning — 60 min endurance with Z3-Z4 intervals
      _ActivitySpec(
        startedAt: now.subtract(const Duration(days: 14, hours: -7)),
        durationSeconds: 60 * 60,
        hasHr: true,
        zones: const [_Zone(88, 125, 0.12), _Zone(140, 172, 0.76), _Zone(115, 130, 0.12)],
      ),
      // 4: 11 days ago, afternoon — 30 min, no HR
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
      ),
      // 6: 5 days ago, evening — 15 min intense, Z4-Z5
      _ActivitySpec(
        startedAt: now.subtract(const Duration(days: 5, hours: -19)),
        durationSeconds: 15 * 60,
        hasHr: true,
        zones: const [_Zone(90, 140, 0.15), _Zone(165, 192, 0.70), _Zone(140, 160, 0.15)],
      ),
      // 7: 2 days ago, morning — 50 min moderate, smooth warmup/cooldown
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
}

class _ActivitySpec {
  final DateTime startedAt;
  final int durationSeconds;
  final bool hasHr;
  final List<_Zone> zones;

  const _ActivitySpec({
    required this.startedAt,
    required this.durationSeconds,
    required this.hasHr,
    required this.zones,
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
