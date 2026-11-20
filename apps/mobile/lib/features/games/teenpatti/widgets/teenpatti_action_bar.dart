import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/buttons.dart';

/// Teen Patti actions, right thumb zone.
/// Hierarchy: Chaal/Show is the one gold primary; Raise and Side Show are
/// secondary; Pack is destructive. Off-turn, everything goes neutral.
class TeenPattiActionBar extends StatelessWidget {
  final bool isMyTurn;
  final bool isSeen;
  final int currentStake;
  final int activePlayerCount;
  final bool canSideShow;
  final bool canShow;
  final bool isBlindLimitReached;
  final ValueChanged<int> onChaal;
  final VoidCallback onPack;
  final VoidCallback onSideShow;
  final VoidCallback onShow;
  final VoidCallback? onSeeCards;

  const TeenPattiActionBar({
    super.key,
    required this.isMyTurn,
    required this.isSeen,
    required this.currentStake,
    required this.activePlayerCount,
    required this.canSideShow,
    required this.canShow,
    this.isBlindLimitReached = false,
    required this.onChaal,
    required this.onPack,
    required this.onSideShow,
    required this.onShow,
    this.onSeeCards,
  });

  int get baseBet => isSeen ? currentStake * 2 : currentStake;
  int get raiseBet => isSeen ? currentStake * 4 : currentStake * 2;

  @override
  Widget build(BuildContext context) {
    const h = 44.0;
    const pad = EdgeInsets.symmetric(horizontal: 14);
    final canBet = isMyTurn && (!isBlindLimitReached || isSeen);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (isBlindLimitReached && !isSeen && isMyTurn)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'teenpatti.blind_limit_reached'.tr(),
              style: PatiiTypography.body(fontSize: 12, fontWeight: FontWeight.w700, color: PatiiColors.warning),
            ),
          )
        else if (!isMyTurn)
          Padding(
            padding: const EdgeInsets.only(bottom: 6, right: 4),
            child: Text(
              'table.waiting'.tr(),
              style: PatiiTypography.eyebrow(fontSize: 10, color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            DangerButton(
              label: 'teenpatti.pack'.tr(),
              height: h,
              padding: pad,
              isEnabled: isMyTurn,
              onPressed: onPack,
            ),
            GhostButton(
              label: 'teenpatti.sideshow'.tr(),
              icon: Icons.compare_arrows_rounded,
              height: h,
              padding: pad,
              isEnabled: isMyTurn && canSideShow,
              onPressed: onSideShow,
            ),
            if (!canShow)
              GhostButton(
                label: '+$raiseBet',
                height: h,
                padding: pad,
                isEnabled: canBet,
                onPressed: () => onChaal(raiseBet),
              ),
            if (canShow)
              GoldButton(
                label: '${'teenpatti.show'.tr()} $baseBet',
                icon: Icons.visibility_rounded,
                height: h,
                padding: pad,
                minWidth: 112,
                isEnabled: isMyTurn,
                onPressed: onShow,
              )
            else
              GoldButton(
                label: '${'teenpatti.chaal'.tr()} $baseBet',
                height: h,
                padding: pad,
                minWidth: 112,
                isEnabled: canBet,
                onPressed: () => onChaal(baseBet),
              ),
          ],
        ),
      ],
    ).animate(target: isMyTurn ? 1 : 0).scaleXY(begin: 0.98, end: 1, duration: 200.ms);
  }
}
