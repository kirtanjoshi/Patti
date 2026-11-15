import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:patii_engine/patii_engine.dart';
import '../../table/widgets/playing_card_widget.dart';
import 'marriage_models.dart';

class MarriageMeldTray extends StatelessWidget {
  final List<MarriageMeldSlot> slots;
  final MeldType meldType;
  final bool hasSeenMaal;
  final Card? selectedCard;
  final VoidCallback? onSeeMaal;
  final VoidCallback? onDeclare;
  final ValueChanged<MeldType>? onMeldTypeChanged;
  final void Function(int slotId, Card card)? onCardAdded;
  final void Function(int slotId, Card card)? onCardRemoved;
  final VoidCallback? onAutoGroup;
  final VoidCallback? onClearTray;

  const MarriageMeldTray({
    super.key,
    required this.slots,
    required this.meldType,
    required this.hasSeenMaal,
    this.selectedCard,
    this.onSeeMaal,
    this.onDeclare,
    this.onMeldTypeChanged,
    this.onCardAdded,
    this.onCardRemoved,
    this.onAutoGroup,
    this.onClearTray,
  });

  bool get canSeeMaal {
    if (hasSeenMaal) return false;
    if (slots.isEmpty) return false;
    return slots.every((s) => s.isValid);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row: Mode Switcher & Tools
          Row(
            children: [
              Icon(
                Icons.auto_awesome_motion,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8.0),
              Text(
                'marriage.meld_tray'.tr(),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              if (!hasSeenMaal) ...[
                // Mode Toggle: 3 Pure vs 7 Dublees
                SegmentedButton<MeldType>(
                  segments: [
                    ButtonSegment(
                      value: MeldType.pure,
                      label: Text(
                        'marriage.pure_sequences'.tr(),
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                    ButtonSegment(
                      value: MeldType.dublee,
                      label: Text(
                        'marriage.dublees'.tr(),
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  ],
                  selected: {meldType},
                  onSelectionChanged: (newSelection) {
                    onMeldTypeChanged?.call(newSelection.first);
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.padded,
                  ),
                ),
                const SizedBox(width: 8.0),
              ],
              // Auto-group helper
              Semantics(
                button: true,
                label: 'marriage.auto_group'.tr(),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  child: IconButton(
                    tooltip: 'marriage.auto_group'.tr(),
                    icon: Icon(Icons.auto_fix_high, color: colorScheme.primary),
                    onPressed: onAutoGroup,
                  ),
                ),
              ),
              // Clear tray
              Semantics(
                button: true,
                label: 'marriage.clear_tray'.tr(),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  child: IconButton(
                    tooltip: 'marriage.clear_tray'.tr(),
                    icon: Icon(Icons.delete_sweep_outlined, color: colorScheme.onSurfaceVariant),
                    onPressed: onClearTray,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),

          // Meld Slots (Horizontal List)
          SizedBox(
            height: 120.0,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: slots.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8.0),
              itemBuilder: (context, index) {
                final slot = slots[index];
                return _buildSlot(context, slot);
              },
            ),
          ),
          const SizedBox(height: 8.0),

          // Action Button Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  hasSeenMaal
                      ? 'marriage.maal_seen_desc'.tr()
                      : (canSeeMaal
                          ? 'marriage.see_maal'.tr()
                          : 'marriage.cannot_see_maal'.tr()),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: canSeeMaal
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: canSeeMaal ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8.0),
              if (!hasSeenMaal)
                Semantics(
                  button: true,
                  label: 'marriage.see_maal'.tr(),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 120, minHeight: 48),
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onPressed: canSeeMaal ? onSeeMaal : null,
                      icon: const Icon(Icons.visibility),
                      label: Text('marriage.see_maal'.tr()),
                    ),
                  ),
                )
              else
                Semantics(
                  button: true,
                  label: 'marriage.declare'.tr(),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 120, minHeight: 48),
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onPressed: onDeclare,
                      icon: const Icon(Icons.emoji_events),
                      label: Text('marriage.declare'.tr()),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlot(BuildContext context, MarriageMeldSlot slot) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = slot.status;

    Color borderColor;
    Color statusBgColor;
    Color statusTextColor;
    String statusLabel;

    switch (status) {
      case MeldSlotStatus.pureSequence:
        borderColor = colorScheme.primary;
        statusBgColor = colorScheme.primaryContainer;
        statusTextColor = colorScheme.onPrimaryContainer;
        statusLabel = 'marriage.slot_pure_seq'.tr();
        break;
      case MeldSlotStatus.tunnela:
        borderColor = colorScheme.primary;
        statusBgColor = colorScheme.primaryContainer;
        statusTextColor = colorScheme.onPrimaryContainer;
        statusLabel = 'marriage.slot_tunnela'.tr();
        break;
      case MeldSlotStatus.dublee:
        borderColor = colorScheme.primary;
        statusBgColor = colorScheme.primaryContainer;
        statusTextColor = colorScheme.onPrimaryContainer;
        statusLabel = 'marriage.slot_dublee'.tr();
        break;
      case MeldSlotStatus.invalid:
        borderColor = colorScheme.error;
        statusBgColor = colorScheme.errorContainer;
        statusTextColor = colorScheme.onErrorContainer;
        statusLabel = 'marriage.slot_invalid'.tr();
        break;
      case MeldSlotStatus.incomplete:
        borderColor = colorScheme.outline;
        statusBgColor = colorScheme.surfaceContainer;
        statusTextColor = colorScheme.onSurfaceVariant;
        statusLabel = 'marriage.slot_incomplete'.tr(
          args: ['${slot.requiredCardCount - slot.cards.length}'],
        );
        break;
      case MeldSlotStatus.empty:
        borderColor = colorScheme.outlineVariant;
        statusBgColor = colorScheme.surfaceContainer;
        statusTextColor = colorScheme.onSurfaceVariant;
        statusLabel = 'marriage.slot_empty'.tr();
        break;
    }

    final slotWidth = slot.type == MeldType.pure ? 136.0 : 96.0;

    return DragTarget<Card>(
      onWillAcceptWithDetails: (details) => !slot.isFull,
      onAcceptWithDetails: (details) {
        onCardAdded?.call(slot.id, details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = candidateData.isNotEmpty;

        return Semantics(
          button: true,
          label: '${'marriage.slot_title'.tr(args: ['${slot.id + 1}'])}: $statusLabel',
          child: GestureDetector(
            onTap: () {
              if (selectedCard != null && !slot.isFull) {
                onCardAdded?.call(slot.id, selectedCard!);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: slotWidth,
              decoration: BoxDecoration(
                color: isHighlighted
                    ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : colorScheme.surface,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: isHighlighted ? colorScheme.primary : borderColor,
                  width: slot.isValid || isHighlighted ? 2.0 : 1.0,
                ),
              ),
              padding: const EdgeInsets.all(6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status badge row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      statusLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusTextColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6.0),

                  // Cards area
                  Expanded(
                    child: slot.cards.isEmpty
                        ? Center(
                            child: Icon(
                              Icons.add_circle_outline,
                              color: colorScheme.outlineVariant,
                              size: 24,
                            ),
                          )
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: slot.cards.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 4.0),
                            itemBuilder: (context, cardIdx) {
                              final card = slot.cards[cardIdx];
                              return Semantics(
                                button: true,
                                label: 'marriage.tap_to_return'.tr(),
                                child: PlayingCardWidget(
                                  card: card,
                                  width: 38.0,
                                  height: 60.0,
                                  onTap: () => onCardRemoved?.call(slot.id, card),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
