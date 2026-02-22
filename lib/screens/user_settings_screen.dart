import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/user_settings_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/arcade_background.dart';
import '../widgets/arcade/arcade_panel.dart';
import '../widgets/arcade/arcade_button.dart';
import '../widgets/arcade/pixel_icon.dart';
import '../painters/resistance_band_config.dart';

class UserSettingsScreen extends StatefulWidget {
  final UserSettingsService userSettingsService;

  const UserSettingsScreen({
    super.key,
    required this.userSettingsService,
  });

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  void _goBack() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
  }

  void _editMaxHeartRate() {
    _showEditDialog(
      title: 'MAX HEART RATE',
      currentValue: widget.userSettingsService.maxHeartRate,
      unit: 'BPM',
      min: 100,
      max: 230,
      onSave: (value) {
        setState(() {
          widget.userSettingsService.maxHeartRate = value;
        });
      },
    );
  }

  void _editFtp() {
    _showEditDialog(
      title: 'FTP',
      currentValue: widget.userSettingsService.ftp,
      unit: 'W',
      min: 50,
      max: 500,
      onSave: (value) {
        setState(() {
          widget.userSettingsService.ftp = value;
        });
      },
    );
  }

  void _showEditDialog({
    required String title,
    required int? currentValue,
    required String unit,
    required int min,
    required int max,
    required void Function(int?) onSave,
  }) {
    final controller = TextEditingController(
      text: currentValue?.toString() ?? '',
    );
    String? errorText;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.nightPlum,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: AppColors.gold, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
            title: Text(
              title,
              style: AppTypography.button(fontSize: 12, color: AppColors.gold),
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: AppTypography.number(fontSize: 20),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '$min-$max $unit',
                    hintStyle: AppTypography.secondary(fontSize: 8),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.electricViolet, width: 2),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.gold, width: 2),
                    ),
                  ),
                  autofocus: true,
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorText!,
                    style: AppTypography.label(fontSize: 6, color: AppColors.red),
                  ),
                ],
              ],
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
              if (currentValue != null)
                TextButton(
                  onPressed: () {
                    onSave(null);
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'CLEAR',
                    style: AppTypography.label(fontSize: 7, color: AppColors.red),
                  ),
                ),
              TextButton(
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isEmpty) {
                    setDialogState(() {
                      errorText = 'ENTER A VALUE';
                    });
                    return;
                  }
                  final value = int.tryParse(text);
                  if (value == null || value < min || value > max) {
                    setDialogState(() {
                      errorText = 'MUST BE $min-$max';
                    });
                    return;
                  }
                  onSave(value);
                  Navigator.of(context).pop();
                },
                child: Text(
                  'SAVE',
                  style: AppTypography.label(fontSize: 7, color: AppColors.gold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHr = widget.userSettingsService.maxHeartRate;
    final ftp = widget.userSettingsService.ftp;

    return Scaffold(
      body: ArcadeBackground(
        config: ResistanceBandConfig.history,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'SETTINGS',
                  style: AppTypography.button(
                    fontSize: 20,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 24),

                // Max Heart Rate row
                GestureDetector(
                  onTap: _editMaxHeartRate,
                  behavior: HitTestBehavior.opaque,
                  child: ArcadePanel.secondary(
                    borderColor: AppColors.magenta,
                    child: Row(
                      children: [
                        const PixelIcon.heart(size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MAX HEART RATE',
                                style: AppTypography.secondary(fontSize: 7),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                maxHr != null ? '$maxHr BPM' : 'NOT SET',
                                style: AppTypography.label(
                                  fontSize: 10,
                                  color: maxHr != null ? AppColors.white : AppColors.warmCream.withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // FTP row
                GestureDetector(
                  onTap: _editFtp,
                  behavior: HitTestBehavior.opaque,
                  child: ArcadePanel.secondary(
                    borderColor: AppColors.neonCyan,
                    child: Row(
                      children: [
                        const PixelIcon.lightningBolt(size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'FTP',
                                style: AppTypography.secondary(fontSize: 7),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ftp != null ? '$ftp W' : 'NOT SET',
                                style: AppTypography.label(
                                  fontSize: 10,
                                  color: ftp != null ? AppColors.white : AppColors.warmCream.withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

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
}
