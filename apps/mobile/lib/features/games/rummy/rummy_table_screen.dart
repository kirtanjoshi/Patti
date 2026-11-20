import 'package:flutter/material.dart' hide Card;
import 'package:patii_engine/patii_engine.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/card_hand.dart';
import '../../../core/widgets/player_seat.dart';
import '../../../core/widgets/playing_card.dart';
import '../../../core/widgets/table_shell.dart';
import '../../../core/widgets/toast_banner.dart';

/// Casino-Style Rummy & Joker Rummy Table Screen (Landscape).
/// Features:
/// - Screen locked to landscape via TableShell
/// - 4-player seating around table felt
/// - Stock, Discard, and Wild Joker card (when Joker Rummy)
/// - Overlapping 13-card hand fan that dynamically fits screen width
/// - Sort (by Suit / Rank), Discard, and Declare actions
class RummyTableScreen extends StatefulWidget {
  final bool isJokerVariant;

  const RummyTableScreen({
    super.key,
    this.isJokerVariant = false,
  });

  @override
  State<RummyTableScreen> createState() => _RummyTableScreenState();
}

class _RummyTableScreenState extends State<RummyTableScreen> {
  int currentRound = 1;
  int currentTurnSeat = 0; // 0: You, 1: Bot 1, 2: Bot 2, 3: Bot 3
  String turnPhase = 'draw'; // 'draw' | 'discard'
  int pot = 600;
  String? selectedCardId;
  bool isSortedBySuit = true;

  // Joker Card (for Joker Rummy)
  final Card cutJoker = const Card(suit: Suit.C, rank: 8, deck: 0, id: '8C_cut');

  List<Card> stockPile = [
    const Card(suit: Suit.S, rank: 5, deck: 0, id: '5S1'),
    const Card(suit: Suit.H, rank: 9, deck: 0, id: '9H1'),
    const Card(suit: Suit.D, rank: 2, deck: 0, id: '2D1'),
    const Card(suit: Suit.C, rank: 11, deck: 0, id: 'JC1'),
  ];

  List<Card> discardPile = [
    const Card(suit: Suit.H, rank: 4, deck: 0, id: '4H0'),
  ];

  List<Card> myHand = [
    const Card(suit: Suit.S, rank: 1, deck: 0, id: 'AS0'),
    const Card(suit: Suit.S, rank: 2, deck: 0, id: '2S0'),
    const Card(suit: Suit.S, rank: 3, deck: 0, id: '3S0'), // Pure Sequence 1
    const Card(suit: Suit.H, rank: 10, deck: 0, id: '10H0'),
    const Card(suit: Suit.H, rank: 11, deck: 0, id: 'JH0'),
    const Card(suit: Suit.H, rank: 12, deck: 0, id: 'QH0'), // Sequence 2
    const Card(suit: Suit.D, rank: 7, deck: 0, id: '7D0'),
    const Card(suit: Suit.C, rank: 7, deck: 0, id: '7C0'),
    const Card(suit: Suit.S, rank: 7, deck: 0, id: '7S0'), // Set 1
    const Card(suit: Suit.D, rank: 13, deck: 0, id: 'KD0'),
    const Card(suit: Suit.C, rank: 13, deck: 0, id: 'KC0'),
    const Card(suit: Suit.H, rank: 13, deck: 0, id: 'KH0'), // Set 2
    const Card(suit: Suit.C, rank: 4, deck: 0, id: '4C0'), // Unmatched
  ];

  void _onDrawStock() {
    if (currentTurnSeat != 0 || turnPhase != 'draw' || stockPile.isEmpty) return;
    setState(() {
      final drawn = stockPile.removeLast();
      myHand.add(drawn);
      turnPhase = 'discard';
      selectedCardId = drawn.id;
    });
    ToastBanner.show(context, 'Discard 1 card to end turn', icon: Icons.arrow_upward);
  }

