import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/coin_counter.dart';

/// 7-day streak reward. Claimed days are checked, today glows gold, day 7 is
/// the big chest so the streak has a visible goal.
class DailyRewardDialog extends StatelessWidget {
  const DailyRewardDialog({super.key});

  static const List<int> dailyRewards = [500, 750, 1000, 1250, 1500, 2000, 3000];

  @override
  Widget build(BuildContext context) {
    const currentStreakDay = 3;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    Widget dayTile(int index, {bool wide = false}) {
      final day = index + 1;
      final isClaimed = day < currentStreakDay;
      final isToday = day == currentStreakDay;

      Widget tile = Container(
        height: wide ? 64 : 84,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: isToday ? PatiiColors.goldButtonGradient : null,
          color: isToday ? null : Colors.white.withValues(alpha: isClaimed ? 0.03 : 0.06),
          border: Border.all(color: isToday ? Colors.transparent : PatiiColors.hairline),
          boxShadow: isToday
              ? [BoxShadow(color: PatiiColors.gold.withValues(alpha: 0.4), blurRadius: 16)]
              : null,
        ),
        child: Opacity(
          opacity: isClaimed ? 0.55 : 1,
          child: Flex(
            direction: wide ? Axis.horizontal : Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${'economy.day'.tr()} $day',
                style: PatiiTypography.body(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isToday ? const Color(0xFF3A2A06) : PatiiColors.textSecondary,
                ),
              ),
              SizedBox(width: wide ? 12 : 0, height: wide ? 0 : 4),
              isClaimed
                  ? const Icon(Icons.check_circle_rounded, size: 22, color: PatiiColors.success)
                  : wide
                      ? const Icon(Icons.inventory_2_rounded, size: 26, color: PatiiColors.gold)
                      : const CoinGlyph(size: 22),
              SizedBox(width: wide ? 12 : 0, height: wide ? 0 : 4),
              Text(
                CoinCounter.formatCoins(dailyRewards[index]),
                style: PatiiTypography.display(
                  fontSize: wide ? 16 : 12.5,
                  fontWeight: FontWeight.w800,
                  color: isToday ? const Color(0xFF241A05) : PatiiColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
      if (isToday && !reduceMotion) {
        tile = tile
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(begin: 1, end: 1.05, duration: 900.ms, curve: Curves.easeInOut);
      }
      return tile;
    }

    return Dialog(
      backgroundColor: PatiiColors.navyElevated,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: PatiiColors.goldButtonGradient,
                    boxShadow: [BoxShadow(color: PatiiColors.gold.withValues(alpha: 0.45), blurRadius: 24)],
                  ),
                  child: const Icon(Icons.redeem_rounded, size: 28, color: Color(0xFF241A05)),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'economy.daily_reward'.tr(),
                textAlign: TextAlign.center,
                style: PatiiTypography.display(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                '${'economy.streak'.tr()}: $currentStreakDay ${'economy.day'.tr()}',
                textAlign: TextAlign.center,
                style: PatiiTypography.body(fontSize: 13.5, fontWeight: FontWeight.w600, color: PatiiColors.goldLight),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: dayTile(i)),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 3; i < 6; i++) ...[
                    if (i > 3) const SizedBox(width: 8),
                    Expanded(child: dayTile(i)),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              dayTile(6, wide: true),
              const SizedBox(height: 20),
              GoldButton(
                label: 'economy.claim'.tr(),
                icon: Icons.redeem_rounded,
                height: 50,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
