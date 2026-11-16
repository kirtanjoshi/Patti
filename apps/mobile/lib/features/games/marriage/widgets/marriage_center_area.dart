import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:patii_engine/patii_engine.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/playing_card.dart';
import '../marriage_models.dart';

/// Center Table Area for Marriage (Landscape).
/// Houses the Stock pile (face-down with card count),
/// Discard pile (top card face up, tap to draw),
/// and the Cut Joker / Maal card (face down until seen).
class MarriageCenterArea extends StatelessWidget {
  final bool isMaalSeen;
  final Card cutJoker;
  final List<Card> stockPile;
  final List<Card> discardPile;
  final bool canDraw;
  final VoidCallback onDrawStock;
  final VoidCallback onDrawDiscard;

  const MarriageCenterArea({
    super.key,
    required this.isMaalSeen,
    required this.cutJoker,
    required this.stockPile,
    required this.discardPile,
    required this.canDraw,
    required this.onDrawStock,
    required this.onDrawDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final specialInfo = SpecialCardsInfo.fromMaal(cutJoker);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Table Cards Row: Stock | Discard | Cut Joker (Maal)
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Stock Pile (Face Down)
            GestureDetector(
              onTap: canDraw ? onDrawStock : null,
              child: Semantics(
                button: true,
                label: '${'table.stock'.tr()}, ${stockPile.length} cards',
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    PlayingCard.table(
                      card: const Card(suit: Suit.S, rank: 1, deck: 0, id: 'stock_back'),
                      isFaceDown: true,
                      width: 46,
                      height: 66,
                    ),
                    Positioned(
                      bottom: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: PatiiColors.navy.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: PatiiColors.gold.withValues(alpha: 0.6),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '${stockPile.length}',
                          style: PatiiTypography.cinzel(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: PatiiColors.goldLight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),

            // 2. Discard Pile (Top card face up)
            GestureDetector(
              onTap: canDraw && discardPile.isNotEmpty ? onDrawDiscard : null,
              child: Semantics(
                button: true,
                label: 'table.discard_pile'.tr(),
                child: discardPile.isEmpty
                    ? Container(
                        width: 46,
                        height: 66,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1.0,
                          ),
                          color: Colors.black.withValues(alpha: 0.15),
                        ),
                        child: Center(
                          child: Text(
                            'table.discard_pile'.tr(),
                            style: PatiiTypography.caption(
                              color: Colors.white38,
                            ).copyWith(fontSize: 8),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : PlayingCard.table(
                        card: discardPile.last,
                        width: 46,
                        height: 66,
                      ),
              ),
            ),
            const SizedBox(width: 14),

            // 3. Cut Joker (Maal) Card
            Semantics(
              label: isMaalSeen ? 'Cut Joker: ${cutJoker.id}' : 'Hidden Cut Joker',
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  PlayingCard.table(
                    card: cutJoker,
                    isFaceDown: !isMaalSeen,
                    badgeText: isMaalSeen ? 'MAAL' : null,
                    width: 46,
                    height: 66,
                  ),
                  Positioned(
                    bottom: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        gradient: isMaalSeen
                            ? PatiiColors.goldButtonGradient
                            : null,
                        color: isMaalSeen
                            ? null
                            : PatiiColors.navy.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: PatiiColors.goldDark,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        isMaalSeen ? 'TIPLU' : 'MAAL',
                        style: PatiiTypography.cinzel(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isMaalSeen
                              ? PatiiColors.navy
                              : PatiiColors.goldLight,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Special Cards Pill Row (Visible when Maal is Seen)
        if (isMaalSeen) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: PatiiColors.navySurface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: PatiiColors.goldDark.withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSpecialMini('P', specialInfo.poplu),
                const SizedBox(width: 6),
                _buildSpecialMini('J', specialInfo.jhiplu),
                const SizedBox(width: 6),
                _buildSpecialMini('A', specialInfo.alter),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSpecialMini(String tag, Card card) {
    final isRed = card.suit == Suit.H || card.suit == Suit.D;
    final color = isRed ? PatiiColors.suitRed : Colors.white;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$tag: ',
          style: PatiiTypography.caption(color: PatiiColors.goldLight)
              .copyWith(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        Text(
          '${card.rank}${card.suit.name}',
          style: PatiiTypography.caption(color: color)
              .copyWith(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
