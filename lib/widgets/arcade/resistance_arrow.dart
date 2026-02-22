import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

enum ArrowDirection { up, down }

/// A wide, chunky pixel-art stair-stepped arrow.
///
/// Uses a 10x7 block grid with stair-step edges (all 90-degree angles).
/// Includes a 3D shadow rendered 1 block below the body.
///
/// Sizing: [widthFraction] of parent width via LayoutBuilder.
/// Height derived from 10:7 aspect ratio.
class ResistanceArrow extends StatelessWidget {
  final ArrowDirection direction;
  final Color color;
  final Color shadowColor;
  final double widthFraction;

  const ResistanceArrow({
    super.key,
    required this.direction,
    this.color = AppColors.gold,
    this.shadowColor = AppColors.goldDark,
    this.widthFraction = 0.45,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth * widthFraction;
        final height = width * 7 / 10; // 10:7 aspect ratio
        return CustomPaint(
          size: Size(width, height + width / 10), // extra row for shadow
          painter: _ArrowPainter(
            direction: direction,
            color: color,
            shadowColor: shadowColor,
          ),
        );
      },
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final ArrowDirection direction;
  final Color color;
  final Color shadowColor;

  _ArrowPainter({
    required this.direction,
    required this.color,
    required this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Block size: width covers 10 blocks
    final block = size.width / 10;

    // Up arrow shape on a 10x7 grid:
    // R0: cols 4-5       (2 blocks - tip)
    // R1: cols 3-6       (4 blocks)
    // R2: cols 2-7       (6 blocks)
    // R3: cols 1-8       (8 blocks)
    // R4: cols 0-9       (10 blocks - full width)
    // R5: cols 2-7       (6 blocks - shaft)
    // R6: cols 2-7       (6 blocks - shaft)
    //
    // Down arrow is vertically mirrored.

    // Define rows as (startCol, endCol) pairs — endCol is exclusive
    final List<List<int>> upRows = [
      [4, 6],   // R0: tip
      [3, 7],   // R1
      [2, 8],   // R2
      [1, 9],   // R3
      [0, 10],  // R4: full width
      [2, 8],   // R5: shaft
      [2, 8],   // R6: shaft
    ];

    final rows = direction == ArrowDirection.up
        ? upRows
        : upRows.reversed.toList();

    // Draw shadow first (offset 1 block down)
    final shadowPaint = Paint()..color = shadowColor;
    for (int r = 0; r < rows.length; r++) {
      final startCol = rows[r][0];
      final endCol = rows[r][1];
      for (int c = startCol; c < endCol; c++) {
        canvas.drawRect(
          Rect.fromLTWH(c * block, (r + 1) * block, block, block),
          shadowPaint,
        );
      }
    }

    // Draw body on top
    final bodyPaint = Paint()..color = color;
    for (int r = 0; r < rows.length; r++) {
      final startCol = rows[r][0];
      final endCol = rows[r][1];
      for (int c = startCol; c < endCol; c++) {
        canvas.drawRect(
          Rect.fromLTWH(c * block, r * block, block, block),
          bodyPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) =>
      direction != oldDelegate.direction ||
      color != oldDelegate.color ||
      shadowColor != oldDelegate.shadowColor;
}
