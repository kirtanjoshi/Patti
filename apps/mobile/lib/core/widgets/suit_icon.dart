import 'dart:math' as math;
import 'package:flutter/material.dart' hide Card;
import 'package:patii_engine/patii_engine.dart' as engine;

/// Vector card suits. Font glyphs (♠♥♦♣) render as colour emoji on many
/// Android builds and differ per OEM; paths look identical everywhere.
class SuitIcon extends StatelessWidget {
  final engine.Suit suit;
  final double size;
  final Color color;

  const SuitIcon({
    super.key,
    required this.suit,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: SuitPainter(suit, color),
    );
  }
}

class SuitPainter extends CustomPainter {
  final engine.Suit suit;
  final Color color;

  const SuitPainter(this.suit, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas.save();
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);
    canvas.scale(s);
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true;
    switch (suit) {
      case engine.Suit.H:
        canvas.drawPath(_heart, paint);
      case engine.Suit.D:
        canvas.drawPath(_diamond, paint);
      case engine.Suit.S:
        canvas.drawPath(_spade, paint);
        canvas.drawPath(_stem, paint);
      case engine.Suit.C:
        canvas.drawCircle(const Offset(0.5, 0.28), 0.215, paint);
        canvas.drawCircle(const Offset(0.255, 0.585), 0.215, paint);
        canvas.drawCircle(const Offset(0.745, 0.585), 0.215, paint);
        canvas.drawCircle(const Offset(0.5, 0.55), 0.14, paint);
        canvas.drawPath(_stem, paint);
      case engine.Suit.X:
        canvas.drawPath(_star, paint);
    }
    canvas.restore();
  }

  static final Path _heart = Path()
    ..moveTo(0.5, 0.98)
    ..cubicTo(0.36, 0.84, 0.0, 0.62, 0.0, 0.32)
    ..cubicTo(0.0, 0.12, 0.15, 0.02, 0.29, 0.02)
    ..cubicTo(0.4, 0.02, 0.47, 0.09, 0.5, 0.18)
    ..cubicTo(0.53, 0.09, 0.6, 0.02, 0.71, 0.02)
    ..cubicTo(0.85, 0.02, 1.0, 0.12, 1.0, 0.32)
    ..cubicTo(1.0, 0.62, 0.64, 0.84, 0.5, 0.98)
    ..close();

  static final Path _diamond = Path()
    ..moveTo(0.5, 0.0)
    ..quadraticBezierTo(0.66, 0.3, 0.9, 0.5)
    ..quadraticBezierTo(0.66, 0.7, 0.5, 1.0)
    ..quadraticBezierTo(0.34, 0.7, 0.1, 0.5)
    ..quadraticBezierTo(0.34, 0.3, 0.5, 0.0)
    ..close();

  static final Path _spade = Path()
    ..moveTo(0.5, 0.0)
    ..cubicTo(0.36, 0.18, 0.0, 0.38, 0.0, 0.62)
    ..cubicTo(0.0, 0.8, 0.14, 0.88, 0.28, 0.88)
    ..cubicTo(0.38, 0.88, 0.46, 0.83, 0.5, 0.74)
    ..cubicTo(0.54, 0.83, 0.62, 0.88, 0.72, 0.88)
    ..cubicTo(0.86, 0.88, 1.0, 0.8, 1.0, 0.62)
    ..cubicTo(1.0, 0.38, 0.64, 0.18, 0.5, 0.0)
    ..close();

  static final Path _stem = Path()
    ..moveTo(0.47, 0.62)
    ..cubicTo(0.46, 0.84, 0.41, 0.94, 0.3, 1.0)
    ..lineTo(0.7, 1.0)
    ..cubicTo(0.59, 0.94, 0.54, 0.84, 0.53, 0.62)
    ..close();

  static final Path _star = () {
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? 0.5 : 0.21;
      final a = -math.pi / 2 + i * math.pi / 5;
      final pt = Offset(0.5 + r * math.cos(a), 0.53 + r * math.sin(a));
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    return p..close();
  }();

  @override
  bool shouldRepaint(covariant SuitPainter old) =>
      old.suit != suit || old.color != color;
}
