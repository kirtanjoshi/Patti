import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

/// Animated Coin Counter Widget
/// Gold coin icon + Cinzel tabular number that smoothly interpolates up/down on value changes.
class CoinCounter extends StatelessWidget {
  final int coins;
  final double fontSize;
  final bool showPlusButton;
  final VoidCallback? onPlusTap;

  const CoinCounter({
    super.key,
    required this.coins,
    this.fontSize = 16.0,
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
      padding: EdgeInsets.symmetric(
        horizontal: showPlusButton ? 8.0 : 10.0,
        vertical: 4.0,
      ),
      decoration: BoxDecoration(
        color: PatiiColors.navySurface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: PatiiColors.gold.withValues(alpha: 0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 3D Embossed Gold Coin Icon
          Container(
            width: fontSize + 6,
            height: fontSize + 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: PatiiColors.goldButtonGradient,
              border: Border.all(color: PatiiColors.goldDark, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: PatiiColors.gold.withValues(alpha: 0.5),
                  blurRadius: 3.0,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '¢',
                style: TextStyle(
                  fontSize: fontSize * 0.75,
                  fontWeight: FontWeight.w900,
                  color: PatiiColors.navy,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6.0),

          // Animated Cinzel Tabular Number
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: coins.toDouble(), end: coins.toDouble()),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, val, child) {
              return Text(
                formatCoins(val.round()),
                style: PatiiTypography.cinzel(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: PatiiColors.goldLight,
                ),
              );
            },
          ),

          // Optional Plus Button for Buying / Claiming Coins
          if (showPlusButton) ...[
            const SizedBox(width: 6.0),
            GestureDetector(
              onTap: onPlusTap,
              child: Container(
                width: 20.0,
                height: 20.0,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: PatiiColors.goldButtonGradient,
                ),
                child: const Icon(
                  Icons.add,
                  size: 14.0,
                  color: PatiiColors.navy,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
