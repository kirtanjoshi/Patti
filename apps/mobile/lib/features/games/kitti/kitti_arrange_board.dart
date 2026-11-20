import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:patii_engine/patii_engine.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/glass_sheet.dart';
import '../../../../core/widgets/playing_card.dart';
import 'kitti_evaluator.dart';

/// Casino-Style Kitti 3x3 Arrange Board (Responsive Landscape/Portrait).
/// In Landscape, Show 1, Show 2, and Show 3 sit horizontally in a row.
/// Each show accepts 3 cards via drag-and-drop or tap, showing real-time evaluation.
class KittiArrangeBoard extends StatelessWidget {
  final List<List<Card>> slots;
  final Card? selectedCard;
  final void Function(int slotIndex, Card card) onCardTapInSlot;
  final void Function(int slotIndex) onSlotTap;
  final void Function(int slotIndex, Card card)? onCardDropped;
  final void Function(int slotIndex)? onClearSlot;

  const KittiArrangeBoard({
    super.key,
    required this.slots,
    this.selectedCard,
    required this.onCardTapInSlot,
    required this.onSlotTap,
    this.onCardDropped,
    this.onClearSlot,
  });

  String _slotTitle(int index) {
    switch (index) {
      case 0:
        return 'kitti.show_1'.tr();
      case 1:
        return 'kitti.show_2'.tr();
      case 2:
      default:
        return 'kitti.show_3'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape ||
            constraints.maxWidth > 340;

        final slotWidgets = List.generate(3, (index) {
          final slotCards = index < slots.length ? slots[index] : <Card>[];
          final evaluation = slotCards.length == 3
              ? KittiEvaluator.evaluate(slotCards)
              : null;

          return _buildSlotContainer(
            context: context,
            slotIndex: index,
            cards: slotCards,
            evaluation: evaluation,
            isCompact: isLandscape,
          );
        });

        if (isLandscape) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: slotWidgets.map((w) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: w,
              ),
            )).toList(),
          );
        } else {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: slotWidgets.map((w) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: w,
            )).toList(),
          );
        }
      },
    );
  }

  Widget _buildSlotContainer({
    required BuildContext context,
    required int slotIndex,
    required List<Card> cards,
    required KittiHandEvaluation? evaluation,
    required bool isCompact,
  }) {
    final title = _slotTitle(slotIndex);
    final isFull = cards.length == 3;

    return DragTarget<Card>(
      onWillAcceptWithDetails: (details) => cards.length < 3,
      onAcceptWithDetails: (details) {
        onCardDropped?.call(slotIndex, details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return GestureDetector(
          onTap: () => onSlotTap(slotIndex),
          child: GlassPanel(
            padding: const EdgeInsets.all(6.0),
            customBorder: Border.all(
              color: isHovered
                  ? PatiiColors.gold
                  : (isFull
                      ? PatiiColors.success.withValues(alpha: 0.6)
                      : PatiiColors.goldDark.withValues(alpha: 0.3)),
              width: isHovered || isFull ? 1.5 : 1.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Slot Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: PatiiTypography.display(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: PatiiColors.goldLight,
                        ),
                      ),
                    ),
                    if (evaluation != null) ...[
                      const SizedBox(width: 4),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
                          decoration: BoxDecoration(
                            color: PatiiColors.success.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6.0),
                            border: Border.all(color: PatiiColors.success, width: 0.8),
                          ),
                          child: Text(
                            evaluation.labelKey.tr(),
                            overflow: TextOverflow.ellipsis,
                            style: PatiiTypography.caption(
                              color: PatiiColors.success,
                              bold: true,
                            ).copyWith(fontSize: 9),
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(width: 4),
                      Text(
                        '${cards.length}/3',
                        style: PatiiTypography.caption(
                          color: PatiiColors.textMuted,
                        ).copyWith(fontSize: 10),
                      ),
                    ],
                    if (cards.isNotEmpty && onClearSlot != null) ...[
                      const SizedBox(width: 2),
                      Semantics(
                        button: true,
                        label: 'kitti.reset'.tr(),
                        child: GestureDetector(
                          onTap: () => onClearSlot!(slotIndex),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: PatiiColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                  const SizedBox(height: 4.0),

                  // 3 Card Slots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (cardIndex) {
                      final hasCard = cardIndex < cards.length;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: hasCard
                            ? _buildFilledCard(cards[cardIndex], slotIndex)
                            : _buildEmptyPlaceholder(slotIndex),
                      );
                    }),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

  Widget _buildFilledCard(Card card, int slotIndex) {
    return GestureDetector(
      onTap: () => onCardTapInSlot(slotIndex, card),
      child: PlayingCard.table(
        card: card,
        width: 36.0,
        height: 52.0,
      ),
    );
  }

  Widget _buildEmptyPlaceholder(int slotIndex) {
    return Semantics(
      button: true,
      label: 'kitti.slot_hint'.tr(),
      child: GestureDetector(
        onTap: () => onSlotTap(slotIndex),
        child: Container(
          width: 36.0,
          height: 52.0,
          decoration: BoxDecoration(
            color: PatiiColors.navy.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(
              color: PatiiColors.goldDark.withValues(alpha: 0.35),
              style: BorderStyle.solid,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.add_rounded,
              color: PatiiColors.goldDark,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}
