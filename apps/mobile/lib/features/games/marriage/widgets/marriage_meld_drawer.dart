import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:patii_engine/patii_engine.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/glass_sheet.dart';
import '../../../../core/widgets/playing_card.dart';
import '../marriage_models.dart';

/// Collapsible bottom glass drawer for Marriage melds.
/// When collapsed, it forms a sleek 36px bar indicating meld progress.
/// When expanded, it slides up over the hand to allow slot management,
/// pure/dublee switching, auto-grouping, and "See Maal" / "Declare" execution.
class MarriageMeldDrawer extends StatefulWidget {
  final List<MarriageMeldSlot> slots;
  final MeldType meldType;
  final bool hasSeenMaal;
  final Card? selectedCard;
  final VoidCallback onSeeMaal;
  final VoidCallback onDeclare;
  final ValueChanged<MeldType> onMeldTypeChanged;
  final void Function(int slotId, Card card) onCardAdded;
  final void Function(int slotId, Card card) onCardRemoved;
  final VoidCallback onAutoGroup;
  final VoidCallback onClearTray;

  const MarriageMeldDrawer({
    super.key,
    required this.slots,
    required this.meldType,
    required this.hasSeenMaal,
    this.selectedCard,
    required this.onSeeMaal,
    required this.onDeclare,
    required this.onMeldTypeChanged,
    required this.onCardAdded,
    required this.onCardRemoved,
    required this.onAutoGroup,
    required this.onClearTray,
  });

  @override
  State<MarriageMeldDrawer> createState() => _MarriageMeldDrawerState();
}

class _MarriageMeldDrawerState extends State<MarriageMeldDrawer> {
  bool _isExpanded = false;

  int get _validSlotsCount {
    return widget.slots.where((s) {
      final st = s.status;
      return st == MeldSlotStatus.pureSequence ||
          st == MeldSlotStatus.tunnela ||
          st == MeldSlotStatus.dublee;
    }).length;
  }

  bool get _isEligibleToSeeMaal {
    if (widget.hasSeenMaal) return false;
    if (widget.meldType == MeldType.pure) {
      return _validSlotsCount >= 3;
    } else {
      return _validSlotsCount >= 7;
    }
  }

