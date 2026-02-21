import 'package:flutter/material.dart';
import '../../painters/pixel_border_painter.dart';

/// A container with pixel stair-step corners. Drop-in replacement for
/// `Container` + `BoxDecoration` + `BorderRadius` in arcade widgets.
class PixelContainer extends StatelessWidget {
  final Widget? child;
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;
  final double notchSize;
  final EdgeInsetsGeometry padding;

  const PixelContainer({
    super.key,
    this.child,
    required this.fillColor,
    required this.borderColor,
    this.borderWidth = 2,
    this.notchSize = 3,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: PixelBorderPainter(
        fillColor: fillColor,
        borderColor: borderColor,
        borderWidth: borderWidth,
        notchSize: notchSize,
      ),
      child: ClipPath(
        clipper: _PixelBorderClipper(notchSize: notchSize),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// Clips child content to the pixel stair-step border path.
class _PixelBorderClipper extends CustomClipper<Path> {
  final double notchSize;

  const _PixelBorderClipper({required this.notchSize});

  @override
  Path getClip(Size size) {
    return buildPixelBorderPath(Offset.zero & size, notchSize);
  }

  @override
  bool shouldReclip(_PixelBorderClipper oldClipper) =>
      notchSize != oldClipper.notchSize;
}
