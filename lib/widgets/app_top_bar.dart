import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'arcade/arcade_badge.dart';
import 'arcade/pixel_icon.dart';

/// Persistent top bar with optional left badge and a YOU navigation badge on the right.
class AppTopBar extends StatelessWidget {
  final Widget? leftBadge;
  final VoidCallback onYouTap;

  const AppTopBar({
    super.key,
    this.leftBadge,
    required this.onYouTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 8,
        left: 16,
        right: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          leftBadge ?? const SizedBox.shrink(),
          ArcadeBadge(
            icon: const PixelIcon.person(size: 12),
            text: 'YOU',
            borderColor: AppColors.electricViolet,
            onTap: onYouTap,
          ),
        ],
      ),
    );
  }
}
