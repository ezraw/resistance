import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/activity.dart';
import '../models/activity_sample.dart';
import '../services/activity_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/arcade_background.dart';
import '../widgets/arcade/arcade_panel.dart';
import '../widgets/arcade/arcade_button.dart';
import '../widgets/arcade/pixel_icon.dart';
import '../painters/resistance_band_config.dart';
import '../painters/hr_zone_chart_painter.dart';
import '../painters/power_zone_chart_painter.dart';

class ActivityDetailScreen extends StatefulWidget {
  final Activity activity;
  final ActivityService activityService;

  const ActivityDetailScreen({
    super.key,
    required this.activity,
    required this.activityService,
  });

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  List<ActivitySample>? _samples;

  @override
  void initState() {
    super.initState();
    _loadSamples();
  }

  Future<void> _loadSamples() async {
    if (widget.activity.id == null) return;
    final samples = await widget.activityService.getSamples(widget.activity.id!);
    if (mounted) {
      setState(() {
        _samples = samples;
      });
    }
  }

  void _goBack() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h}h ${m}m ${s}s';
    } else if (m > 0) {
      return '${m}m ${s}s';
    }
    return '${s}s';
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
                     'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    final month = months[local.month - 1];
    final day = local.day;
    final year = local.year;
    final hour = local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    return '$month $day, $year AT $hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;

    return Scaffold(
      body: ArcadeBackground(
        config: ResistanceBandConfig.history,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'ACTIVITY DETAIL',
                              style: AppTypography.button(
                                fontSize: 24,
                                color: AppColors.gold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatDate(activity.startedAt),
                            style: AppTypography.secondary(fontSize: 7),
                          ),

                          const SizedBox(height: 24),

                          // Duration
                          _buildStatCard(
                            icon: const PixelIcon.stopwatch(size: 24),
                            label: 'DURATION',
                            value: _formatDuration(activity.durationSeconds),
                            borderColor: AppColors.neonCyan,
                          ),

                          if (activity.avgHeartRate != null) ...[
                            const SizedBox(height: 12),
                            _buildStatCard(
                              icon: const PixelIcon.heart(size: 24),
                              label: 'AVG HEART RATE',
                              value: '${activity.avgHeartRate} BPM',
                              borderColor: AppColors.magenta,
                            ),
                          ],

                          if (activity.maxHeartRate != null) ...[
                            const SizedBox(height: 12),
                            _buildStatCard(
                              icon: const PixelIcon.heart(size: 24),
                              label: 'MAX HEART RATE',
                              value: '${activity.maxHeartRate} BPM',
                              borderColor: AppColors.magenta,
                            ),
                          ],

                          // HR Zone chart
                          if (_samples != null && _samples!.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _buildHrZoneChart(),
                          ],

                          // Power section
                          if (activity.avgWatts != null) ...[
                            const SizedBox(height: 20),
                            _buildStatCard(
                              icon: const PixelIcon.lightningBolt(size: 24),
                              label: 'AVG POWER',
                              value: '${activity.avgWatts} W',
                              borderColor: AppColors.gold,
                            ),
                            if (activity.maxWatts != null) ...[
                              const SizedBox(height: 12),
                              _buildStatCard(
                                icon: const PixelIcon.lightningBolt(size: 24),
                                label: 'MAX POWER',
                                value: '${activity.maxWatts} W',
                                borderColor: AppColors.gold,
                              ),
                            ],
                            if (_samples != null && _samples!.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              _buildPowerZoneChart(),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                ArcadeButton(
                  label: 'BACK',
                  onTap: _goBack,
                  scheme: ArcadeButtonScheme.gold,
                  minWidth: 160,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required Widget icon,
    required String label,
    required String value,
    required Color borderColor,
  }) {
    return ArcadePanel.secondary(
      borderColor: borderColor,
      child: Row(
        children: [
          icon,
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.secondary(fontSize: 7),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTypography.number(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHrZoneChart() {
    final heartRates = _samples!
        .where((s) => s.heartRate != null && s.heartRate! > 0)
        .map((s) => s.heartRate!)
        .toList();

    if (heartRates.isEmpty) return const SizedBox.shrink();

    final zoneData = HrZoneData.fromHeartRates(heartRates);
    if (zoneData.isEmpty) return const SizedBox.shrink();

    final totalHrSeconds = heartRates.length;
    final totalWorkoutSeconds = widget.activity.durationSeconds;

    return ArcadePanel.secondary(
      borderColor: AppColors.magenta,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HEART RATE ZONES (MAX HR: 190)',
            style: AppTypography.label(fontSize: 7, color: AppColors.gold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: CustomPaint(
              size: const Size(double.infinity, 100),
              painter: HrZoneChartPainter(data: zoneData),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'HR DATA: ${_formatDuration(totalHrSeconds)} OF ${_formatDuration(totalWorkoutSeconds)}',
            style: AppTypography.secondary(fontSize: 6),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerZoneChart() {
    final watts = _samples!
        .where((s) => s.watts != null && s.watts! > 0)
        .map((s) => s.watts!)
        .toList();

    if (watts.isEmpty) return const SizedBox.shrink();

    final zoneData = PowerZoneData.fromWatts(watts);
    if (zoneData.isEmpty) return const SizedBox.shrink();

    final totalPowerSeconds = watts.length;
    final totalWorkoutSeconds = widget.activity.durationSeconds;

    return ArcadePanel.secondary(
      borderColor: AppColors.gold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'POWER ZONES (FTP: 100W)',
            style: AppTypography.label(fontSize: 7, color: AppColors.gold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: CustomPaint(
              size: const Size(double.infinity, 140),
              painter: PowerZoneChartPainter(data: zoneData),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'POWER DATA: ${_formatDuration(totalPowerSeconds)} OF ${_formatDuration(totalWorkoutSeconds)}',
            style: AppTypography.secondary(fontSize: 6),
          ),
        ],
      ),
    );
  }
}
