import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/glass_sheet.dart';

/// Casino-Style Action Bar for Teen Patti (Landscape).
/// Houses Pack (Danger crimson), Side Show (Ghost outline), Chaal / Show (Gold CTA),
/// and Raise (+) actions with live stakes and turn gating.
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
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Blind limit warning if active
          if (isBlindLimitReached && !isSeen && isMyTurn)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                'teenpatti.blind_limit_reached'.tr(),
                style: PatiiTypography.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: PatiiColors.warning,
                ),
              ),
            ),

          // Main Action Buttons Row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Pack Button (Nepali Crimson)
              Flexible(
                child: DangerButton(
                  label: 'teenpatti.pack'.tr(),
                  icon: Icons.close,
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                  isEnabled: isMyTurn,
                  onPressed: onPack,
                ),
              ),
              const SizedBox(width: 8),

              // 2. Side Show Button (Gold Outlined Ghost)
              Flexible(
                child: GhostButton(
                  label: 'teenpatti.sideshow'.tr(),
                  icon: Icons.compare_arrows,
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                  isEnabled: isMyTurn && canSideShow,
                  onPressed: onSideShow,
                ),
              ),
              const SizedBox(width: 8),

              // 3. Chaal OR Show Button (Gold CTA)
              if (canShow)
                Flexible(
                  child: GoldButton(
                    label: '${'teenpatti.show'.tr()} $baseBet',
                    icon: Icons.visibility,
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                    isEnabled: isMyTurn,
                    onPressed: onShow,
                  ),
                )
              else
                Flexible(
                  child: GoldButton(
                    label: '${'teenpatti.chaal'.tr()} $baseBet',
                    icon: Icons.flash_on,
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                    isEnabled: isMyTurn && (!isBlindLimitReached || isSeen),
                    onPressed: () => onChaal(baseBet),
                  ),
                ),
              const SizedBox(width: 8),

              // 4. Raise (+) Button
              if (!canShow)
                Flexible(
                  child: GoldButton(
                    label: '+$raiseBet',
                    icon: Icons.arrow_upward,
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                    isEnabled: isMyTurn && (!isBlindLimitReached || isSeen),
                    onPressed: () => onChaal(raiseBet),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
