import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:patii_engine/patii_engine.dart' as engine;
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/playing_card.dart';

/// Data class representing a played card in a Callbreak trick.
class PlayedTrickCard {
  final int seat;
  final engine.Card card;

  const PlayedTrickCard({
    required this.seat,
    required this.card,
  });
}

/// Callbreak Center Trick Area
/// Arranges up to 4 played cards in a diamond layout, where each card sits
/// slightly toward the player who played it:
/// - Seat 0 (South / You): sits towards bottom
/// - Seat 1 (West / Left): sits towards left
/// - Seat 2 (North / Top): sits towards top
/// - Seat 3 (East / Right): sits towards right
///
/// Features smooth dealing arrival and collection animation toward the trick winner.
class CallbreakTrickArea extends StatelessWidget {
  final List<PlayedTrickCard> playedCards;
  final String phase;
  final int currentTurnSeat;
  final int? winningSeat;

  const CallbreakTrickArea({
    super.key,
    required this.playedCards,
    required this.phase,
    required this.currentTurnSeat,
    this.winningSeat,
  });

  Offset _getCardOffset(int seat) {
    switch (seat) {
      case 0: // South (You)
        return const Offset(0, 20);
      case 1: // West (Left)
        return const Offset(-30, 0);
      case 2: // North (Top)
        return const Offset(0, -20);
      case 3: // East (Right)
        return const Offset(30, 0);
      default:
        return Offset.zero;
    }
  }

  double _getCardRotation(int seat) {
    switch (seat) {
      case 0:
        return 0.0;
      case 1:
        return -0.08;
      case 2:
        return 0.05;
      case 3:
        return 0.08;
      default:
        return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 190,
        height: 150,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Center Felt Diamond Subtle Watermark
            Container(
              width: 140,
              height: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: PatiiColors.gold.withValues(alpha: 0.12),
                  width: 1.0,
                ),
                color: Colors.black.withValues(alpha: 0.10),
              ),
            ),

            // Empty State Hint
            if (playedCards.isEmpty)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: PatiiColors.navySurface.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: PatiiColors.gold.withValues(alpha: 0.2),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    phase == 'bidding'
                        ? 'callbreak.bid'.tr()
                        : currentTurnSeat == 0
                            ? 'table.your_turn'.tr()
                            : 'table.waiting'.tr(),
                    style: PatiiTypography.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: PatiiColors.goldLight.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),

            // Played Cards in Diamond Layout
            ...playedCards.map((played) {
              final offset = _getCardOffset(played.seat);
              final rotation = _getCardRotation(played.seat);

              return Transform.translate(
                offset: offset,
                child: Transform.rotate(
                  angle: rotation,
                  child: PlayingCard.table(
                    card: played.card,
                    width: 48,
                    height: 68,
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0.7, 0.7),
                        end: const Offset(1.0, 1.0),
                        duration: 180.ms,
                        curve: Curves.easeOutBack,
                      )
                      .fadeIn(duration: 120.ms),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
