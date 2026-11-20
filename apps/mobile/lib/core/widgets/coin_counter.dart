import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'buttons.dart';

/// Painted gold coin with a dhaka diamond stamp.
class CoinGlyph extends StatelessWidget {
  final double size;

  const CoinGlyph({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _CoinPainter());
  }
}

class _CoinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE7A3), PatiiColors.gold, Color(0xFFC98B1E)],
        ).createShader(rect),
    );
    canvas.drawCircle(
      c,
      r * 0.72,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.1
        ..color = const Color(0xFFB07A18).withValues(alpha: 0.7),
    );
    final d = r * 0.32;
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy - d)
        ..lineTo(c.dx + d, c.dy)
        ..lineTo(c.dx, c.dy + d)
        ..lineTo(c.dx - d, c.dy)
        ..close(),
      Paint()..color = const Color(0xFFB07A18),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Coin balance capsule. The number counts up/down when [coins] changes.
class CoinCounter extends StatelessWidget {
  final int coins;
  final double fontSize;
  final bool showPlusButton;
  final VoidCallback? onPlusTap;

  const CoinCounter({
    super.key,
    required this.coins,
    this.fontSize = 15.0,
    this.showPlusButton = false,
    this.onPlusTap,
  });

  static String formatCoins(int value) {
    return value.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: fontSize + 21,
      padding: EdgeInsets.only(left: 5, right: showPlusButton ? 4 : 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: PatiiColors.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CoinGlyph(size: fontSize + 9),
          const SizedBox(width: 7),
          TweenAnimationBuilder<double>(
            // begin is only used on first build (no count-up from 0 on every
            // screen open); later changes animate from the current value.
            tween: Tween<double>(begin: coins.toDouble(), end: coins.toDouble()),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, val, child) {
              return Text(
                formatCoins(val.round()),
                style: PatiiTypography.display(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: PatiiColors.textPrimary,
                  letterSpacing: 0,
                ),
              );
            },
          ),
          if (showPlusButton) ...[
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: 'Add coins',
              child: Pressable(
                onPressed: onPlusTap,
                child: Container(
                  width: fontSize + 13,
                  height: fontSize + 13,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: PatiiColors.goldButtonGradient,
                  ),
                  child: Icon(Icons.add_rounded, size: fontSize, color: const Color(0xFF241A05)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
