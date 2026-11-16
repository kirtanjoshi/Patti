import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:patii_engine/patii_engine.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/playing_card.dart';

/// Casino-Style Kitti Action Bar.
/// Displays the unassigned cards rack and action buttons (Fold, Auto Arrange, Confirm Show).
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: PatiiColors.navySurface.withValues(alpha: 0.90),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hand Cards Rack
          if (unassignedCards.isNotEmpty)
            SizedBox(
              height: 68.0,
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: unassignedCards.map((card) {
                      final isSelected = selectedCard?.id == card.id;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3.0),
                        child: GestureDetector(
                          onTap: () => onCardTap(card),
                          child: PlayingCard.table(
                            card: card,
                            width: 42.0,
                            height: 60.0,
                            isSelected: isSelected,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                'kitti.slot_hint'.tr(),
                textAlign: TextAlign.center,
                style: PatiiTypography.caption(
                  color: PatiiColors.goldLight,
                ),
              ),
            ),
          const SizedBox(height: 6.0),

          // Action Buttons: Fold, Best Arrangement, Confirm Show
          Row(
            children: [
              // Fold Button
              DangerButton(
                label: 'kitti.fold'.tr(),
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                onPressed: onFold,
              ),
              const SizedBox(width: 8.0),

              // Best Arrangement (Auto Arrange)
              Expanded(
                child: GhostButton(
                  label: 'kitti.best_arrangement'.tr(),
                  icon: Icons.auto_fix_high,
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  onPressed: onBestArrangement,
                ),
              ),
              const SizedBox(width: 8.0),

              // Confirm Show Button
              Expanded(
                child: GoldButton(
                  label: 'kitti.confirm_show'.tr(),
                  icon: Icons.check_circle_outline,
                  height: 38,
                  isEnabled: isAllSlotsFilled,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  onPressed: isAllSlotsFilled ? onConfirmShow : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
