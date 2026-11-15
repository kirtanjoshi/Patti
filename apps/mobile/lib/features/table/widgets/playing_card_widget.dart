import 'package:flutter/material.dart' hide Card;
import 'package:patii_engine/patii_engine.dart';

class PlayingCardWidget extends StatelessWidget {
  final Card card;
  final bool isLegal;
  final bool isSelected;
  final VoidCallback? onTap;

  const PlayingCardWidget({
    super.key,
    required this.card,
    this.isLegal = true,
    this.isSelected = false,
    this.onTap,
  });

  String get rankLabel {
    switch (card.rank) {
      case 1:
        return 'A';
      case 11:
        return 'J';
      case 12:
        return 'Q';
      case 13:
        return 'K';
      case 0:
        return '★';
      default:
        return '${card.rank}';
    }
  }

  String get suitSymbol {
    switch (card.suit) {
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

  bool get isRed => card.suit == Suit.H || card.suit == Suit.D;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cardColor = isRed ? colorScheme.error : colorScheme.onSurface;

    return Semantics(
      label: '$rankLabel of ${card.suit.name}',
      button: isLegal,
      child: GestureDetector(
        onTap: isLegal ? onTap : null,
        child: AnimatedOpacity(
          opacity: isLegal ? 1.0 : 0.45,
          duration: const Duration(milliseconds: 200),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            transform: Matrix4.translationValues(0, isSelected ? -12 : 0, 0),
            width: 56.0,
            height: 84.0,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(
                color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(4.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    rankLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cardColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  suitSymbol,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: cardColor,
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    rankLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cardColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
