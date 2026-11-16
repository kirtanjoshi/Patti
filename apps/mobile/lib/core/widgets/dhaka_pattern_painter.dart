import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// CustomPainter for the traditional Nepali Dhaka geometric pattern
/// Used on card backs, casino table trims, and luxury accents.
class DhakaPatternPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  const DhakaPatternPainter({
    this.primaryColor = PatiiColors.gold,
    this.secondaryColor = PatiiColors.crimson,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final goldPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final fillPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final crimsonPaint = Paint()
      ..color = secondaryColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    const step = 14.0;

    for (double y = 0; y < size.height + step; y += step) {
      for (double x = 0; x < size.width + step; x += step) {
        final cx = x;
        final cy = y;

        // Diamond path
        final diamond = Path()
          ..moveTo(cx, cy - step / 2)
          ..lineTo(cx + step / 2, cy)
          ..lineTo(cx, cy + step / 2)
          ..lineTo(cx - step / 2, cy)
          ..close();

        // Alternating fill
        if (((x / step).floor() + (y / step).floor()) % 2 == 0) {
          canvas.drawPath(diamond, fillPaint);
        } else {
          canvas.drawPath(diamond, crimsonPaint);
        }

        canvas.drawPath(diamond, goldPaint);

        // Center dot
        canvas.drawCircle(
          Offset(cx, cy),
          0.8,
          Paint()..color = primaryColor,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant DhakaPatternPainter oldDelegate) =>
      primaryColor != oldDelegate.primaryColor ||
      secondaryColor != oldDelegate.secondaryColor;
}
