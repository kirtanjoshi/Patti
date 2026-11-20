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
        // Seen: hand-rank tag. Blind: a quiet "See cards" control (tapping the
        // cards works too). Gold is reserved for the betting action.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: isSeen
              ? Container(
                  key: const ValueKey('rank'),
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 3.0),
                  margin: const EdgeInsets.only(bottom: 6.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: PatiiColors.gold.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars, size: 13, color: PatiiColors.gold),
                      const SizedBox(width: 5),
                      Text(
                        handRank,
                        style: PatiiTypography.display(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: PatiiColors.goldLight,
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  key: const ValueKey('see'),
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: GhostButton(
                    label: 'teenpatti.see_cards'.tr(),
                    icon: Icons.visibility_outlined,
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    onPressed: onToggleSeen,
                  ),
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
                  final fanAngle = (index - 1) * 0.12;

                  return Padding(
                    padding: EdgeInsets.only(top: index == 1 ? 0 : 6, left: 1, right: 1),
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
                                width: 60.0,
                                height: 84.0,
                                onTap: onToggleSeen,
                              ),
                            )
                          : PlayingCard.table(
                              card: card,
                              isFaceDown: true,
                              width: 60.0,
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
