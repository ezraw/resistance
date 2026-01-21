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
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  Color _previousColor = Colors.green;
  Color _targetColor = Colors.green;
  bool _isIncreasing = true;

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

    // Wave animation for color transitions
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _waveAnimation = CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeOutCubic,
    );

    _previousColor = _getColorForLevel(widget.currentLevel);
    _targetColor = _previousColor;
  }

  @override
  void didUpdateWidget(ResistanceControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLevel != widget.currentLevel) {
      // Capture current interpolated color if animation is in progress
      if (_waveController.isAnimating) {
        _previousColor = Color.lerp(_previousColor, _targetColor, _waveAnimation.value)!;
      } else {
        _previousColor = _getColorForLevel(oldWidget.currentLevel);
      }
      _targetColor = _getColorForLevel(widget.currentLevel);
      _isIncreasing = widget.currentLevel > oldWidget.currentLevel;
      _waveController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Color _getColorForLevel(int level) {
    // Gradient: green (1-2) → yellow (3-5) → orange (6-7) → red (8-10)
    switch (level) {
      case 1:
        return const Color(0xFF4CAF50); // Green
      case 2:
        return const Color(0xFF8BC34A); // Light green
      case 3:
        return const Color(0xFFCDDC39); // Lime
      case 4:
        return const Color(0xFFFFEB3B); // Yellow
      case 5:
        return const Color(0xFFFFC107); // Amber
      case 6:
        return const Color(0xFFFF9800); // Orange
      case 7:
        return const Color(0xFFFF5722); // Deep orange
      case 8:
        return const Color(0xFFF44336); // Red
      case 9:
        return const Color(0xFFE53935); // Red darken
      case 10:
        return const Color(0xFFB71C1C); // Dark red
      default:
        return const Color(0xFF4CAF50);
    }
  }

  void _handleIncrease() {
    if (widget.currentLevel >= 10 || widget.isUpdating) return;
    _pulseController.forward(from: 0);
    widget.onIncrease();
  }

  void _handleDecrease() {
    if (widget.currentLevel <= 1 || widget.isUpdating) return;
    _pulseController.forward(from: 0);
    widget.onDecrease();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _waveAnimation]),
      builder: (context, child) {
        final waveProgress = _waveAnimation.value;

        // Calculate the display color for UI elements (interpolated based on wave progress)
        final displayColor = Color.lerp(_previousColor, _targetColor, waveProgress)!;

        return Stack(
          children: [
            // Base layer: previous color with pulse effect
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: _pulseAnimation.value,
                  colors: [
                    _previousColor,
                    _previousColor.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),

            // Wave overlay: new color sweeping in with gradient trail
            if (waveProgress > 0 && waveProgress < 1)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: _isIncreasing ? Alignment.bottomCenter : Alignment.topCenter,
                      end: _isIncreasing ? Alignment.topCenter : Alignment.bottomCenter,
                      colors: [
                        _targetColor,
                        _targetColor,
                        _targetColor.withValues(alpha: 0.0),
                      ],
                      stops: [
                        0.0,
                        (waveProgress - 0.08).clamp(0.0, 1.0),  // Sharp edge
                        waveProgress.clamp(0.0, 1.0),           // Short fade
                      ],
                    ),
                  ),
                ),
              ),

            // Final state: target color when animation completes
            if (waveProgress >= 1)
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: _pulseAnimation.value,
                    colors: [
                      _targetColor,
                      _targetColor.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),

            // UI content layer
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
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
            isEnabled: widget.currentLevel < 10 && !widget.isUpdating,
            contentColor: contentColor,
            isTop: true,
          ),

          // Level number
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              '${widget.currentLevel}',
              style: TextStyle(
                fontSize: 100,
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
            isEnabled: widget.currentLevel > 1 && !widget.isUpdating,
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

