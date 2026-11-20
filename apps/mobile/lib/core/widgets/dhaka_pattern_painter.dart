import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Traditional Nepali Dhaka lattice, drawn as fine line-work.
/// Used on card backs and as a faint texture accent. Kept deliberately thin:
/// at small sizes a filled pattern turns into noise.
class DhakaPatternPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final double step;

  const DhakaPatternPainter({
    this.primaryColor = PatiiColors.gold,
    this.secondaryColor = PatiiColors.crimson,
    this.step = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    final dot = Paint()..color = secondaryColor;

    final h = step / 2;
    for (double y = 0; y < size.height + step; y += step) {
      for (double x = 0; x < size.width + step; x += step) {
        final diamond = Path()
          ..moveTo(x, y - h)
          ..lineTo(x + h, y)
          ..lineTo(x, y + h)
          ..lineTo(x - h, y)
          ..close();
        canvas.drawPath(diamond, line);
        if (secondaryColor.a > 0) {
          final q = h * 0.28;
          canvas.drawPath(
            Path()
              ..moveTo(x, y - q)
              ..lineTo(x + q, y)
              ..lineTo(x, y + q)
              ..lineTo(x - q, y)
              ..close(),
            dot,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant DhakaPatternPainter oldDelegate) =>
      primaryColor != oldDelegate.primaryColor ||
      secondaryColor != oldDelegate.secondaryColor ||
      step != oldDelegate.step;
}
