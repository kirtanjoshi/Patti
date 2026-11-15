import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patii_engine/patii_engine.dart';
import '../../table/widgets/playing_card_widget.dart';
import '../../table/widgets/seat_widget.dart';
import 'marriage_dialogs.dart';
import 'marriage_meld_tray.dart';
import 'marriage_models.dart';
import 'marriage_table_center.dart';

class MarriageTableScreen extends ConsumerStatefulWidget {
  const MarriageTableScreen({super.key});

  @override
  ConsumerState<MarriageTableScreen> createState() =>
      _MarriageTableScreenState();
}

class _MarriageTableScreenState extends ConsumerState<MarriageTableScreen> {
  int currentRound = 1;
  int currentTurnSeat = 0; // 0: You, 1: Bot 1, 2: Bot 2, 3: Bot 3
  String turnPhase = 'draw'; // 'draw' | 'discard'
  bool isMaalSeen = false;
  MeldType activeMeldType = MeldType.pure;
  String? selectedCardId;
  bool isSortedBySuit = true;

  // The hidden cut joker (Maal)
  final Card cutJoker =
      const Card(suit: Suit.C, rank: 11, deck: 0, id: 'JC_cut');

  List<Card> stockPile = createInitialStockPile();
  List<Card> discardPile = createInitialDiscardPile();
  List<Card> myHand = createInitialMarriageHand();
  late List<MarriageMeldSlot> meldSlots;

  @override
  void initState() {
    super.initState();
    _resetMeldSlots(MeldType.pure);
  }

  void _resetMeldSlots(MeldType type) {
    activeMeldType = type;
    meldSlots = createInitialMeldSlots(type);
  }

  Card? get selectedCard {
    if (selectedCardId == null) return null;
    try {
      return myHand.firstWhere((c) => c.id == selectedCardId);
    } catch (_) {
      return null;
    }
  }

  int get liveMaalPoints {
    if (!isMaalSeen) return 0;
    final allCards = [...myHand];
    for (final slot in meldSlots) {
      allCards.addAll(slot.cards);
    }
    return calculateLiveMaalPoints(
      hand: allCards,
      maal: cutJoker,
      alterEnabled: true,
    );
  }

  void _onDrawStock() {
    if (currentTurnSeat != 0 || turnPhase != 'draw') return;
    if (stockPile.isEmpty) return;
    setState(() {
      final drawn = stockPile.removeLast();
      myHand.add(drawn);
      turnPhase = 'discard';
      selectedCardId = drawn.id;
    });
  }

  void _onDrawDiscard() {
    if (currentTurnSeat != 0 || turnPhase != 'draw') return;
    if (discardPile.isEmpty) return;
    setState(() {
      final drawn = discardPile.removeLast();
      myHand.add(drawn);
      turnPhase = 'discard';
      selectedCardId = drawn.id;
    });
  }

