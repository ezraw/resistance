import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ResistanceControl extends StatefulWidget {
  final int currentLevel;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final bool isUpdating;

  const ResistanceControl({
    super.key,
    required this.currentLevel,
    required this.onIncrease,
    required this.onDecrease,
    this.isUpdating = false,
  });

  @override
  State<ResistanceControl> createState() => _ResistanceControlState();
}

class _ResistanceControlState extends State<ResistanceControl>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  Color _previousColor = const Color(0xFF4CAF50);
  Color _targetColor = const Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();

    // Pulse animation for tap feedback
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _pulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.reverse();
      }
    });

    // Fade animation for color transitions (only on decade boundary crossings)
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _previousColor = _getColorForLevel(widget.currentLevel);
    _targetColor = _previousColor;
  }

  /// Get the decade (0-10) for a given level (0-100)
  int _getDecade(int level) {
    if (level >= 100) return 10;
    return level ~/ 10;
  }

  @override
  void didUpdateWidget(ResistanceControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLevel != widget.currentLevel) {
      final oldDecade = _getDecade(oldWidget.currentLevel);
      final newDecade = _getDecade(widget.currentLevel);

      // Only animate color when crossing decade boundaries
      if (oldDecade != newDecade) {
        // Capture current interpolated color if animation is in progress
        if (_fadeController.isAnimating) {
          _previousColor = Color.lerp(_previousColor, _targetColor, _fadeAnimation.value)!;
        } else {
          _previousColor = _getColorForLevel(oldWidget.currentLevel);
        }
        _targetColor = _getColorForLevel(widget.currentLevel);
        _fadeController.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Color _getColorForLevel(int level) {
    // Decade-based colors: 11 bands (0-9, 10-19, ... 90-99, 100)
    final decade = _getDecade(level);
    switch (decade) {
      case 0:  // 0-9
        return const Color(0xFF4CAF50);  // Green
      case 1:  // 10-19
        return const Color(0xFF8BC34A);  // Light Green
      case 2:  // 20-29
        return const Color(0xFFCDDC39);  // Lime
      case 3:  // 30-39
        return const Color(0xFFFFEB3B);  // Yellow
      case 4:  // 40-49
        return const Color(0xFFFFC107);  // Amber
      case 5:  // 50-59
        return const Color(0xFFFF9800);  // Orange
      case 6:  // 60-69
        return const Color(0xFFFF5722);  // Deep Orange
      case 7:  // 70-79
        return const Color(0xFFF44336);  // Red
      case 8:  // 80-89
        return const Color(0xFFE53935);  // Red Darken
      case 9:  // 90-99
        return const Color(0xFFC62828);  // Dark Red
      case 10: // 100
        return const Color(0xFFB71C1C);  // Darkest Red
      default:
        return const Color(0xFF4CAF50);
    }
  }

  void _handleIncrease() {
    if (widget.currentLevel >= 100 || widget.isUpdating) return;
    _pulseController.forward(from: 0);
    widget.onIncrease();
  }

  void _handleDecrease() {
    if (widget.currentLevel <= 0 || widget.isUpdating) return;
    _pulseController.forward(from: 0);
    widget.onDecrease();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _fadeAnimation]),
      builder: (context, child) {
        final fadeProgress = _fadeAnimation.value;

        // Calculate the display color (interpolated during fade)
        final displayColor = Color.lerp(_previousColor, _targetColor, fadeProgress)!;

        return Stack(
          children: [
            // Background with fade transition
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: _pulseAnimation.value,
                  colors: [
                    displayColor,
                    displayColor.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),

            // UI content layer
            SafeArea(
              child: Center(
                child: Padding(
                  // Extra bottom padding to accommodate workout controls overlay
                  padding: const EdgeInsets.only(
                    left: 40,
                    right: 40,
                    top: 60,
                    bottom: 100,
                  ),
                  child: _buildControlPanel(displayColor),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControlPanel(Color backgroundColor) {
    // Determine text/icon color based on background brightness
    final isDark = backgroundColor.computeLuminance() < 0.5;
    final contentColor = isDark ? Colors.white : Colors.black87;
    // Panel is a darker, semi-transparent version of the background color
    final HSLColor hsl = HSLColor.fromColor(backgroundColor);
    final panelColor = hsl
        .withLightness((hsl.lightness * 0.6).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation * 0.8).clamp(0.0, 1.0))
        .toColor()
        .withValues(alpha: 0.5);

    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // UP button
          _buildButton(
            icon: FontAwesomeIcons.caretUp,
            onTap: _handleIncrease,
            isEnabled: widget.currentLevel < 100 && !widget.isUpdating,
            contentColor: contentColor,
            isTop: true,
          ),

          // Level number
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              '${widget.currentLevel}',
              style: TextStyle(
                fontSize: widget.currentLevel >= 100 ? 80 : 100,
                fontWeight: FontWeight.w700,
                fontFamily: '.SF Pro Rounded',
                color: contentColor,
                height: 1,
              ),
            ),
          ),

          // DOWN button
          _buildButton(
            icon: FontAwesomeIcons.caretDown,
            onTap: _handleDecrease,
            isEnabled: widget.currentLevel > 0 && !widget.isUpdating,
            contentColor: contentColor,
            isTop: false,
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isEnabled,
    required Color contentColor,
    required bool isTop,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: EdgeInsets.only(
          top: isTop ? 30 : 10,
          bottom: isTop ? 10 : 30,
        ),
        child: FaIcon(
          icon,
          size: 70,
          color: isEnabled
              ? contentColor
              : contentColor.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
