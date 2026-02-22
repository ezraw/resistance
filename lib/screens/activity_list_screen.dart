import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/activity.dart';
import '../services/activity_service.dart';
import '../services/seed_data_service.dart';
import '../services/user_settings_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/page_transitions.dart';
import '../widgets/arcade_background.dart';
import '../widgets/arcade/arcade_panel.dart';
import '../widgets/arcade/arcade_button.dart';
import '../widgets/arcade/pixel_icon.dart';
import '../widgets/arcade/arcade_badge.dart';
import '../painters/resistance_band_config.dart';
import 'activity_detail_screen.dart';
import 'user_settings_screen.dart';

class ActivityListScreen extends StatefulWidget {
  final ActivityService activityService;
  final UserSettingsService userSettingsService;

  const ActivityListScreen({
    super.key,
    required this.activityService,
    required this.userSettingsService,
  });

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  List<Activity>? _activities;
  Timer? _seedTimer;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  @override
  void dispose() {
    _seedTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    final activities = await widget.activityService.getAll();
    if (mounted) {
      setState(() {
        _activities = activities;
      });
    }
  }

  void _openDetail(Activity activity) {
    Navigator.of(context).push(
      ArcadePageRoute(
        page: ActivityDetailScreen(
          activity: activity,
          activityService: widget.activityService,
          userSettingsService: widget.userSettingsService,
        ),
        transition: ArcadeTransition.slideRight,
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      ArcadePageRoute(
        page: UserSettingsScreen(
          userSettingsService: widget.userSettingsService,
        ),
        transition: ArcadeTransition.slideRight,
      ),
    );
  }

  void _goBack() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
  }

  void _startSeedTimer() {
    _seedTimer?.cancel();
    _seedTimer = Timer(const Duration(seconds: 10), _confirmSeed);
  }

  void _cancelSeedTimer() {
    _seedTimer?.cancel();
    _seedTimer = null;
  }

  void _confirmSeed() {
    _seedTimer = null;
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.nightPlum,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.gold, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        title: Text(
          'SEED DATA',
          style: AppTypography.button(fontSize: 12, color: AppColors.gold),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Generate 8 test activities?',
          style: AppTypography.label(fontSize: 7, color: AppColors.warmCream),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'CANCEL',
              style: AppTypography.label(
                fontSize: 7,
                color: AppColors.warmCream.withValues(alpha: 0.5),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _seedDatabase();
            },
            child: Text(
              'SEED',
              style: AppTypography.label(fontSize: 7, color: AppColors.gold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _seedDatabase() async {
    final count = await SeedDataService.seed(widget.activityService);
    await _loadActivities();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.nightPlum,
          content: Text(
            '$count ACTIVITIES SEEDED',
            style: AppTypography.label(fontSize: 7, color: AppColors.gold),
            textAlign: TextAlign.center,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final year = local.year.toString().substring(2);
    final hour = local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    return '$month/$day/$year $hour:$minute $ampm';
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h}h ${m}m';
    } else if (m > 0) {
      return '${m}m ${s}s';
    }
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ArcadeBackground(
        config: ResistanceBandConfig.history,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // YOU badge — right-aligned
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ArcadeBadge(
                      icon: const PixelIcon.person(size: 12),
                      text: 'YOU',
                      borderColor: AppColors.electricViolet,
                      onTap: _openSettings,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (_) => _startSeedTimer(),
                  onPointerUp: (_) => _cancelSeedTimer(),
                  onPointerCancel: (_) => _cancelSeedTimer(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      'HISTORY',
                      style: AppTypography.button(
                        fontSize: 20,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildContent(),
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

  Widget _buildContent() {
    if (_activities == null) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.warmCream,
          ),
        ),
      );
    }

    if (_activities!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const PixelIcon.list(size: 48),
            const SizedBox(height: 16),
            Text(
              'NO ACTIVITIES YET',
              style: AppTypography.label(
                fontSize: 10,
                color: AppColors.warmCream.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _activities!.length,
      itemBuilder: (context, index) {
        final activity = _activities![index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: GestureDetector(
            onTap: () => _openDetail(activity),
            child: ArcadePanel.secondary(
              borderColor: AppColors.electricViolet,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(activity.startedAt),
                          style: AppTypography.label(fontSize: 7),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatDuration(activity.durationSeconds),
                        style: AppTypography.label(
                          fontSize: 7,
                          color: AppColors.neonCyan,
                        ),
                      ),
                      if (activity.avgHeartRate != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${activity.avgHeartRate} BPM',
                          style: AppTypography.label(
                            fontSize: 6,
                            color: AppColors.hotPink,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