  void _onDiscardCard(Card card) {
    if (currentTurnSeat != 0 || turnPhase != 'discard') return;
    setState(() {
      myHand.removeWhere((c) => c.id == card.id);
      discardPile.add(card);
      selectedCardId = null;
      turnPhase = 'draw';
      currentTurnSeat = 1;

      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        setState(() => currentTurnSeat = 2);
        Future.delayed(const Duration(milliseconds: 700), () {
          if (!mounted) return;
          setState(() => currentTurnSeat = 3);
          Future.delayed(const Duration(milliseconds: 700), () {
            if (!mounted) return;
            setState(() {
              currentTurnSeat = 0;
              turnPhase = 'draw';
            });
          });
        });
      });
    });
  }

  void _onAddCardToSlot(int slotId, Card card) {
    final slotIdx = meldSlots.indexWhere((s) => s.id == slotId);
    if (slotIdx == -1) return;
    final slot = meldSlots[slotIdx];
    if (slot.isFull) return;

    setState(() {
      myHand.removeWhere((c) => c.id == card.id);
      meldSlots[slotIdx] = slot.copyWith(cards: [...slot.cards, card]);
      if (selectedCardId == card.id) selectedCardId = null;
    });
  }

  void _onRemoveCardFromSlot(int slotId, Card card) {
    final slotIdx = meldSlots.indexWhere((s) => s.id == slotId);
    if (slotIdx == -1) return;
    final slot = meldSlots[slotIdx];

    setState(() {
      final updated = List<Card>.from(slot.cards)
        ..removeWhere((c) => c.id == card.id);
      meldSlots[slotIdx] = slot.copyWith(cards: updated);
      myHand.add(card);
    });
  }

  void _onAutoGroup() {
    _onClearTray();
    setState(() {
      if (activeMeldType == MeldType.pure) {
        final combinations = findAutoGroupPureCombinations(myHand);
        for (int i = 0; i < combinations.length && i < meldSlots.length; i++) {
          meldSlots[i] = meldSlots[i].copyWith(cards: combinations[i]);
          for (final c in combinations[i]) {
            myHand.removeWhere((x) => x.id == c.id);
          }
        }
      }
    });
  }

  void _onClearTray() {
    setState(() {
      for (final slot in meldSlots) {
        myHand.addAll(slot.cards);
      }
      _resetMeldSlots(activeMeldType);
    });
  }

  void _onSeeMaal() {
    setState(() => isMaalSeen = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('marriage.maal_seen_desc'.tr()),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _onDeclare() {
    showMarriageDeclareDialog(context);
  }

  void _toggleSort() {
    setState(() {
      isSortedBySuit = !isSortedBySuit;
      myHand = isSortedBySuit
          ? sortCardsBySuit(myHand)
          : sortCardsByRank(myHand);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Semantics(
                    button: true,
                    label: 'marriage.leave'.tr(),
                    child: IconButton(
                      icon:
                          Icon(Icons.arrow_back, color: colorScheme.onSurface),
                      onPressed: () => showMarriageLeaveDialog(context),
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 6.0),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Text(
                        'marriage.round_info'.tr(args: ['$currentRound', '800']),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  // Maal Status Chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: isMaalSeen
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                        color: isMaalSeen
                            ? colorScheme.primary
                            : colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isMaalSeen ? Icons.stars : Icons.visibility_off,
                          size: 16,
                          color: isMaalSeen
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          isMaalSeen
                              ? 'marriage.pts'.tr(args: ['$liveMaalPoints'])
                              : 'marriage.phase_1_badge'.tr(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isMaalSeen
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Semantics(
                    button: true,
                    label: 'marriage.game_rules'.tr(),
                    child: IconButton(
                      icon: Icon(Icons.help_outline,
                          color: colorScheme.onSurface),
                      onPressed: () => showMarriageRulesDialog(context),
                    ),
                  ),
                ],
              ),
            ),

            // Main Table & Center Area
            Expanded(
              child: MarriageTableCenter(
                currentTurnSeat: currentTurnSeat,
                turnPhase: turnPhase,
                isMaalSeen: isMaalSeen,
                cutJoker: cutJoker,
                stockPile: stockPile,
                discardPile: discardPile,
                onDrawStock: _onDrawStock,
                onDrawDiscard: _onDrawDiscard,
                onDiscardCard: _onDiscardCard,
              ),
            ),

            // Meld Tray
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: MarriageMeldTray(
                slots: meldSlots,
                meldType: activeMeldType,
                hasSeenMaal: isMaalSeen,
                selectedCard: selectedCard,
                onSeeMaal: _onSeeMaal,
                onDeclare: _onDeclare,
                onMeldTypeChanged: (type) {
                  _onClearTray();
                  setState(() => _resetMeldSlots(type));
                },
                onCardAdded: _onAddCardToSlot,
                onCardRemoved: _onRemoveCardFromSlot,
                onAutoGroup: _onAutoGroup,
                onClearTray: _onClearTray,
              ),
            ),
            const SizedBox(height: 8.0),

            // Bottom Area: My Seat & 21-Card Hand
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16.0)),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Hand controls row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SeatWidget(
                        displayName: 'You',
                        isCurrentTurn: currentTurnSeat == 0,
                        statusText: isMaalSeen
                            ? 'marriage.pts'.tr(args: ['$liveMaalPoints'])
                            : 'marriage.cards_in_hand'
                                .tr(args: ['${myHand.length}']),
                      ),
                      // Instruction indicator
                      Text(
                        currentTurnSeat == 0
                            ? (turnPhase == 'draw'
                                ? 'marriage.phase_draw'.tr()
                                : 'marriage.phase_discard'.tr())
                            : 'table.waiting'.tr(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: currentTurnSeat == 0
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          fontWeight: currentTurnSeat == 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      Row(
                        children: [
                          // Sort Button
                          Semantics(
                            button: true,
                            label: isSortedBySuit
                                ? 'marriage.sort_suit'.tr()
                                : 'marriage.sort_rank'.tr(),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                  minWidth: 48, minHeight: 48),
                              child: TextButton.icon(
                                onPressed: _toggleSort,
                                icon: const Icon(Icons.sort, size: 16),
                                label: Text(
                                  isSortedBySuit
                                      ? 'marriage.sort_suit'.tr()
                                      : 'marriage.sort_rank'.tr(),
                                  style: theme.textTheme.labelSmall,
                                ),
                              ),
                            ),
                          ),
                          // Discard Button
                          if (currentTurnSeat == 0 &&
                              turnPhase == 'discard') ...[
                            const SizedBox(width: 8.0),
                            Semantics(
                              button: true,
                              label: 'marriage.discard'.tr(),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                    minWidth: 48, minHeight: 48),
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: colorScheme.error,
                                    foregroundColor: colorScheme.onError,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0),
                                  ),
                                  onPressed: selectedCard != null
                                      ? () => _onDiscardCard(selectedCard!)
                                      : null,
                                  child: Text('marriage.discard'.tr()),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),

                  // 21-card hand view with auto-sort and drag/tap selection
                  SizedBox(
                    height: 90.0,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: myHand.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 4.0),
                      itemBuilder: (context, index) {
                        final card = myHand[index];
                        final isSelected = selectedCardId == card.id;

                        return Draggable<Card>(
                          data: card,
                          feedback: Material(
                            color: Colors.transparent,
                            child: PlayingCardWidget(card: card),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: PlayingCardWidget(card: card),
                          ),
                          child: PlayingCardWidget(
                            card: card,
                            isSelected: isSelected,
                            isLegal: true,
                            onTap: () {
                              setState(() {
                                selectedCardId = isSelected ? null : card.id;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
