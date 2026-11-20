import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/chips.dart';
import '../../../../core/widgets/coin_counter.dart';

/// Centre pot: chip stacks over a large counting number.
/// The number rolls to each new total and the chips pop when the pot grows.
class TeenPattiPotCenter extends StatelessWidget {
  final int pot;
  final int currentStake;
  final int? lastBetAmount;

  const TeenPattiPotCenter({
    super.key,
    required this.pot,
    required this.currentStake,
    this.lastBetAmount,
  });

  @override
  Widget build(BuildContext context) {
    final formattedPot = NumberFormat('#,###').format(pot);
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    Widget chips = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ChipStack(totalAmount: pot ~/ 3, chipSize: 26, maxVisibleChips: 3),
        const SizedBox(width: 3),
        ChipStack(totalAmount: pot, chipSize: 30, maxVisibleChips: 5),
        const SizedBox(width: 3),
        ChipStack(totalAmount: pot ~/ 2, chipSize: 26, maxVisibleChips: 4),
      ],
    );
    if (!reduceMotion) {
      chips = chips
          .animate(key: ValueKey(pot))
          .scaleXY(begin: 0.9, end: 1, duration: 260.ms, curve: Curves.easeOutBack);
    }

    return Semantics(
      label: '${'teenpatti.pot'.tr()}: $formattedPot, ${'teenpatti.stake'.tr()}: $currentStake',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            chips,
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.fromLTRB(6, 4, 14, 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: PatiiColors.hairline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CoinGlyph(size: 22),
                  const SizedBox(width: 8),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: pot.toDouble(), end: pot.toDouble()),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => Text(
                      CoinCounter.formatCoins(v.round()),
                      style: PatiiTypography.display(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: PatiiColors.goldLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'teenpatti.pot'.tr().toUpperCase(),
              style: PatiiTypography.eyebrow(fontSize: 9.5, color: Colors.white.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}
