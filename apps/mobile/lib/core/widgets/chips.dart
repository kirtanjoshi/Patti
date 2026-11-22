import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

enum ChipDenomination {
  c10(10, PatiiColors.chipWhite, PatiiColors.navy),
  c50(50, PatiiColors.chipRed, Colors.white),
  c100(100, PatiiColors.chipBlue, Colors.white),
  c500(500, PatiiColors.chipGreen, Colors.white),
  c1000(1000, PatiiColors.chipGold, PatiiColors.navy);

  final int value;
  final Color primaryColor;
  final Color textColor;

  const ChipDenomination(this.value, this.primaryColor, this.textColor);

  static ChipDenomination fromValue(int val) {
    if (val >= 1000) return ChipDenomination.c1000;
    if (val >= 500) return ChipDenomination.c500;
    if (val >= 100) return ChipDenomination.c100;
    if (val >= 50) return ChipDenomination.c50;
    return ChipDenomination.c10;
  }
}

/// Casino Chip Widget
class CasinoChip extends StatelessWidget {
  final ChipDenomination denomination;
  final double size;

  const CasinoChip({
    super.key,
    required this.denomination,
    this.size = 28.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: denomination.primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 3.0,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _ChipEdgePainter(
          stripe: denomination == ChipDenomination.c10
              ? PatiiColors.chipBlue
              : Colors.white.withValues(alpha: 0.85),
        ),
        child: Center(
          child: Container(
            width: size * 0.72,
            height: size * 0.72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: denomination.textColor.withValues(alpha: 0.4),
                width: 1.0,
              ),
            ),
            child: Center(
              child: Text(
                denomination.value >= 1000
                    ? '${denomination.value ~/ 1000}k'
                    : '${denomination.value}',
                style: PatiiTypography.display(
                  fontSize: size * 0.28,
                  fontWeight: FontWeight.w900,
                  color: denomination.textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Six edge stripes, the visual signature of a casino chip.
class _ChipEdgePainter extends CustomPainter {
  final Color stripe;

  const _ChipEdgePainter({required this.stripe});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final paint = Paint()
      ..color = stripe
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.22;
    final rect = Rect.fromCircle(center: c, radius: r * 0.89);
    for (var i = 0; i < 6; i++) {
      canvas.drawArc(rect, i * 3.14159 / 3, 0.32, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChipEdgePainter old) => old.stripe != stripe;
}

/// Casino Chip Stack
/// Displays multiple chips stacked vertically with realistic edge depth.
class ChipStack extends StatelessWidget {
  final int totalAmount;
  final double chipSize;
  final int maxVisibleChips;

  const ChipStack({
    super.key,
    required this.totalAmount,
    this.chipSize = 32.0,
    this.maxVisibleChips = 5,
  });

  @override
  Widget build(BuildContext context) {
    if (totalAmount <= 0) return const SizedBox.shrink();

    final denom = ChipDenomination.fromValue(totalAmount);
    final count = (totalAmount / denom.value).clamp(1, maxVisibleChips).toInt();

    return SizedBox(
      width: chipSize,
      height: chipSize + (count - 1) * 4.0,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: List.generate(count, (index) {
          final bottomOffset = index * 4.0;
          return Positioned(
            bottom: bottomOffset,
            child: CasinoChip(
              denomination: denom,
              size: chipSize,
            ),
          );
        }),
      ),
    );
  }
}

/// Animated Chip Toss from seat to pot
class ChipToss extends StatefulWidget {
  final Offset startOffset;
  final Offset endOffset;
  final int amount;
  final VoidCallback onComplete;

  const ChipToss({
    super.key,
    required this.startOffset,
    required this.endOffset,
    required this.amount,
    required this.onComplete,
  });

  @override
  State<ChipToss> createState() => _ChipTossState();
}

class _ChipTossState extends State<ChipToss>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    AudioService.instance.playChip();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

    _controller.forward().then((_) {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final t = _animation.value;
        // Parabolic arc for toss effect
        final arcY = -40.0 * 4 * t * (1 - t);
        final currentX = widget.startOffset.dx +
            (widget.endOffset.dx - widget.startOffset.dx) * t;
        final currentY = widget.startOffset.dy +
            (widget.endOffset.dy - widget.startOffset.dy) * t +
            arcY;

        return Positioned(
          left: currentX - 14.0,
          top: currentY - 14.0,
          child: Transform.rotate(
            angle: t * 3.14159,
            child: CasinoChip(
              denomination: ChipDenomination.fromValue(widget.amount),
              size: 28.0,
            ),
          ),
        );
      },
    );
  }
}
