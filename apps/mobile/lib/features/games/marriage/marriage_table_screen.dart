import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patii_engine/patii_engine.dart';
import '../../table/widgets/playing_card_widget.dart';
import '../../table/widgets/seat_widget.dart';
import 'marriage_meld_tray.dart';
import 'marriage_models.dart';

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

  // Stock pile
  List<Card> stockPile = [
    const Card(suit: Suit.S, rank: 1, deck: 1, id: 'AS1'),
    const Card(suit: Suit.H, rank: 4, deck: 1, id: '4H1'),
    const Card(suit: Suit.D, rank: 12, deck: 1, id: 'QD1'),
    const Card(suit: Suit.C, rank: 9, deck: 1, id: '9C1'),
    const Card(suit: Suit.S, rank: 3, deck: 1, id: '3S1'),
  ];

  // Discard pile
  List<Card> discardPile = [
    const Card(suit: Suit.H, rank: 2, deck: 0, id: '2H0'),
  ];

  // 21 Dealt cards for player 0
  List<Card> myHand = [
    // Pure Sequence 1 (also Marriage with cut joker)
    const Card(suit: Suit.C, rank: 10, deck: 0, id: '10C0'),
    const Card(suit: Suit.C, rank: 11, deck: 1, id: 'JC1'),
    const Card(suit: Suit.C, rank: 12, deck: 0, id: 'QC0'),
    // Pure Sequence 2
    const Card(suit: Suit.S, rank: 4, deck: 0, id: '4S0'),
    const Card(suit: Suit.S, rank: 5, deck: 0, id: '5S0'),
    const Card(suit: Suit.S, rank: 6, deck: 0, id: '6S0'),
    // Tunnela (3 identical 7 of diamonds)
    const Card(suit: Suit.D, rank: 7, deck: 0, id: '7D0'),
    const Card(suit: Suit.D, rank: 7, deck: 1, id: '7D1'),
    const Card(suit: Suit.D, rank: 7, deck: 2, id: '7D2'),
    // Alter card
    const Card(suit: Suit.S, rank: 11, deck: 0, id: 'JS0'),
    // Dublees and other cards
    const Card(suit: Suit.C, rank: 2, deck: 0, id: '2C0'),
    const Card(suit: Suit.C, rank: 2, deck: 1, id: '2C1'),
    const Card(suit: Suit.S, rank: 13, deck: 0, id: 'KS0'),
    const Card(suit: Suit.S, rank: 13, deck: 1, id: 'KS1'),
    const Card(suit: Suit.H, rank: 8, deck: 0, id: '8H0'),
    const Card(suit: Suit.H, rank: 9, deck: 0, id: '9H0'),
    const Card(suit: Suit.H, rank: 10, deck: 0, id: '10H0'),
    const Card(suit: Suit.D, rank: 3, deck: 0, id: '3D0'),
    const Card(suit: Suit.D, rank: 5, deck: 0, id: '5D0'),
    const Card(suit: Suit.S, rank: 9, deck: 0, id: '9S0'),
    const Card(suit: Suit.D, rank: 1, deck: 0, id: 'AD0'),
  ];

  late List<MarriageMeldSlot> meldSlots;

  @override
  void initState() {
    super.initState();
    _resetMeldSlots(MeldType.pure);
  }

  void _resetMeldSlots(MeldType type) {
    activeMeldType = type;
    final count = type == MeldType.pure ? 3 : 7;
    meldSlots = List.generate(
      count,
      (index) => MarriageMeldSlot(id: index, type: type),
    );
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
    // Combine cards in hand + cards in meld slots
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

      // Simulate bot turns sequentially
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
      final updated = List<Card>.from(slot.cards)..removeWhere((c) => c.id == card.id);
      meldSlots[slotIdx] = slot.copyWith(cards: updated);
      myHand.add(card);
    });
  }

  void _onAutoGroup() {
    _onClearTray();
    setState(() {
      if (activeMeldType == MeldType.pure) {
        // Find pure combinations from hand
        final combinations = <List<Card>>[];
        final remaining = List<Card>.from(myHand);

        // Check for tunnelas
        final groupedByRankAndSuit = <String, List<Card>>{};
        for (final c in remaining) {
          final key = '${c.rank}_${c.suit}';
          groupedByRankAndSuit.putIfAbsent(key, () => []).add(c);
        }
        for (final group in groupedByRankAndSuit.values) {
          if (group.length >= 3 && combinations.length < 3) {
            final tunnela = group.take(3).toList();
            combinations.add(tunnela);
            for (final c in tunnela) {
              remaining.removeWhere((x) => x.id == c.id);
            }
          }
        }

        // Check for pure sequences in remaining
        final suits = [Suit.S, Suit.H, Suit.D, Suit.C];
        for (final suit in suits) {
          if (combinations.length >= 3) break;
          final suitCards = remaining.where((c) => c.suit == suit).toList();
          for (int i = 0; i < suitCards.length; i++) {
            for (int j = i + 1; j < suitCards.length; j++) {
              for (int k = j + 1; k < suitCards.length; k++) {
                final trio = [suitCards[i], suitCards[j], suitCards[k]];
                if (MarriageMeldSlot.isPureSequence(trio) && combinations.length < 3) {
                  combinations.add(trio);
                  for (final c in trio) {
                    remaining.removeWhere((x) => x.id == c.id);
                  }
                  break;
                }
              }
              if (combinations.length >= 3) break;
            }
            if (combinations.length >= 3) break;
          }
        }

        // Assign to slots
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
    setState(() {
      isMaalSeen = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('marriage.maal_seen_desc'.tr()),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _onDeclare() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('marriage.declare'.tr()),
        content: Text('marriage.finish_success'.tr()),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('actions.confirm'.tr()),
          ),
        ],
      ),
    );
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
    final specialInfo = SpecialCardsInfo.fromMaal(cutJoker);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Semantics(
                    button: true,
                    label: 'marriage.leave'.tr(),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                      onPressed: () => _showLeaveConfirm(context),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
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
                    ),
                  ),
                  // Maal Status Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: isMaalSeen
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                        color: isMaalSeen ? colorScheme.primary : colorScheme.outlineVariant,
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
                  Semantics(
                    button: true,
                    label: 'marriage.game_rules'.tr(),
                    child: IconButton(
                      icon: Icon(Icons.help_outline, color: colorScheme.onSurface),
                      onPressed: () => _showRulesDialog(context),
                    ),
                  ),
                ],
              ),
            ),

            // Main Table & Center Area
            Expanded(
              child: Stack(
                children: [
                  // Seats
                  Positioned(
                    top: 8.0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: SeatWidget(
                        displayName: 'Bot 2',
                        isBot: true,
                        isCurrentTurn: currentTurnSeat == 2,
                        statusText: isMaalSeen
                            ? 'marriage.seen'.tr()
                            : 'marriage.unseen'.tr(),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16.0,
                    top: 48.0,
                    child: SeatWidget(
                      displayName: 'Bot 1',
                      isBot: true,
                      isCurrentTurn: currentTurnSeat == 1,
                      statusText: isMaalSeen
                          ? 'marriage.seen'.tr()
                          : 'marriage.unseen'.tr(),
                    ),
                  ),
                  Positioned(
                    right: 16.0,
                    top: 48.0,
                    child: SeatWidget(
                      displayName: 'Bot 3',
                      isBot: true,
                      isCurrentTurn: currentTurnSeat == 3,
                      statusText: isMaalSeen
                          ? 'marriage.seen'.tr()
                          : 'marriage.unseen'.tr(),
                    ),
                  ),

                  // Center Stock, Discard, Cut Joker (Maal)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Stock pile
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'table.stock'.tr(),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4.0),
                                PlayingCardWidget(
                                  card: stockPile.isNotEmpty
                                      ? stockPile.last
                                      : cutJoker,
                                  isFaceDown: true,
                                  isLegal: currentTurnSeat == 0 && turnPhase == 'draw',
                                  badgeText: '${stockPile.length}',
                                  onTap: _onDrawStock,
                                ),
                              ],
                            ),
                            const SizedBox(width: 16.0),
                            // Discard pile
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'table.discard_pile'.tr(),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4.0),
                                DragTarget<Card>(
                                  onAcceptWithDetails: (details) =>
                                      _onDiscardCard(details.data),
                                  builder: (context, _, __) => PlayingCardWidget(
                                    card: discardPile.isNotEmpty
                                        ? discardPile.last
                                        : cutJoker,
                                    isLegal: currentTurnSeat == 0 && turnPhase == 'draw',
                                    onTap: _onDrawDiscard,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16.0),
                            // Cut Joker (Tiplu)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'marriage.tiplu'.tr(),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4.0),
                                PlayingCardWidget(
                                  card: cutJoker,
                                  isFaceDown: !isMaalSeen,
                                  badgeText: isMaalSeen
                                      ? 'marriage.tiplu'.tr()
                                      : 'table.maal_unseen'.tr(),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // When Maal is seen: Show Special Cards Banner (Poplu, Jhiplu, Alter)
                        if (isMaalSeen) ...[
                          const SizedBox(height: 8.0),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(color: colorScheme.outlineVariant),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${'marriage.special_cards'.tr()}: ',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4.0),
                                _buildMiniCardChip(context, specialInfo.poplu, 'marriage.poplu'.tr()),
                                const SizedBox(width: 6.0),
                                _buildMiniCardChip(context, specialInfo.jhiplu, 'marriage.jhiplu'.tr()),
                                const SizedBox(width: 6.0),
                                _buildMiniCardChip(context, specialInfo.alter, 'marriage.alter'.tr()),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
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
                            : 'marriage.cards_in_hand'.tr(args: ['${myHand.length}']),
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
                          fontWeight: currentTurnSeat == 0 ? FontWeight.bold : FontWeight.normal,
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
                              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
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
                          if (currentTurnSeat == 0 && turnPhase == 'discard') ...[
                            const SizedBox(width: 8.0),
                            Semantics(
                              button: true,
                              label: 'marriage.discard'.tr(),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: colorScheme.error,
                                    foregroundColor: colorScheme.onError,
                                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
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

  Widget _buildMiniCardChip(BuildContext context, Card card, String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isRed = card.suit == Suit.H || card.suit == Suit.D;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
          Text(
            '${_rankToString(card.rank)}${_suitToSymbol(card.suit)}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: isRed ? colorScheme.error : colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _rankToString(int rank) {
    switch (rank) {
      case 1:
        return 'A';
      case 11:
        return 'J';
      case 12:
        return 'Q';
      case 13:
        return 'K';
      default:
        return '$rank';
    }
  }

  String _suitToSymbol(Suit suit) {
    switch (suit) {
      case Suit.S:
        return '♠';
      case Suit.H:
        return '♥';
      case Suit.D:
        return '♦';
      case Suit.C:
        return '♣';
      case Suit.X:
        return '★';
    }
  }

  void _showLeaveConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('marriage.leave'.tr()),
        content: Text('marriage.leave_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('marriage.stay'.tr()),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text('marriage.leave'.tr()),
          ),
        ],
      ),
    );
  }

  void _showRulesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('marriage.game_rules'.tr()),
        content: Text('marriage.rules_summary'.tr()),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('actions.confirm'.tr()),
          ),
        ],
      ),
    );
  }
}
