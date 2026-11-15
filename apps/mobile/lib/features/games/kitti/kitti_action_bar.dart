import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:patii_engine/patii_engine.dart';
import '../../table/widgets/playing_card_widget.dart';

class KittiActionBar extends StatelessWidget {
  final List<Card> unassignedCards;
  final Card? selectedCard;
  final bool isAllSlotsFilled;
  final void Function(Card card) onCardTap;
  final VoidCallback onBestArrangement;
  final VoidCallback onConfirmShow;
  final VoidCallback onFold;

  const KittiActionBar({
    super.key,
    required this.unassignedCards,
    this.selectedCard,
    required this.isAllSlotsFilled,
    required this.onCardTap,
    required this.onBestArrangement,
    required this.onConfirmShow,
    required this.onFold,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hand Cards Rack
          if (unassignedCards.isNotEmpty)
            SizedBox(
              height: 84.0,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: unassignedCards.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8.0),
                itemBuilder: (context, index) {
                  final card = unassignedCards[index];
                  return PlayingCardWidget(
                    card: card,
                    isSelected: selectedCard?.id == card.id,
                    onTap: () => onCardTap(card),
                  );
                },
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'kitti.slot_hint'.tr(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: 12.0),

          // Action Buttons: Fold, Best Arrangement, Confirm Show
          Row(
            children: [
              Semantics(
                button: true,
                label: 'kitti.fold'.tr(),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onPressed: onFold,
                    child: Text('kitti.fold'.tr()),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'kitti.best_arrangement'.tr(),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48.0),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onPressed: onBestArrangement,
                      icon: const Icon(Icons.auto_fix_high),
                      label: Text(
                        'kitti.best_arrangement'.tr(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'kitti.confirm_show'.tr(),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48.0),
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onPressed: isAllSlotsFilled ? onConfirmShow : null,
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(
                        'kitti.confirm_show'.tr(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
