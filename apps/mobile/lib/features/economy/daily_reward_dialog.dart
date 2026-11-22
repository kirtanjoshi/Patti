import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/coin_counter.dart';
import '../../core/widgets/toast_banner.dart';

/// 7-day streak reward. Claimed days are checked, today glows gold, day 7 is
/// the big chest so the streak has a visible goal.
class DailyRewardDialog extends ConsumerStatefulWidget {
  const DailyRewardDialog({super.key});

  static const List<int> dailyRewards = [
    500,
    750,
    1000,
    1250,
    1500,
    2000,
    3000
  ];

  @override
  ConsumerState<DailyRewardDialog> createState() => _DailyRewardDialogState();
}

class _DailyRewardDialogState extends ConsumerState<DailyRewardDialog> {
  int _currentStreak = 1;
  bool _isClaimedToday = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStreakState();
  }

  Future<void> _loadStreakState() async {
    final notifier = ref.read(authProvider.notifier);
    final streak = await notifier.getDailyStreak();
    final claimed = await notifier.isDailyRewardClaimedToday();
    if (mounted) {
      setState(() {
        _currentStreak = streak.clamp(1, 7);
        _isClaimedToday = claimed;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleClaim() async {
    if (_isClaimedToday) return;

    HapticFeedback.heavyImpact();
    final notifier = ref.read(authProvider.notifier);
    final amount = await notifier.claimDailyReward();

    if (!mounted) return;

    if (amount > 0) {
      AudioService.instance.playCoinsCollect();
      AudioService.instance.playWinJingle();
      setState(() => _isClaimedToday = true);
      ToastBanner.show(
        context,
        'Claimed +$amount coins! Daily streak: Day $_currentStreak',
        icon: Icons.celebration_rounded,
      );
      Future.delayed(const Duration(milliseconds: 750), () {
        if (mounted) Navigator.of(context).pop();
      });
    } else {
      setState(() => _isClaimedToday = true);
      ToastBanner.show(
        context,
        'Daily reward already claimed today!',
        icon: Icons.check_circle_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final rewardAmount = DailyRewardDialog.dailyRewards[_currentStreak - 1];

    Widget dayTile(int index, {bool wide = false}) {
      final day = index + 1;
      final isPast = day < _currentStreak;
      final isToday = day == _currentStreak;
      final isClaimed = isPast || (isToday && _isClaimedToday);

      Widget tile = Container(
        height: wide ? 64 : 84,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: (isToday && !_isClaimedToday)
              ? PatiiColors.goldButtonGradient
              : null,
          color: (isToday && !_isClaimedToday)
              ? null
              : Colors.white.withValues(alpha: isClaimed ? 0.03 : 0.06),
          border: Border.all(
            color: (isToday && !_isClaimedToday)
                ? Colors.transparent
                : PatiiColors.hairline,
          ),
          boxShadow: (isToday && !_isClaimedToday)
              ? [
                  BoxShadow(
                      color: PatiiColors.gold.withValues(alpha: 0.4),
                      blurRadius: 16)
                ]
              : null,
        ),
        child: Opacity(
          opacity: isClaimed ? 0.6 : 1,
          child: Flex(
            direction: wide ? Axis.horizontal : Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${'economy.day'.tr()} $day',
                style: PatiiTypography.body(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: (isToday && !_isClaimedToday)
                      ? const Color(0xFF3A2A06)
                      : PatiiColors.textSecondary,
                ),
              ),
              SizedBox(width: wide ? 12 : 0, height: wide ? 0 : 4),
              isClaimed
                  ? const Icon(Icons.check_circle_rounded,
                      size: 22, color: PatiiColors.success)
                  : wide
                      ? const Icon(Icons.inventory_2_rounded,
                          size: 26, color: PatiiColors.gold)
                      : const CoinGlyph(size: 22),
              SizedBox(width: wide ? 12 : 0, height: wide ? 0 : 4),
              Text(
                CoinCounter.formatCoins(DailyRewardDialog.dailyRewards[index]),
                style: PatiiTypography.display(
                  fontSize: wide ? 16 : 12.5,
                  fontWeight: FontWeight.w800,
                  color: (isToday && !_isClaimedToday)
                      ? const Color(0xFF241A05)
                      : PatiiColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
      if (isToday && !_isClaimedToday && !reduceMotion) {
        tile = tile.animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(
            begin: 1, end: 1.05, duration: 900.ms, curve: Curves.easeInOut);
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
                    boxShadow: [
                      BoxShadow(
                          color: PatiiColors.gold.withValues(alpha: 0.45),
                          blurRadius: 24),
                    ],
                  ),
                  child: const Icon(Icons.redeem_rounded,
                      size: 28, color: Color(0xFF241A05)),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'economy.daily_reward'.tr(),
                textAlign: TextAlign.center,
                style: PatiiTypography.display(
                    fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                '${'economy.streak'.tr()}: $_currentStreak ${'economy.day'.tr()}',
                textAlign: TextAlign.center,
                style: PatiiTypography.body(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: PatiiColors.goldLight,
                ),
              ),
              const SizedBox(height: 18),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: PatiiColors.gold),
                  ),
                )
              else ...[
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
                _isClaimedToday
                    ? OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: PatiiColors.textMuted,
                          side: const BorderSide(color: PatiiColors.hairline),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.check_circle_rounded,
                            color: PatiiColors.success),
                        label: const Text(
                          'Claimed Today • Come back tomorrow!',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      )
                    : GoldButton(
                        label:
                            '${'economy.claim'.tr()} +${CoinCounter.formatCoins(rewardAmount)}',
                        icon: Icons.redeem_rounded,
                        height: 50,
                        onPressed: _handleClaim,
                      ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
