import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:patii_engine/patii_engine.dart';
import '../../table/widgets/playing_card_widget.dart';
import 'kitti_evaluator.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: 'kitti.slot_hint'.tr(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(3, (index) {
          final slotCards = index < slots.length ? slots[index] : <Card>[];
          final evaluation = slotCards.length == 3
              ? KittiEvaluator.evaluate(slotCards)
              : null;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: _buildSlotContainer(
              context: context,
              theme: theme,
              colorScheme: colorScheme,
              slotIndex: index,
              cards: slotCards,
              evaluation: evaluation,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSlotContainer({
    required BuildContext context,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required int slotIndex,
    required List<Card> cards,
    required KittiHandEvaluation? evaluation,
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

        return InkWell(
          onTap: () => onSlotTap(slotIndex),
          borderRadius: BorderRadius.circular(12.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: isHovered
                  ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: isHovered
                    ? colorScheme.primary
                    : (isFull ? colorScheme.primary.withValues(alpha: 0.5) : colorScheme.outlineVariant),
                width: isHovered || isFull ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header row: Slot name, Hand evaluation badge, card count
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (evaluation != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          evaluation.labelKey.tr(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Text(
                        '${cards.length}/3',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (cards.isNotEmpty && onClearSlot != null)
                      Semantics(
                        button: true,
                        label: 'kitti.reset'.tr(),
                        child: IconButton(
                          iconSize: 18,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                          icon: Icon(Icons.close, color: colorScheme.outline),
                          onPressed: () => onClearSlot!(slotIndex),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8.0),

                // Cards Row: 3 slots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (cardIndex) {
                    final hasCard = cardIndex < cards.length;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: hasCard
                          ? _buildFilledCard(cards[cardIndex], slotIndex)
                          : _buildEmptyPlaceholder(colorScheme, slotIndex),
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
    return PlayingCardWidget(
      card: card,
      width: 52.0,
      height: 74.0,
      onTap: () => onCardTapInSlot(slotIndex, card),
    );
  }

  Widget _buildEmptyPlaceholder(ColorScheme colorScheme, int slotIndex) {
    return Semantics(
      button: true,
      label: 'kitti.slot_hint'.tr(),
      child: InkWell(
        onTap: () => onSlotTap(slotIndex),
        borderRadius: BorderRadius.circular(6.0),
        child: Container(
          width: 52.0,
          height: 74.0,
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(
              color: colorScheme.outlineVariant,
              style: BorderStyle.solid,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.add_rounded,
              color: colorScheme.outlineVariant,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
