import 'dart:math' as math;
import 'package:flutter/material.dart' hide Card;
import 'package:patii_engine/patii_engine.dart' as engine;
import '../services/audio_service.dart';
import 'playing_card.dart';

/// Overlapping fan of the player's cards.
///
/// - Always fits the available width (overlap compresses, never clips right).
/// - Cards are keyed by id: when one is played the rest glide closed instead
///   of snapping, and a freshly dealt hand fans in with a short stagger.
/// - Tap to select, flick up to play.
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
    this.cardHeight = 90.0,
    this.maxArcDegrees = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    final lift = cardHeight * 0.2;
    if (cards.isEmpty) {
      return SizedBox(height: cardHeight + lift);
    }
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final n = cards.length;

        double dx;
        double startX;
        if (n == 1) {
          dx = 0;
          startX = (availableWidth - cardWidth) / 2.0;
        } else {
          // Comfortable spacing shows the full corner index; compress if needed.
          final comfortable = cardWidth * 0.62;
          final fitting = (availableWidth - cardWidth) / (n - 1);
          dx = math.min(comfortable, fitting);
          final actualWidth = (n - 1) * dx + cardWidth;
          startX = (availableWidth - actualWidth) / 2.0;
        }

        // Arc strength scales with how spread the hand is.
        final arc = n > 1 ? maxArcDegrees * math.min(1.0, n / 8) : 0.0;

        return SizedBox(
          height: cardHeight + lift + 6,
          child: Stack(
            clipBehavior: Clip.none,
            children: List.generate(n, (index) {
              final card = cards[index];
              final isSelected = card.id == selectedCardId;
              final isPlayable = playableCardIds.isEmpty || playableCardIds.contains(card.id);
              final isMaal = card.id == wildOrMaalCardId;

              final normPos = n > 1 ? (index - (n - 1) / 2.0) / ((n - 1) / 2.0) : 0.0;
              final angleRad = normPos * (arc * math.pi / 180.0);
              final arcY = normPos * normPos * cardHeight * 0.07;

              Widget child = Transform.rotate(
                angle: angleRad,
                alignment: Alignment.bottomCenter,
                child: GestureDetector(
                  onVerticalDragEnd: (details) {
                    final v = details.primaryVelocity;
                    if (v != null && v < -200 && isPlayable) {
                      AudioService.instance.playCardSnap();
                      onCardPlay?.call(card);
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
              );

              if (!reduceMotion) {
                // Deal-in: plays once per card (keyed by id), staggered by
                // index via an Interval. TweenAnimationBuilder needs no timers.
                final total = 320 + 25 * index;
                final startAt = (25 * index) / total;
                final dealt = child;
                child = TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: total),
                  curve: Interval(startAt, 1, curve: Curves.easeOutCubic),
                  builder: (context, t, _) => Opacity(
                    opacity: (t * 2).clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, -cardHeight * 0.6 * (1 - t)),
                      child: Transform.scale(scale: 0.85 + 0.15 * t, child: dealt),
                    ),
                  ),
                );
              }

              return AnimatedPositioned(
                key: ValueKey(card.id),
                duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: startX + index * dx,
                top: lift + arcY,
                child: child,
              );
            }),
          ),
        );
      },
    );
  }
}
