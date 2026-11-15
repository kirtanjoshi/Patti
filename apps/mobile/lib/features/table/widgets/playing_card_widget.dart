import 'package:flutter/material.dart' hide Card;
import 'package:patii_engine/patii_engine.dart';

class PlayingCardWidget extends StatelessWidget {
  final Card card;
  final bool isLegal;
  final bool isSelected;
  final bool isFaceDown;
  final String? badgeText;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const PlayingCardWidget({
    super.key,
    required this.card,
    this.isLegal = true,
    this.isSelected = false,
    this.isFaceDown = false,
    this.badgeText,
    this.width = 56.0,
    this.height = 84.0,
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
      label: isFaceDown ? 'Hidden card' : '$rankLabel of ${card.suit.name}',
      button: isLegal,
      child: GestureDetector(
        onTap: isLegal ? onTap : null,
        child: AnimatedOpacity(
          opacity: isLegal ? 1.0 : 0.45,
          duration: const Duration(milliseconds: 200),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            transform: Matrix4.translationValues(0, isSelected ? -12 : 0, 0),
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: isFaceDown ? colorScheme.secondary : colorScheme.surface,
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(
                color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(4.0),
            child: isFaceDown
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.grid_view_rounded,
                          size: 20,
                          color: colorScheme.onSecondary.withValues(alpha: 0.7),
                        ),
                        if (badgeText != null) ...[
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badgeText!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onPrimary,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      Column(
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
                      if (badgeText != null)
                        Positioned(
                          bottom: 2,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                badgeText!,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
