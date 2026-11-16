import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/coin_counter.dart';

/// Top HUD bar for the Casino Lobby.
/// Displays Player Avatar + VIP Badge, Username, CoinCounter pill with "+" CTA,
/// and a quick settings / component gallery action button.
class LobbyTopBar extends StatelessWidget {
  final int coins;
  final int vipLevel;
  final String username;
  final VoidCallback onAddCoins;
  final VoidCallback onOpenGallery;

  const LobbyTopBar({
    super.key,
    required this.coins,
    this.vipLevel = 3,
    this.username = 'Player 1',
    required this.onAddCoins,
    required this.onOpenGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: PatiiSpacing.s16,
        vertical: PatiiSpacing.s4,
      ),
      child: Row(
        children: [
          // Player Avatar with Level/VIP Badge
          Semantics(
            label: '$username, VIP level $vipLevel',
            button: true,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [PatiiColors.navyElevated, PatiiColors.navySurface],
                    ),
                    border: Border.all(
                      color: PatiiColors.gold,
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: PatiiColors.gold.withValues(alpha: 0.25),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person_outline,
                      color: PatiiColors.goldLight,
                      size: 26,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [PatiiColors.crimson, PatiiColors.goldDark],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: PatiiColors.goldLight, width: 0.8),
                    ),
                    child: Text(
                      'lobby.vip_level'.tr(args: [vipLevel.toString()]),
                      style: PatiiTypography.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: PatiiColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: PatiiSpacing.s8),

          // User info text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  username,
                  style: PatiiTypography.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: PatiiColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'lobby.title'.tr(),
                  style: PatiiTypography.poppins(
                    fontSize: 11,
                    color: PatiiColors.goldLight,
                  ),
                ),
              ],
            ),
          ),

          // Luxury Coin Counter Capsule with "+" CTA
          CoinCounter(
            coins: coins,
            showPlusButton: true,
            onPlusTap: onAddCoins,
          ),
          const SizedBox(width: PatiiSpacing.s4),

          // Quick Dev Gallery / Settings Button (min 48x48 tap target)
          Semantics(
            button: true,
            label: 'lobby.dev_gallery'.tr(),
            child: SizedBox(
              width: PatiiSpacing.minTouchTarget,
              height: PatiiSpacing.minTouchTarget,
              child: IconButton(
                tooltip: 'lobby.dev_gallery'.tr(),
                icon: const Icon(
                  Icons.palette_outlined,
                  color: PatiiColors.gold,
                  size: 22,
                ),
                onPressed: onOpenGallery,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
