import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patii_engine/patii_engine.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/card_hand.dart';
import '../../../../core/widgets/player_seat.dart';
import '../../../../core/widgets/table_shell.dart';
import '../../../../core/widgets/toast_banner.dart';
import 'marriage_dialogs.dart';
import 'marriage_models.dart';
import 'widgets/marriage_center_area.dart';
import 'widgets/marriage_meld_drawer.dart';

/// Casino-Style Marriage Card Game Table Screen (Landscape).
/// Features:
/// - Screen orientation locked to Landscape via TableShell
/// - Elliptical 4-player seating: You (bottom-left), Bot 1 (West), Bot 2 (North), Bot 3 (East)
/// - Center Table Area: Stock pile, Discard pile, and Maal / Cut Joker card
/// - Collapsible bottom drawer for Melds (3 Pure / 7 Dublees) that never covers hand
/// - Overlapping 21-card hand fan that dynamically fits within screen bounds
/// - Smooth tap/drag discard, auto-sort, and live Maal point calculator
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
    ToastBanner.show(context, 'marriage.phase_discard'.tr(), icon: Icons.arrow_upward);
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
    ToastBanner.show(context, 'marriage.phase_discard'.tr(), icon: Icons.arrow_upward);
  }

  void _onDiscardCard(Card card) {
    if (currentTurnSeat != 0 || turnPhase != 'discard') return;
    setState(() {
      myHand.removeWhere((c) => c.id == card.id);
      discardPile.add(card);
      selectedCardId = null;
      turnPhase = 'draw';
      currentTurnSeat = 1;

      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() => currentTurnSeat = 2);
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          setState(() => currentTurnSeat = 3);
          Future.delayed(const Duration(milliseconds: 600), () {
            if (!mounted) return;
            setState(() {
              currentTurnSeat = 0;
              turnPhase = 'draw';
            });
            ToastBanner.show(
              context,
              'marriage.phase_draw'.tr(),
              icon: Icons.touch_app,
            );
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
    ToastBanner.show(context, 'Auto grouped pure sequences!', icon: Icons.auto_fix_high);
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
    ToastBanner.show(
      context,
      'marriage.maal_seen_desc'.tr(),
      icon: Icons.stars,
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
    final isMyTurn = currentTurnSeat == 0;
    final canDraw = isMyTurn && turnPhase == 'draw';
    final canDiscard = isMyTurn && turnPhase == 'discard';

    return TableShell(
      gameTitle: 'marriage.title'.tr(),
      roundInfo: '${'table.round'.tr()} $currentRound · 800',
      pot: 800,
      onRulesTap: () => showMarriageRulesDialog(context),
      onLeave: () => showMarriageLeaveDialog(context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth = constraints.maxWidth;
          final tableHeight = constraints.maxHeight;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Top Opponent (Bot 2, North)
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: PlayerSeat(
                    displayName: 'Bot 2',
                    isCurrentTurn: currentTurnSeat == 2,
                    infoPillText: '21 cards',
                    avatarUrl: null,
                    isBot: true,
                  ),
                ),
              ),

              // 2. Left Opponent (Bot 1, West)
              Positioned(
                left: 12,
                top: (tableHeight - 160) / 2,
                child: PlayerSeat(
                  displayName: 'Bot 1',
                  isCurrentTurn: currentTurnSeat == 1,
                  infoPillText: '21 cards',
                  avatarUrl: null,
                  isBot: true,
                ),
              ),

              // 3. Right Opponent (Bot 3, East)
              Positioned(
                right: 12,
                top: (tableHeight - 160) / 2,
                child: PlayerSeat(
                  displayName: 'Bot 3',
                  isCurrentTurn: currentTurnSeat == 3,
                  infoPillText: '21 cards',
                  avatarUrl: null,
                  isBot: true,
                ),
              ),

              // 4. Center Area: Stock | Discard | Maal card
              Positioned(
                left: 0,
                right: 0,
                top: (tableHeight - 170) / 2,
                child: Center(
                  child: MarriageCenterArea(
                    isMaalSeen: isMaalSeen,
                    cutJoker: cutJoker,
                    stockPile: stockPile,
                    discardPile: discardPile,
                    canDraw: canDraw,
                    onDrawStock: _onDrawStock,
                    onDrawDiscard: _onDrawDiscard,
                  ),
                ),
              ),

              // 5. You (Bottom Left PlayerSeat)
              Positioned(
                left: 16,
                bottom: 8,
                child: PlayerSeat(
                  displayName: 'You',
                  isCurrentTurn: isMyTurn,
                  infoPillText: isMaalSeen
                      ? 'marriage.pts'.tr(args: ['$liveMaalPoints'])
                      : 'marriage.cards_in_hand'.tr(args: ['${myHand.length}']),
                  isBot: false,
                ),
              ),

              // 6. Action Buttons next to Hand (Right Side)
              Positioned(
                right: 12,
                bottom: tableWidth < 700 ? 84 : 98,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Sort Button
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      child: GhostButton(
                        label: isSortedBySuit ? 'marriage.sort_suit'.tr() : 'marriage.sort_rank'.tr(),
                        icon: Icons.sort_rounded,
                        height: 36,
                        onPressed: _toggleSort,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Discard Button (when eligible)
                    if (canDiscard && selectedCard != null)
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                        child: DangerButton(
                          label: 'marriage.discard'.tr(),
                          icon: Icons.arrow_upward,
                          height: 36,
                          onPressed: () => _onDiscardCard(selectedCard!),
                        ),
                      ),
                  ],
                ),
              ),

              // 7. My 21-Card Hand (Centered at Bottom)
              Positioned(
                left: 108,
                right: 12,
                bottom: -14,
                child: CardHand(
                  cards: myHand,
                  selectedCardId: selectedCardId,
                  playableCardIds: canDiscard
                      ? myHand.map((c) => c.id).toSet()
                      : const {},
                  wildOrMaalCardId: isMaalSeen ? cutJoker.id : null,
                  cardWidth: tableWidth < 700 ? 46.0 : 54.0,
                  cardHeight: tableWidth < 700 ? 68.0 : 80.0,
                  maxArcDegrees: 8.0,
                  onCardTap: (card) {
                    setState(() {
                      selectedCardId =
                          selectedCardId == card.id ? null : card.id;
                    });
                  },
                  onCardPlay: (card) {
                    if (canDiscard) {
                      _onDiscardCard(card);
                    }
                  },
                ),
              ),

              // 8. Collapsible Meld Drawer (Floating above hand bar)
              Positioned(
                left: tableWidth < 700 ? 50 : 90,
                right: tableWidth < 700 ? 50 : 90,
                bottom: tableWidth < 700 ? 76 : 90,
                child: Center(
                  child: MarriageMeldDrawer(
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
              ),
            ],
          );
        },
      ),
    );
  }
}
