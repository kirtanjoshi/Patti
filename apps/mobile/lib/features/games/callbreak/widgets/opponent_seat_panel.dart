import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/dhaka_pattern_painter.dart';
import '../../../../core/widgets/player_seat.dart';

/// Opponent Seat Widget for Callbreak table.
/// Combines the 52px circular PlayerSeat (avatar, turn-ring, bot badge, dealer chip, bid/tricks pill)
/// with a mini Dhaka card-back badge indicating remaining cards in hand.
class OpponentSeatPanel extends StatelessWidget {
  final String displayName;
  final int? bid;
  final int tricksWon;
  final int cardCount;
  final bool isCurrentTurn;
  final bool isDealer;
  final bool isBot;

  const OpponentSeatPanel({
    super.key,
    required this.displayName,
    this.bid,
    required this.tricksWon,
    this.cardCount = 13,
    this.isCurrentTurn = false,
    this.isDealer = false,
    this.isBot = true,
  });

  @override
  Widget build(BuildContext context) {
    final infoText = bid != null ? 'Bid $bid · Won $tricksWon' : 'Won $tricksWon';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Circular 52px PlayerSeat
            PlayerSeat(
              displayName: displayName,
              isCurrentTurn: isCurrentTurn,
              isDealer: isDealer,
              isBot: isBot,
              infoPillText: infoText,
              remainingSeconds: isCurrentTurn ? 12 : 15,
            ),

            // Mini Dhaka Card-Back with Remaining Cards Badge
            Positioned(
              top: 0,
              right: -14,
              child: Container(
                width: 22,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: PatiiColors.gold.withValues(alpha: 0.8),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 4,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2.5),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Dhaka pattern
                      Positioned.fill(
                        child: CustomPaint(
                          painter: DhakaPatternPainter(
                            primaryColor: PatiiColors.gold,
                            secondaryColor: PatiiColors.crimson,
                          ),
                        ),
                      ),
                      // Card count pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: PatiiColors.navy.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          '$cardCount',
                          style: PatiiTypography.cinzel(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: PatiiColors.goldLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
