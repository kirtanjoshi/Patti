import 'dart:math' as math;
import 'package:flutter/material.dart' hide Card;
import 'package:patii_engine/patii_engine.dart' as engine;
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'dhaka_pattern_painter.dart';

enum CardSizeVariant {
  hand,  // 64 x 92
  table, // 52 x 74
  mini,  // 40 x 58
}

/// Premium Casino Playing Card Widget
/// Meets exact specs from PRD Section 10 & redesign instructions.
class PlayingCard extends StatelessWidget {
  final engine.Card card;
  final bool isFaceDown;
  final bool isSelected;
  final bool isPlayable;
  final String? badgeText;
  final double? width;
  final double? height;
  final CardSizeVariant sizeVariant;
  final VoidCallback? onTap;

  const PlayingCard({
    super.key,
    required this.card,
    this.isFaceDown = false,
    this.isSelected = false,
    this.isPlayable = true,
    this.badgeText,
    this.width,
    this.height,
    this.sizeVariant = CardSizeVariant.hand,
    this.onTap,
  });

  const PlayingCard.table({
    super.key,
    required this.card,
    this.isFaceDown = false,
    this.isSelected = false,
    this.isPlayable = true,
    this.badgeText,
    this.width,
    this.height,
    this.onTap,
  }) : sizeVariant = CardSizeVariant.table;

  double get resolvedWidth {
    if (width != null) return width!;
    switch (sizeVariant) {
      case CardSizeVariant.hand:
        return 64.0;
      case CardSizeVariant.table:
        return 52.0;
      case CardSizeVariant.mini:
        return 40.0;
    }
  }

  double get resolvedHeight {
    if (height != null) return height!;
    switch (sizeVariant) {
      case CardSizeVariant.hand:
        return 92.0;
      case CardSizeVariant.table:
        return 74.0;
      case CardSizeVariant.mini:
        return 58.0;
    }
  }

  bool get isRed =>
      card.suit == engine.Suit.H || card.suit == engine.Suit.D;

  Color get suitColor => isRed ? PatiiColors.suitRed : PatiiColors.suitBlack;

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
        return 'JOKER';
      default:
        return '${card.rank}';
    }
  }

  String get suitSymbol {
    switch (card.suit) {
      case engine.Suit.S:
        return '♠';
      case engine.Suit.H:
        return '♥';
      case engine.Suit.D:
        return '♦';
      case engine.Suit.C:
        return '♣';
      case engine.Suit.X:
        return '★';
    }
  }

  bool get isCourtCard =>
      card.rank == 11 || card.rank == 12 || card.rank == 13;

  @override
  Widget build(BuildContext context) {
    final w = resolvedWidth;
    final h = resolvedHeight;

    // Accessibility Semantics
    final semanticsLabel = isFaceDown
        ? 'Face-down card'
        : '$rankLabel of ${card.suit.name}${badgeText != null ? ', $badgeText' : ''}';

    return Semantics(
      label: semanticsLabel,
      button: onTap != null,
      selected: isSelected,
      child: GestureDetector(
        onTap: isPlayable ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(
            0,
            isSelected ? -16.0 : 0.0,
            0,
          ),
          width: w,
          height: h,
          decoration: BoxDecoration(
            borderRadius: PatiiSpacing.rounded8,
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: PatiiColors.gold.withValues(alpha: 0.65),
                  blurRadius: 14.0,
                  spreadRadius: 2.0,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 6.0,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: PatiiSpacing.rounded8,
            child: Stack(
              children: [
                // Card Surface (Face or Back)
                Positioned.fill(
                  child: isFaceDown ? _buildCardBack(w, h) : _buildCardFace(w, h),
                ),

                // Not Playable State: 40% darken overlay (not grey, keeps vibrancy)
                if (!isPlayable && !isFaceDown)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.40),
                    ),
                  ),

                // Selected Outline
                if (isSelected)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: PatiiSpacing.rounded8,
                        border: Border.all(
                          color: PatiiColors.goldLight,
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),

                // Wild / Maal / Trick Badge
                if (badgeText != null)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                      decoration: BoxDecoration(
                        gradient: PatiiColors.goldButtonGradient,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: Text(
                        badgeText!,
                        style: PatiiTypography.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: PatiiColors.navy,
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

  Widget _buildCardBack(double w, double h) {
    return Container(
      decoration: BoxDecoration(
        color: PatiiColors.navy,
        border: Border.all(color: PatiiColors.gold, width: 1.5),
        borderRadius: PatiiSpacing.rounded8,
      ),
      child: Padding(
        padding: const EdgeInsets.all(3.0),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: PatiiColors.goldDark, width: 0.75),
            borderRadius: BorderRadius.circular(5.0),
          ),
          child: CustomPaint(
            painter: const DhakaPatternPainter(),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }

  Widget _buildCardFace(double w, double h) {
    final scale = w / 64.0;
    final cornerFontSize = (12.0 * scale).clamp(9.0, 14.0);
    final suitFontSize = (10.0 * scale).clamp(8.0, 13.0);

    return Container(
      decoration: BoxDecoration(
        color: PatiiColors.cardFace,
        border: Border.all(color: PatiiColors.cardBorder, width: 0.8),
        borderRadius: PatiiSpacing.rounded8,
      ),
      child: Stack(
        children: [
          // Top-Left Rank & Pip
          Positioned(
            top: 3 * scale,
            left: 4 * scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  rankLabel,
                  style: PatiiTypography.cardRank.copyWith(
                    color: suitColor,
                    fontSize: cornerFontSize,
                    height: 1.0,
                  ),
                ),
                Text(
                  suitSymbol,
                  style: TextStyle(
                    color: suitColor,
                    fontSize: suitFontSize,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),

          // Center Card Artwork / Pip
          Center(
            child: isCourtCard
                ? _buildCourtPanel(scale)
                : Text(
                    suitSymbol,
                    style: TextStyle(
                      color: suitColor,
                      fontSize: (26.0 * scale).clamp(16.0, 32.0),
                    ),
                  ),
          ),

          // Bottom-Right Inverted Rank & Pip
          Positioned(
            bottom: 3 * scale,
            right: 4 * scale,
            child: Transform.rotate(
              angle: math.pi,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    rankLabel,
                    style: PatiiTypography.cardRank.copyWith(
                      color: suitColor,
                      fontSize: cornerFontSize,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    suitSymbol,
                    style: TextStyle(
                      color: suitColor,
                      fontSize: suitFontSize,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourtPanel(double scale) {
    return Container(
      width: 28 * scale,
      height: 38 * scale,
      decoration: BoxDecoration(
        color: PatiiColors.cardCourtBg,
        borderRadius: BorderRadius.circular(4 * scale),
        border: Border.all(color: PatiiColors.goldDark, width: 0.8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            rankLabel,
            style: PatiiTypography.cinzel(
              fontSize: 20 * scale,
              fontWeight: FontWeight.w900,
              color: suitColor,
            ),
          ),
          Positioned(
            bottom: 2 * scale,
            right: 2 * scale,
            child: Text(
              suitSymbol,
              style: TextStyle(
                color: suitColor,
                fontSize: 10 * scale,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
