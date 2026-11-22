import 'package:flutter/material.dart' hide Card;
import 'package:patii_engine/patii_engine.dart' as engine;
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'playing_card.dart';

/// Physical 3D Stacked Card Deck & Discard Pile representation.
///
/// Simulates physical card thickness on casino felt by rendering subtle,
/// layered card-edge offsets underneath the top card, complete with
/// paper-core edge shadows and realistic stepped bevels.
class StackedDeck extends StatelessWidget {
  final engine.Card? topCard;
  final bool isFaceDown;
  final int cardCount;
  final double width;
  final double height;
  final String? label;
  final bool isInteractive;
  final VoidCallback? onTap;
  final bool spreadDiscard;

  const StackedDeck({
    super.key,
    this.topCard,
    this.isFaceDown = true,
    this.cardCount = 1,
    this.width = 50.0,
    this.height = 72.0,
    this.label,
    this.isInteractive = false,
    this.onTap,
    this.spreadDiscard = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular((width * 0.11).clamp(4.0, 9.0));
    final hasCards = cardCount > 0 && topCard != null;

    if (!hasCards) {
      return _buildEmptySlot(radius);
    }

    // Determine visual stack depth (up to 4 edge steps for deep decks)
    final visualLayers = cardCount >= 25
        ? 4
        : cardCount >= 12
            ? 3
            : cardCount >= 4
                ? 2
                : cardCount > 1
                    ? 1
                    : 0;

    return Semantics(
      button: onTap != null,
      label: '${label ?? (isFaceDown ? "Stock Pile" : "Discard Pile")}, $cardCount cards',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: isInteractive ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: SizedBox(
            width: width + (visualLayers * 1.5) + (spreadDiscard ? 6.0 : 0.0),
            height: height + (visualLayers * 1.5) + 6.0,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // 1. Underlying physical card-edge layers (stepped thickness)
                if (visualLayers > 0)
                  ...List.generate(visualLayers, (i) {
                    final layerIndex = visualLayers - i;
                    final stepX = layerIndex * 1.2;
                    final stepY = layerIndex * 1.2;
                    final rot = spreadDiscard
                        ? (layerIndex == 1 ? -0.06 : 0.04)
                        : 0.0;

                    return Positioned(
                      left: stepX + (spreadDiscard ? (layerIndex == 1 ? -3.0 : 2.0) : 0),
                      top: stepY,
                      child: Transform.rotate(
                        angle: rot,
                        child: Container(
                          width: width,
                          height: height,
                          decoration: BoxDecoration(
                            color: isFaceDown
                                ? const Color(0xFF6A1220)
                                : const Color(0xFFEBE7DD),
                            borderRadius: radius,
                            border: Border.all(
                              color: isFaceDown
                                  ? const Color(0xFF3E0A12)
                                  : const Color(0xFFC8C4B8),
                              width: 0.6,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.16 + 0.05 * layerIndex),
                                blurRadius: 2.0 + layerIndex * 1.2,
                                offset: Offset(0.5, 1.0 + layerIndex * 0.8),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                // 2. Interactive Ambient Aura when turn/drawable
                if (isInteractive)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: width,
                      height: height,
                      decoration: BoxDecoration(
                        borderRadius: radius,
                        boxShadow: [
                          BoxShadow(
                            color: PatiiColors.gold.withValues(alpha: 0.40),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),

                // 3. Top Card
                Positioned(
                  top: 0,
                  left: 0,
                  child: PlayingCard.table(
                    card: topCard!,
                    isFaceDown: isFaceDown,
                    width: width,
                    height: height,
                    onTap: onTap,
                  ),
                ),

                // 4. Subtle Count / Label Pill
                if (label != null || cardCount > 1)
                  Positioned(
                    bottom: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: PatiiColors.navy.withValues(alpha: 0.90),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isInteractive
                              ? PatiiColors.goldLight
                              : PatiiColors.goldDark.withValues(alpha: 0.5),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        label != null ? '$label ($cardCount)' : '$cardCount',
                        style: PatiiTypography.display(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: isInteractive ? PatiiColors.goldLight : Colors.white,
                          letterSpacing: 0.3,
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

  Widget _buildEmptySlot(BorderRadius radius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
          width: 1.0,
          strokeAlign: BorderSide.strokeAlignCenter,
        ),
        color: Colors.black.withValues(alpha: 0.12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.style_outlined,
              size: width * 0.35,
              color: Colors.white.withValues(alpha: 0.22),
            ),
            if (label != null) ...[
              const SizedBox(height: 2),
              Text(
                label!,
                style: PatiiTypography.caption(
                  color: Colors.white.withValues(alpha: 0.30),
                  bold: true,
                ).copyWith(fontSize: 8.5),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