  bool get _isEligibleToDeclare {
    if (!widget.hasSeenMaal) return false;
    return _validSlotsCount >= (widget.meldType == MeldType.pure ? 3 : 7);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isExpanded) {
      return _buildCollapsedBar();
    }
    return _buildExpandedDrawer();
  }

  /// Compact 36px floating bar when drawer is collapsed
  Widget _buildCollapsedBar() {
    final totalTarget = widget.meldType == MeldType.pure ? 3 : 7;
    final progressText = '$_validSlotsCount / $totalTarget';

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = true),
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.layers, size: 16, color: PatiiColors.gold),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'marriage.meld_tray'.tr(),
                overflow: TextOverflow.ellipsis,
                style: PatiiTypography.cinzel(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: PatiiColors.goldLight,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Progress Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _isEligibleToSeeMaal || _validSlotsCount == totalTarget
                    ? PatiiColors.success.withValues(alpha: 0.25)
                    : PatiiColors.navy.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isEligibleToSeeMaal
                      ? PatiiColors.success
                      : PatiiColors.goldDark.withValues(alpha: 0.4),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isEligibleToSeeMaal ? Icons.check_circle : Icons.style,
                    size: 11,
                    color: _isEligibleToSeeMaal
                        ? PatiiColors.success
                        : PatiiColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    progressText,
                    style: PatiiTypography.caption(
                      color: _isEligibleToSeeMaal
                          ? PatiiColors.success
                          : PatiiColors.textPrimary,
                      bold: true,
                    ).copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),

            // See Maal Glowing CTA if eligible
            if (_isEligibleToSeeMaal) ...[
              const SizedBox(width: 8),
              GoldButton(
                label: 'marriage.see_maal'.tr(),
                icon: Icons.stars,
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                onPressed: widget.onSeeMaal,
              ),
            ],

            const SizedBox(width: 6),
            const Icon(
              Icons.keyboard_arrow_up,
              size: 20,
              color: PatiiColors.goldLight,
            ),
          ],
        ),
      ),
    );
  }

  /// Full-featured sliding drawer when expanded
  Widget _buildExpandedDrawer() {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drawer Header Row: Title & Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.layers, size: 16, color: PatiiColors.gold),
                  const SizedBox(width: 6),
                  Text(
                    'marriage.meld_tray'.tr(),
                    style: PatiiTypography.cinzel(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: PatiiColors.goldLight,
                    ),
                  ),
                ],
              ),
              IconButton(
                iconSize: 22,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: const Icon(Icons.keyboard_arrow_down, color: PatiiColors.goldLight),
                onPressed: () => setState(() => _isExpanded = false),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Drawer Subheader Row: Mode Toggle & Auto Group
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Pure vs Dublee switch
              Container(
                decoration: BoxDecoration(
                  color: PatiiColors.navy.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: PatiiColors.goldDark.withValues(alpha: 0.5),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTypeButton(
                      '3 Pure',
                      widget.meldType == MeldType.pure,
                      () => widget.onMeldTypeChanged(MeldType.pure),
                    ),
                    _buildTypeButton(
                      '7 Dublees',
                      widget.meldType == MeldType.dublee,
                      () => widget.onMeldTypeChanged(MeldType.dublee),
                    ),
                  ],
                ),
              ),
              GhostButton(
                label: 'marriage.auto_group'.tr(),
                icon: Icons.auto_fix_high,
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                onPressed: widget.onAutoGroup,
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Meld Slots Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.slots.map((slot) => _buildSlotItem(slot)).toList(),
            ),
          ),
          const SizedBox(height: 6),

          // Footer Action (See Maal or Declare)
          if (_isEligibleToSeeMaal)
            GoldButton(
              label: 'marriage.see_maal'.tr(),
              icon: Icons.stars,
              height: 36,
              onPressed: widget.onSeeMaal,
            )
          else if (_isEligibleToDeclare)
            GoldButton(
              label: 'marriage.declare'.tr(),
              icon: Icons.emoji_events,
              height: 36,
              onPressed: widget.onDeclare,
            ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? PatiiColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: PatiiTypography.caption(
            color: isSelected ? PatiiColors.navy : PatiiColors.textSecondary,
            bold: isSelected,
          ).copyWith(fontSize: 11),
        ),
      ),
    );
  }

  Widget _buildSlotItem(MarriageMeldSlot slot) {
    final status = slot.status;
    final isValid = status == MeldSlotStatus.pureSequence ||
        status == MeldSlotStatus.tunnela ||
        status == MeldSlotStatus.dublee;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: DragTarget<Card>(
        onWillAcceptWithDetails: (details) => !slot.isFull,
        onAcceptWithDetails: (details) => widget.onCardAdded(slot.id, details.data),
        builder: (context, candidateData, rejectedData) {
          return GestureDetector(
            onTap: () {
              if (widget.selectedCard != null && !slot.isFull) {
                widget.onCardAdded(slot.id, widget.selectedCard!);
              }
            },
            child: Container(
              width: 98,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: PatiiColors.navySurface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isValid
                      ? PatiiColors.success
                      : PatiiColors.goldDark.withValues(alpha: 0.4),
                  width: isValid ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Slot ${slot.id + 1}',
                    style: PatiiTypography.caption(
                      color: isValid ? PatiiColors.success : PatiiColors.goldLight,
                      bold: true,
                    ).copyWith(fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 52,
                    child: slot.cards.isEmpty
                        ? Center(
                            child: Icon(
                              Icons.add_circle_outline,
                              size: 20,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          )
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: slot.cards.map((card) {
                                return GestureDetector(
                                  onTap: () => widget.onCardRemoved(slot.id, card),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 1),
                                    child: PlayingCard.table(
                                      card: card,
                                      width: 22,
                                      height: 34,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
