import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

enum TableFeltShape {
  roundedRect,
  oval,
}

/// Landscape Casino Table Felt Widget
/// Wood rail (14px, gradient with thin gold line), felt radial gradient, and gold watermark.
class TableFelt extends StatelessWidget {
  final Widget child;
  final TableFeltShape shape;
  final String watermarkText;

  const TableFelt({
    super.key,
    required this.child,
    this.shape = TableFeltShape.roundedRect,
    this.watermarkText = 'PATII',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: PatiiColors.navy,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: shape == TableFeltShape.oval
                ? BorderRadius.circular(160.0)
                : BorderRadius.circular(32.0),
            gradient: PatiiColors.woodRailGradient,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 16.0,
                spreadRadius: 2.0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14.0), // 14px wood rail
          child: Container(
            decoration: BoxDecoration(
              borderRadius: shape == TableFeltShape.oval
                  ? BorderRadius.circular(146.0)
                  : BorderRadius.circular(20.0),
              border: Border.all(
                color: PatiiColors.woodRailGoldLine.withValues(alpha: 0.8),
                width: 1.5, // Thin gold inner line
              ),
              gradient: PatiiColors.feltGradient,
            ),
            child: ClipRRect(
              borderRadius: shape == TableFeltShape.oval
                  ? BorderRadius.circular(144.0)
                  : BorderRadius.circular(18.0),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Subtle Felt Weave Noise Layer (4% opacity)
                  CustomPaint(
                    painter: _FeltTexturePainter(),
                  ),

                  // Center Watermark Logo
                  Center(
                    child: Text(
                      watermarkText,
                      style: PatiiTypography.cinzel(
                        fontSize: 72.0,
                        fontWeight: FontWeight.w900,
                        color: PatiiColors.gold.withValues(alpha: 0.06), // 6% gold watermark
                        letterSpacing: 12.0,
                      ),
                    ),
                  ),

                  // Table Children
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeltTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 0.5;

    const spacing = 12.0;
    for (double i = -size.height; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
