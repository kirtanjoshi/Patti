import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:patii_engine/patii_engine.dart';
import '../../table/widgets/playing_card_widget.dart';
import '../../table/widgets/seat_widget.dart';
import 'marriage_models.dart';

class MarriageTableCenter extends StatelessWidget {
  final int currentTurnSeat;
  final String turnPhase;
  final bool isMaalSeen;
  final Card cutJoker;
  final List<Card> stockPile;
  final List<Card> discardPile;
  final VoidCallback? onDrawStock;
  final VoidCallback? onDrawDiscard;
  final ValueChanged<Card>? onDiscardCard;

  const MarriageTableCenter({
    super.key,
    required this.currentTurnSeat,
    required this.turnPhase,
    required this.isMaalSeen,
    required this.cutJoker,
    required this.stockPile,
    required this.discardPile,
    this.onDrawStock,
    this.onDrawDiscard,
    this.onDiscardCard,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final specialInfo = SpecialCardsInfo.fromMaal(cutJoker);

    return Stack(
      children: [
        // Top Seat (Bot 2)
        Positioned(
          top: 8.0,
          left: 0,
          right: 0,
          child: Center(
            child: SeatWidget(
              displayName: 'Bot 2',
              isBot: true,
              isCurrentTurn: currentTurnSeat == 2,
              statusText: isMaalSeen
                  ? 'marriage.seen'.tr()
                  : 'marriage.unseen'.tr(),
            ),
          ),
        ),

        // Left Seat (Bot 1)
        Positioned(
          left: 16.0,
          top: 48.0,
          child: SeatWidget(
            displayName: 'Bot 1',
            isBot: true,
            isCurrentTurn: currentTurnSeat == 1,
            statusText: isMaalSeen
                ? 'marriage.seen'.tr()
                : 'marriage.unseen'.tr(),
          ),
        ),

        // Right Seat (Bot 3)
        Positioned(
          right: 16.0,
          top: 48.0,
          child: SeatWidget(
            displayName: 'Bot 3',
            isBot: true,
            isCurrentTurn: currentTurnSeat == 3,
            statusText: isMaalSeen
                ? 'marriage.seen'.tr()
                : 'marriage.unseen'.tr(),
          ),
        ),

        // Center Area: Stock, Discard, Cut Joker, and Special Cards
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Stock Pile
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'table.stock'.tr(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      PlayingCardWidget(
                        card: stockPile.isNotEmpty ? stockPile.last : cutJoker,
                        isFaceDown: true,
                        isLegal: currentTurnSeat == 0 && turnPhase == 'draw',
                        badgeText: '${stockPile.length}',
                        onTap: onDrawStock,
                      ),
                    ],
                  ),
                  const SizedBox(width: 16.0),

                  // Discard Pile
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'table.discard_pile'.tr(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      DragTarget<Card>(
                        onAcceptWithDetails: (details) =>
                            onDiscardCard?.call(details.data),
                        builder: (context, _, __) => PlayingCardWidget(
                          card: discardPile.isNotEmpty
                              ? discardPile.last
                              : cutJoker,
                          isLegal: currentTurnSeat == 0 && turnPhase == 'draw',
                          onTap: onDrawDiscard,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16.0),

                  // Cut Joker (Tiplu)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'marriage.tiplu'.tr(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      PlayingCardWidget(
                        card: cutJoker,
                        isFaceDown: !isMaalSeen,
                        badgeText: isMaalSeen
                            ? 'marriage.tiplu'.tr()
                            : 'table.maal_unseen'.tr(),
                      ),
                    ],
                  ),
                ],
              ),

              // When Maal is seen: Special Cards Row (Poplu, Jhiplu, Alter)
              if (isMaalSeen) ...[
                const SizedBox(height: 8.0),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 6.0,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${'marriage.special_cards'.tr()}: ',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4.0),
                      _buildMiniChip(
                        context,
                        specialInfo.poplu,
                        'marriage.poplu'.tr(),
                      ),
                      const SizedBox(width: 6.0),
                      _buildMiniChip(
                        context,
                        specialInfo.jhiplu,
                        'marriage.jhiplu'.tr(),
                      ),
                      const SizedBox(width: 6.0),
                      _buildMiniChip(
                        context,
                        specialInfo.alter,
                        'marriage.alter'.tr(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniChip(BuildContext context, Card card, String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isRed = card.suit == Suit.H || card.suit == Suit.D;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
          Text(
            '${_rankToString(card.rank)}${_suitToSymbol(card.suit)}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: isRed ? colorScheme.error : colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _rankToString(int rank) {
    switch (rank) {
      case 1:
        return 'A';
      case 11:
        return 'J';
      case 12:
        return 'Q';
      case 13:
        return 'K';
      default:
        return '$rank';
    }
  }

  String _suitToSymbol(Suit suit) {
    switch (suit) {
      case Suit.S:
        return '♠';
      case Suit.H:
        return '♥';
      case Suit.D:
        return '♦';
      case Suit.C:
        return '♣';
      case Suit.X:
        return '★';
    }
  }
}