  void _onDrawDiscard() {
    if (currentTurnSeat != 0 || turnPhase != 'draw' || discardPile.isEmpty) return;
    setState(() {
      final drawn = discardPile.removeLast();
      myHand.add(drawn);
      turnPhase = 'discard';
      selectedCardId = drawn.id;
    });
    ToastBanner.show(context, 'Discard 1 card to end turn', icon: Icons.arrow_upward);
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
            ToastBanner.show(context, 'Your turn to draw', icon: Icons.touch_app);
          });
        });
      });
    });
  }

  void _toggleSort() {
    setState(() {
      isSortedBySuit = !isSortedBySuit;
      if (isSortedBySuit) {
        myHand.sort((a, b) {
          final suitCmp = a.suit.index.compareTo(b.suit.index);
          return suitCmp != 0 ? suitCmp : a.rank.compareTo(b.rank);
        });
      } else {
        myHand.sort((a, b) {
          final rankCmp = a.rank.compareTo(b.rank);
          return rankCmp != 0 ? rankCmp : a.suit.index.compareTo(b.suit.index);
        });
      }
    });
  }

  void _onDeclare() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PatiiColors.navyElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: PatiiColors.gold, width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.emoji_events, color: PatiiColors.gold),
            const SizedBox(width: 8),
            Text(
              'RUMMY SHOW!',
              style: PatiiTypography.display(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: PatiiColors.goldLight,
              ),
            ),
          ],
        ),
        content: Text(
          'Valid declaration with Pure Sequence, Sequences & Sets!\n\n'
          '🎉 YOU WIN 600 COINS!',
          style: PatiiTypography.body(fontSize: 14, color: PatiiColors.textPrimary),
        ),
        actions: [
          GoldButton(
            label: 'Collect 600',
            height: 40,
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showRulesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PatiiColors.navyElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: PatiiColors.hairline),
        ),
        title: Text(
          widget.isJokerVariant ? 'Joker Rummy Rules' : 'Classic Rummy Rules',
          style: PatiiTypography.display(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: PatiiColors.goldLight,
          ),
        ),
        content: Text(
          '• 13 cards dealt to each player.\n'
          '• Must make at least 1 Pure Sequence (no joker).\n'
          '${widget.isJokerVariant ? "• The cut Joker can substitute any card in impure sequences & sets.\n" : ""}'
          '• Arrange all cards into valid sequences & sets to Declare.',
          style: PatiiTypography.body(
            fontSize: 13,
            color: PatiiColors.textPrimary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Got it', style: PatiiTypography.display(color: PatiiColors.gold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMyTurn = currentTurnSeat == 0;
    final selectedCard = selectedCardId != null
        ? myHand.where((c) => c.id == selectedCardId).firstOrNull
        : null;

    return TableShell(
      gameTitle: widget.isJokerVariant ? 'Joker Rummy' : 'Rummy',
      roundInfo: 'Round $currentRound · Pot $pot',
      pot: pot,
      onRulesTap: _showRulesDialog,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth = constraints.maxWidth;
          final tableHeight = constraints.maxHeight;

          return Stack(
            children: [
              // 1. Top Opponent (Bot 2, North)
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: PlayerSeat(
                    displayName: 'Bot 2',
                    isBot: true,
                    isCurrentTurn: currentTurnSeat == 2,
                    infoPillText: '13 cards',
                  ),
                ),
              ),

              // 2. Left Opponent (Bot 1, West)
              Positioned(
                left: 12,
                top: (tableHeight - 160) / 2,
                child: PlayerSeat(
                  displayName: 'Bot 1',
                  isBot: true,
                  isCurrentTurn: currentTurnSeat == 1,
                  infoPillText: '13 cards',
                ),
              ),

              // 3. Right Opponent (Bot 3, East)
              Positioned(
                right: 12,
                top: (tableHeight - 160) / 2,
                child: PlayerSeat(
                  displayName: 'Bot 3',
                  isBot: true,
                  isCurrentTurn: currentTurnSeat == 3,
                  infoPillText: '13 cards',
                ),
              ),

              // 4. Center Area: Stock, Discard, and Cut Joker
              Positioned(
                left: 0,
                right: 0,
                top: (tableHeight - 150) / 2,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Stock Pile
                      GestureDetector(
                        onTap: isMyTurn && turnPhase == 'draw' ? _onDrawStock : null,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            PlayingCard.table(
                              card: const Card(suit: Suit.S, rank: 1, deck: 0, id: 'back'),
                              isFaceDown: true,
                              width: 48,
                              height: 68,
                            ),
                            Positioned(
                              bottom: -6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: PatiiColors.navy.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: PatiiColors.goldDark, width: 0.8),
                                ),
                                child: Text(
                                  '${stockPile.length}',
                                  style: PatiiTypography.caption(color: PatiiColors.goldLight, bold: true),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Discard Pile
                      GestureDetector(
                        onTap: isMyTurn && turnPhase == 'draw' && discardPile.isNotEmpty
                            ? _onDrawDiscard
                            : null,
                        child: discardPile.isEmpty
                            ? Container(
                                width: 48,
                                height: 68,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                ),
                              )
                            : PlayingCard.table(
                                card: discardPile.last,
                                width: 48,
                                height: 68,
                              ),
                      ),

                      // Cut Joker (if Joker Rummy variant)
                      if (widget.isJokerVariant) ...[
                        const SizedBox(width: 16),
                        PlayingCard.table(
                          card: cutJoker,
                          width: 48,
                          height: 68,
                          badgeText: 'JOKER',
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // 5. You (Bottom Left PlayerSeat)
              Positioned(
                left: 16,
                bottom: 8,
                child: PlayerSeat(
                  displayName: 'You',
                  isBot: false,
                  isCurrentTurn: isMyTurn,
                  infoPillText: '${myHand.length} cards',
                ),
              ),

              // 6. Center Bottom: 13-Card Hand Fan
              Positioned(
                left: 110,
                right: tableWidth < 700 ? 120 : 160,
                bottom: -12,
                child: CardHand(
                  cards: myHand,
                  selectedCardId: selectedCardId,
                  wildOrMaalCardId: widget.isJokerVariant ? cutJoker.id : null,
                  cardWidth: 54,
                  cardHeight: 78,
                  maxArcDegrees: 8,
                  onCardTap: (card) {
                    setState(() {
                      selectedCardId = selectedCardId == card.id ? null : card.id;
                    });
                  },
                  onCardPlay: (card) {
                    if (isMyTurn && turnPhase == 'discard') {
                      _onDiscardCard(card);
                    }
                  },
                ),
              ),

              // 7. Right Bottom: Action Cluster
              Positioned(
                right: 16,
                bottom: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Declare Button
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: GoldButton(
                        label: 'Declare',
                        icon: Icons.emoji_events,
                        height: 38,
                        onPressed: _onDeclare,
                      ),
                    ),

                    // Sort Button
                    GhostButton(
                      label: isSortedBySuit ? 'Sort: Suit' : 'Sort: Rank',
                      icon: Icons.sort,
                      height: 36,
                      onPressed: _toggleSort,
                    ),
                    const SizedBox(height: 6),

                    // Discard Button
                    if (isMyTurn && turnPhase == 'discard' && selectedCard != null)
                      DangerButton(
                        label: 'Discard',
                        icon: Icons.arrow_upward,
                        height: 36,
                        onPressed: () => _onDiscardCard(selectedCard),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
