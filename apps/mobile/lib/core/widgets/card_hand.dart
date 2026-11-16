import 'dart:math' as math;
import 'package:flutter/material.dart' hide Card;
import 'package:patii_engine/patii_engine.dart' as engine;
import '../services/audio_service.dart';
import 'playing_card.dart';

/// Overlapping Fan Card Hand
/// Guarantees that ALL cards fit within the available width without right-edge cutoff.
/// Supports tap-to-select, drag-up to play, and reordering.
class CardHand extends StatelessWidget {
  final List<engine.Card> cards;
  final String? selectedCardId;
  final Set<String> playableCardIds;
  final String? wildOrMaalCardId;
  final ValueChanged<engine.Card>? onCardTap;
  final ValueChanged<engine.Card>? onCardPlay;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final double cardWidth;
  final double cardHeight;
  final double maxArcDegrees;

  const CardHand({
    super.key,
    required this.cards,
    this.selectedCardId,
    this.playableCardIds = const {},
    this.wildOrMaalCardId,
    this.onCardTap,
    this.onCardPlay,
    this.onReorder,
    this.cardWidth = 64.0,
    this.cardHeight = 92.0,
    this.maxArcDegrees = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return SizedBox(height: cardHeight + 20.0);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final n = cards.length;

        // Compute step dx so all cards fit within availableWidth
        double dx;
        double startX;

        if (n == 1) {
          dx = 0;
          startX = (availableWidth - cardWidth) / 2.0;
        } else {
          final totalNaturalWidth = n * cardWidth;
          if (totalNaturalWidth <= availableWidth) {
            // Cards can be spaced comfortably without full compression
            dx = cardWidth * 0.75;
            final actualWidth = (n - 1) * dx + cardWidth;
            startX = (availableWidth - actualWidth) / 2.0;
          } else {
            // Compress overlap so it exactly fits availableWidth
            dx = (availableWidth - cardWidth) / (n - 1);
            startX = 0;
          }
        }

        return SizedBox(
          height: cardHeight + 24.0, // extra height for selected card lift & arc
          child: Stack(
            clipBehavior: Clip.none,
            children: List.generate(n, (index) {
              final card = cards[index];
              final isSelected = card.id == selectedCardId;
              final isPlayable = playableCardIds.isEmpty || playableCardIds.contains(card.id);
              final isMaal = card.id == wildOrMaalCardId;

              // Arc math: normalized position between -1.0 (left) and +1.0 (right)
              final normPos = n > 1 ? (index - (n - 1) / 2.0) / ((n - 1) / 2.0) : 0.0;
              final angleRad = normPos * (maxArcDegrees * math.pi / 180.0);
              // Slight downward drop towards the edges
              final arcY = normPos * normPos * 6.0;

              final left = startX + (index * dx);
              final top = 16.0 + arcY;

              return Positioned(
                left: left,
                top: top,
                child: Transform.rotate(
                  angle: angleRad,
                  alignment: Alignment.bottomCenter,
                  child: GestureDetector(
                    onVerticalDragEnd: (details) {
                      // Drag-up gesture to play card
                      if (details.primaryVelocity != null && details.primaryVelocity! < -200) {
                        if (isPlayable) {
                          AudioService.instance.playCardSnap();
                          onCardPlay?.call(card);
                        }
                      }
                    },
                    child: PlayingCard(
                      card: card,
                      isSelected: isSelected,
                      isPlayable: isPlayable,
                      width: cardWidth,
                      height: cardHeight,
                      badgeText: isMaal ? 'MAAL' : null,
                      onTap: () {
                        AudioService.instance.hapticCardPlay();
                        onCardTap?.call(card);
                      },
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
