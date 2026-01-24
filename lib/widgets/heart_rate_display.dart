import 'package:flutter/material.dart';

/// Displays heart rate with animated heart icon
class HeartRateDisplay extends StatefulWidget {
  final int? bpm;
  final bool isConnected;
  final VoidCallback? onTap;
  final TextStyle? style;

  const HeartRateDisplay({
    super.key,
    this.bpm,
    this.isConnected = false,
    this.onTap,
    this.style,
  });

  @override
  State<HeartRateDisplay> createState() => _HeartRateDisplayState();
}

class _HeartRateDisplayState extends State<HeartRateDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start pulsing if we have a heart rate
    if (widget.bpm != null && widget.bpm! > 0) {
      _startPulsing();
    }
  }

  @override
  void didUpdateWidget(HeartRateDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bpm != null && widget.bpm! > 0 && !_pulseController.isAnimating) {
      _startPulsing();
    } else if ((widget.bpm == null || widget.bpm == 0) && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  void _startPulsing() {
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasHeartRate = widget.bpm != null && widget.bpm! > 0;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: hasHeartRate ? _pulseAnimation.value : 1.0,
                child: Icon(
                  Icons.favorite,
                  color: hasHeartRate
                      ? Colors.red
                      : Colors.white.withValues(alpha: 0.5),
                  size: 20,
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          Text(
            hasHeartRate ? '${widget.bpm}' : '--',
            style: widget.style ?? TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: hasHeartRate
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 2),
          Text(
            'bpm',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
