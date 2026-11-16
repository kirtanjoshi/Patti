import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:patii_engine/patii_engine.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/glass_sheet.dart';
import '../../../../core/widgets/playing_card.dart';
import 'kitti_models.dart';

/// Casino-Style Kitti Reveal Board.
/// Reveals the 3 shows compared across all players, highlighting the winner,
/// any Salami bonus, or Kitti carryover.
class KittiRevealBoard extends StatefulWidget {
  final List<KittiPlayer> players;
  final KittiRoundSummary summary;
  final VoidCallback onNextDeal;

  const KittiRevealBoard({
    super.key,
    required this.players,
    required this.summary,
    required this.onNextDeal,
  });

  @override
  State<KittiRevealBoard> createState() => _KittiRevealBoardState();
}

class _KittiRevealBoardState extends State<KittiRevealBoard> {
  int _activeShowIndex = 0; // 0, 1, 2 for Show 1, 2, 3

  String _showLabel(int index) {
    switch (index) {
      case 0:
        return 'kitti.show_1'.tr();
      case 1:
        return 'kitti.show_2'.tr();
      case 2:
      default:
        return 'kitti.show_3'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final showResult = widget.summary.showResults.length > _activeShowIndex
        ? widget.summary.showResults[_activeShowIndex]
        : null;

    final winnerSeat = showResult?.winnerSeat;
    final winningPlayer = winnerSeat != null
        ? widget.players.firstWhere((p) => p.seatIndex == winnerSeat)
        : null;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Salami or Kitti Carryover Banner
          if (widget.summary.isSalami)
            _buildCelebrationBanner(
              icon: Icons.auto_awesome,
              title: 'kitti.salami_bonus'.tr(),
              subtitle: 'kitti.salami_desc'.tr(),
              color: PatiiColors.gold,
            )
          else if (widget.summary.isKittiCarryover)
            _buildCelebrationBanner(
              icon: Icons.sync,
              title: 'kitti.kitti_carryover'.tr(),
              subtitle: 'kitti.kitti_desc'.tr(),
              color: PatiiColors.warning,
            ),

          const SizedBox(height: 6.0),

          // Show selector tabs (1st Show, 2nd Show, 3rd Show)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final isSelected = _activeShowIndex == index;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Semantics(
                  button: true,
                  label: _showLabel(index),
                  child: GestureDetector(
                    onTap: () => setState(() => _activeShowIndex = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? PatiiColors.gold
                            : PatiiColors.navySurface.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: isSelected
                              ? PatiiColors.goldLight
                              : PatiiColors.goldDark.withValues(alpha: 0.35),
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        _showLabel(index),
                        style: PatiiTypography.cinzel(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? PatiiColors.navy : PatiiColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 6.0),

          // Show Outcome Header
          GlassPanel(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  showResult?.isVoid == true ? Icons.handshake : Icons.emoji_events,
                  size: 18,
                  color: PatiiColors.gold,
                ),
                const SizedBox(width: 8.0),
                Text(
                  showResult?.isVoid == true
                      ? 'kitti.show_void'.tr()
                      : (winningPlayer != null
                          ? 'kitti.show_winner'.tr(args: [winningPlayer.displayName])
                          : ''),
                  style: PatiiTypography.cinzel(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: PatiiColors.goldLight,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6.0),

          // Player Shows Grid for the active show
          ...widget.players.where((p) => !p.isFolded).map((player) {
            final isThisWinner = winnerSeat == player.seatIndex;
            final evaluation = showResult?.handEvaluations[player.seatIndex];
            final handCards = player.arrangedHands != null &&
                    player.arrangedHands!.length > _activeShowIndex
                ? player.arrangedHands![_activeShowIndex]
                : <Card>[];

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.0),
              child: GlassPanel(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                customBorder: Border.all(
                  color: isThisWinner
                      ? PatiiColors.gold
                      : Colors.white.withValues(alpha: 0.08),
                  width: isThisWinner ? 1.5 : 1.0,
                ),
                child: Row(
                  children: [
                    // Player info
                    SizedBox(
                      width: 80.0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            player.displayName,
                            style: PatiiTypography.poppins(
                              fontSize: 12,
                              fontWeight: isThisWinner ? FontWeight.bold : FontWeight.w500,
                              color: isThisWinner ? PatiiColors.goldLight : PatiiColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (evaluation != null)
                            Text(
                              evaluation.labelKey.tr(),
                              style: PatiiTypography.caption(
                                color: isThisWinner ? PatiiColors.success : PatiiColors.textMuted,
                                bold: isThisWinner,
                              ).copyWith(fontSize: 9),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8.0),

                    // Cards in this show
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: handCards.map((card) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: PlayingCard.table(
                              card: card,
                              width: 32.0,
                              height: 46.0,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 10.0),

          // Next Deal Button
          GoldButton(
            label: 'kitti.next_deal'.tr(),
            icon: Icons.play_arrow_rounded,
            height: 42,
            onPressed: widget.onNextDeal,
          ),
        ],
      ),
    );
  }

  Widget _buildCelebrationBanner({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: PatiiTypography.cinzel(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: PatiiTypography.caption(color: PatiiColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
