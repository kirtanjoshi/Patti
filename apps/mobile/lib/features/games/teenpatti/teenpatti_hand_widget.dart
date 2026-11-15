import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:patii_engine/patii_engine.dart';
import '../../table/widgets/playing_card_widget.dart';
import 'teenpatti_evaluator.dart';

/// 3-Card hand display for Teen Patti with flip animation between Blind and Seen modes.
class TeenPattiHandWidget extends StatelessWidget {
  final List<Card> cards;
  final bool isSeen;
  final VoidCallback onToggleSeen;

  const TeenPattiHandWidget({
    super.key,
    required this.cards,
    required this.isSeen,
    required this.onToggleSeen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final handRank = isSeen ? TeenPattiEvaluator.evaluateRankName(cards) : '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hand rank badge or "See Cards" toggle button
        if (isSeen)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            margin: const EdgeInsets.only(bottom: 8.0),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.4),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.stars_rounded,
                  size: 16.0,
                  color: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8.0),
                Text(
                  handRank,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Semantics(
              button: true,
              label: 'teenpatti.see_cards'.tr(),
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(120.0, 48.0),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                ),
                onPressed: onToggleSeen,
                icon: const Icon(Icons.visibility_outlined, size: 18.0),
                label: Text(
                  'teenpatti.see_cards'.tr(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

        // 3 Cards Fan with 3D Flip animation
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
          tween: Tween<double>(begin: 0, end: isSeen ? math.pi : 0),
          builder: (context, angle, child) {
            final isFlipped = angle > (math.pi / 2);

            return Semantics(
              label: isSeen
                  ? 'teenpatti.cards_revealed'.tr()
                  : 'teenpatti.cards_hidden'.tr(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(cards.length, (index) {
                  final card = cards[index];
                  // Card fan slight rotation
                  final fanAngle = (index - 1) * 0.08;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateZ(fanAngle)
                        ..rotateY(angle),
                      child: isFlipped
                          ? Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(math.pi),
                              child: PlayingCardWidget(
                                card: card,
                                isFaceDown: false,
                                width: 56.0,
                                height: 84.0,
                                onTap: onToggleSeen,
                              ),
                            )
                          : PlayingCardWidget(
                              card: card,
                              isFaceDown: true,
                              width: 56.0,
                              height: 84.0,
                              onTap: onToggleSeen,
                            ),
                    ),
                  );
                }),
              ),
            );
          },
        ),
      ],
    );
  }
}
