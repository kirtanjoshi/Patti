import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:patii_engine/patii_engine.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/playing_card.dart';
import '../teenpatti_evaluator.dart';

/// 3-Card hand display for Teen Patti with 3D flip rotation between Blind and Seen modes,
/// and live hand-rank badge (Trail, Pure Sequence, Sequence, Color, Pair, High Card).
class TeenPattiHandFan extends StatelessWidget {
  final List<Card> cards;
  final bool isSeen;
  final VoidCallback onToggleSeen;

  const TeenPattiHandFan({
    super.key,
    required this.cards,
    required this.isSeen,
    required this.onToggleSeen,
  });

  @override
  Widget build(BuildContext context) {
    final handRank = isSeen ? TeenPattiEvaluator.evaluateRankName(cards) : '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Hand rank badge (when Seen) OR "See Cards" Gold CTA (when Blind)
        if (isSeen)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 3.0),
            margin: const EdgeInsets.only(bottom: 4.0),
            decoration: BoxDecoration(
              gradient: PatiiColors.goldButtonGradient,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: PatiiColors.goldDark.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.stars,
                  size: 14.0,
                  color: PatiiColors.navy,
                ),
                const SizedBox(width: 5.0),
                Text(
                  handRank,
                  style: PatiiTypography.cinzel(
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    color: PatiiColors.navy,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: GoldButton(
              label: 'teenpatti.see_cards'.tr(),
              icon: Icons.visibility_outlined,
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
              onPressed: onToggleSeen,
            ),
          ),

        // 3 Cards Fan with 3D Flip animation
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 320),
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
                  // Card fan slight rotation (-6 deg, 0 deg, +6 deg)
                  final fanAngle = (index - 1) * 0.10;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
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
                              child: PlayingCard.table(
                                card: card,
                                isFaceDown: false,
                                width: 50.0,
                                height: 72.0,
                                onTap: onToggleSeen,
                              ),
                            )
                          : PlayingCard.table(
                              card: card,
                              isFaceDown: true,
                              width: 50.0,
                              height: 72.0,
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
