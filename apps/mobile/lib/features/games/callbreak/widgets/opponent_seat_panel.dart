import 'package:flutter/material.dart' hide Card;
import 'package:patii_engine/patii_engine.dart' as engine;
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/player_seat.dart';
import '../../../../core/widgets/playing_card.dart';

/// Opponent seat for Callbreak: the shared PlayerSeat plus a small fanned
/// stack of card backs showing how many cards they still hold.
class OpponentSeatPanel extends StatelessWidget {
  final String displayName;
  final int? bid;
  final int tricksWon;
  final int cardCount;
  final bool isCurrentTurn;
  final bool isDealer;
  final bool isBot;

  /// Put the card stack on the inner (left) side, for the east seat.
  final bool stackOnLeft;

  const OpponentSeatPanel({
    super.key,
    required this.displayName,
    this.bid,
    required this.tricksWon,
    this.cardCount = 13,
    this.isCurrentTurn = false,
    this.isDealer = false,
    this.isBot = true,
    this.stackOnLeft = false,
  });

  static const _back = engine.Card(suit: engine.Suit.S, rank: 2, deck: 0, id: 'back');

  @override
  Widget build(BuildContext context) {
    final infoText = bid != null ? '$tricksWon / $bid tricks' : '$tricksWon tricks';

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        PlayerSeat(
          displayName: displayName,
          isCurrentTurn: isCurrentTurn,
          isDealer: isDealer,
          isBot: isBot,
          infoPillText: infoText,
          remainingSeconds: isCurrentTurn ? 12 : 15,
        ),
        if (cardCount > 0)
          Positioned(
            top: 6,
            right: stackOnLeft ? null : -22,
            left: stackOnLeft ? -22 : null,
            child: Semantics(
              label: '$cardCount cards',
              child: SizedBox(
                width: 30,
                height: 30,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Positioned(
                        left: i * 4.0,
                        top: i * -1.0,
                        child: Transform.rotate(
                          angle: (i - 1) * 0.12,
                          child: const PlayingCard(card: _back, isFaceDown: true, width: 18, height: 26),
                        ),
                      ),
                    Positioned(
                      right: -2,
                      bottom: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
                        decoration: BoxDecoration(
                          color: PatiiColors.navy,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: PatiiColors.hairlineStrong, width: 0.8),
                        ),
                        child: Text(
                          '$cardCount',
                          style: PatiiTypography.display(fontSize: 9.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
