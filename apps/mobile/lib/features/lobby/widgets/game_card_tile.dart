import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';

/// Data model representing a playable game option in the casino lobby.
class GameOption {
  final String id;
  final String titleKey;
  final int onlineCount;
  final String? badgeKey;
  final List<String> fannedCardSuits;
  final List<String> fannedCardRanks;
  final VoidCallback onTap;

  const GameOption({
    required this.id,
    required this.titleKey,
    required this.onlineCount,
    this.badgeKey,
    required this.fannedCardSuits,
    required this.fannedCardRanks,
    required this.onTap,
  });
}

/// An illustrated casino game tile with a 3-card fanned motif, Cinzel title,
/// online player count pill, and periodic shimmer sweep.
class GameCardTile extends StatelessWidget {
  final GameOption option;
  final int animationDelayMs;

  const GameCardTile({
    super.key,
    required this.option,
    this.animationDelayMs = 0,
  });

  @override
  Widget build(BuildContext context) {
    final formattedOnline = NumberFormat('#,###').format(option.onlineCount);

    return Semantics(
      button: true,
      label: '${option.titleKey.tr()}, $formattedOnline online',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: option.onTap,
          borderRadius: PatiiSpacing.rounded12,
          splashColor: PatiiColors.gold.withValues(alpha: 0.2),
          highlightColor: PatiiColors.goldLight.withValues(alpha: 0.1),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: PatiiSpacing.rounded12,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  PatiiColors.navyElevated,
                  PatiiColors.navySurface,
                ],
              ),
              border: Border.all(
                color: PatiiColors.gold.withValues(alpha: 0.22),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: PatiiSpacing.rounded12,
              child: Stack(
                children: [
                  // Subtle felt-tinted corner glow
                  Positioned(
                    top: -24,
                    right: -24,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: PatiiColors.feltGreen.withValues(alpha: 0.15),
                      ),
                    ),
                  ),

                  // Content Layout
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: PatiiSpacing.s8,
                      vertical: PatiiSpacing.s8,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Top row: Illustrated Fanned Cards Motif
                        Expanded(
                          child: Center(
                            child: _FannedCardsMotif(
                              suits: option.fannedCardSuits,
                              ranks: option.fannedCardRanks,
                            ),
                          ),
                        ),
                        const SizedBox(height: PatiiSpacing.s4),

                        // Title in Cinzel font
                        Text(
                          option.titleKey.tr(),
                          style: PatiiTypography.cinzel(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: PatiiColors.textPrimary,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),

                        // Online players count pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: PatiiColors.navy.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: PatiiColors.goldDark.withValues(alpha: 0.35),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: PatiiColors.success,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'lobby.online_count'.tr(args: [formattedOnline]),
                                  style: PatiiTypography.poppins(
                                    fontSize: 10.5,
                                    color: PatiiColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Optional Hot/Popular Badge at Top Right
                  if (option.badgeKey != null)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: option.badgeKey == 'lobby.hot'
                                ? [PatiiColors.crimson, const Color(0xFFE5484D)]
                                : [PatiiColors.goldLight, PatiiColors.goldDark],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: (option.badgeKey == 'lobby.hot'
                                      ? PatiiColors.crimson
                                      : PatiiColors.gold)
                                  .withValues(alpha: 0.4),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          option.badgeKey!.tr(),
                          style: PatiiTypography.poppins(
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            color: option.badgeKey == 'lobby.hot'
                                ? Colors.white
                                : PatiiColors.navy,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        // Periodic subtle shine sweep animation
        .animate(
          onPlay: (controller) => controller.repeat(
            period: const Duration(seconds: 4),
          ),
          delay: Duration(milliseconds: animationDelayMs),
        )
        .shimmer(
          duration: const Duration(milliseconds: 1100),
          color: PatiiColors.gold.withValues(alpha: 0.12),
        );
  }
}

/// Mini 3-card fanned illustration for game tiles
class _FannedCardsMotif extends StatelessWidget {
  final List<String> suits;
  final List<String> ranks;

  const _FannedCardsMotif({
    required this.suits,
    required this.ranks,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Left card (-16 deg)
          Positioned(
            left: 6,
            child: Transform.rotate(
              angle: -0.26,
              child: _MiniCard(
                rank: ranks.isNotEmpty ? ranks[0] : 'A',
                suit: suits.isNotEmpty ? suits[0] : '♠',
              ),
            ),
          ),
          // Right card (+16 deg)
          Positioned(
            right: 6,
            child: Transform.rotate(
              angle: 0.26,
              child: _MiniCard(
                rank: ranks.length > 2 ? ranks[2] : 'K',
                suit: suits.length > 2 ? suits[2] : '♦',
              ),
            ),
          ),
          // Center card (0 deg, elevated)
          Positioned(
            top: 2,
            child: _MiniCard(
              rank: ranks.length > 1 ? ranks[1] : 'Q',
              suit: suits.length > 1 ? suits[1] : '♥',
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String rank;
  final String suit;

  const _MiniCard({required this.rank, required this.suit});

  bool get _isRed => suit == '♥' || suit == '♦';

  @override
  Widget build(BuildContext context) {
    final color = _isRed ? PatiiColors.suitRed : PatiiColors.suitBlack;

    return Container(
      width: 26,
      height: 38,
      decoration: BoxDecoration(
        color: PatiiColors.cardFace,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.18),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            rank,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1.0,
            ),
          ),
          Text(
            suit,
            style: TextStyle(
              fontSize: 11,
              color: color,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
