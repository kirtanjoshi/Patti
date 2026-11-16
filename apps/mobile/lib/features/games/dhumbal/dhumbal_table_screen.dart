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

/// Dhumbal (Jhyap) Casino Table Screen (Landscape).
/// Features:
/// - Screen locked to landscape via TableShell
/// - 4 players distributed around the table felt (You at bottom-center)
/// - Center Table Area: Stock pile & Discard pile
/// - Live "Hand Total" chip (sum of card values in hand)
/// - Prominent "JHYAP!" Crimson-Gold Button appears when hand total <= 5
/// - Drag-up or tap to throw cards, draw from stock or discard
class DhumbalTableScreen extends StatefulWidget {
  const DhumbalTableScreen({super.key});

  @override
  State<DhumbalTableScreen> createState() => _DhumbalTableScreenState();
}

class _DhumbalTableScreenState extends State<DhumbalTableScreen> {
  static const int jhyapThreshold = 5;

  int currentRound = 1;
  int currentTurnSeat = 0; // 0: You, 1: Bot 1, 2: Bot 2, 3: Bot 3
  String turnPhase = 'throw'; // 'throw' | 'draw'
  int pot = 400;
  bool isGameOver = false;

  final Set<String> selectedForThrow = {};

  List<Card> stockPile = [
    const Card(suit: Suit.S, rank: 3, deck: 0, id: '3S1'),
    const Card(suit: Suit.H, rank: 7, deck: 0, id: '7H1'),
    const Card(suit: Suit.D, rank: 9, deck: 0, id: '9D1'),
    const Card(suit: Suit.C, rank: 2, deck: 0, id: '2C1'),
    const Card(suit: Suit.S, rank: 8, deck: 0, id: '8S1'),
    const Card(suit: Suit.H, rank: 1, deck: 0, id: 'AH1'),
  ];

  List<Card> discardPile = [
    const Card(suit: Suit.D, rank: 8, deck: 0, id: '8D0'),
  ];

  List<Card> myHand = [
    const Card(suit: Suit.S, rank: 1, deck: 0, id: 'AS0'), // 1
    const Card(suit: Suit.H, rank: 2, deck: 0, id: '2H0'), // 2
    const Card(suit: Suit.C, rank: 2, deck: 0, id: '2C0'), // 2
    const Card(suit: Suit.D, rank: 4, deck: 0, id: '4D0'), // 4
    const Card(suit: Suit.S, rank: 10, deck: 0, id: '10S0'), // 10
  ];

  int _cardValue(Card card) {
    if (card.rank >= 1 && card.rank <= 13) return card.rank;
    return 10;
  }

  int get handTotal {
    return myHand.fold<int>(0, (sum, card) => sum + _cardValue(card));
  }

  bool get canCallJhyap => handTotal <= jhyapThreshold && currentTurnSeat == 0 && turnPhase == 'throw';

  void _onCardTap(Card card) {
    if (currentTurnSeat != 0 || turnPhase != 'throw') return;
    setState(() {
      if (selectedForThrow.contains(card.id)) {
        selectedForThrow.remove(card.id);
      } else {
        selectedForThrow.add(card.id);
      }
    });
  }

  void _onThrowSelected() {
    if (selectedForThrow.isEmpty || currentTurnSeat != 0 || turnPhase != 'throw') return;

    final thrownCards = myHand.where((c) => selectedForThrow.contains(c.id)).toList();
    setState(() {
      myHand.removeWhere((c) => selectedForThrow.contains(c.id));
      discardPile.addAll(thrownCards);
      selectedForThrow.clear();
      turnPhase = 'draw';
    });
    ToastBanner.show(context, 'Draw 1 card from Stock or Discard', icon: Icons.touch_app);
  }

  void _onDrawStock() {
    if (currentTurnSeat != 0 || turnPhase != 'draw' || stockPile.isEmpty) return;
    setState(() {
      final drawn = stockPile.removeLast();
      myHand.add(drawn);
      turnPhase = 'throw';
      currentTurnSeat = 1;
      _runBotTurns();
    });
  }

  void _onDrawDiscard() {
    if (currentTurnSeat != 0 || turnPhase != 'draw' || discardPile.isEmpty) return;
    setState(() {
      final drawn = discardPile.removeLast();
      myHand.add(drawn);
      turnPhase = 'throw';
      currentTurnSeat = 1;
      _runBotTurns();
    });
  }

  void _onCallJhyap() {
    if (!canCallJhyap) return;
    setState(() {
      isGameOver = true;
    });

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
            const Icon(Icons.flash_on, color: PatiiColors.gold),
            const SizedBox(width: 8),
            Text(
              'JHYAP! Showdown',
              style: PatiiTypography.cinzel(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: PatiiColors.goldLight,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You called Jhyap with total $handTotal!\n\n'
              '• You: $handTotal pts\n'
              '• Bot 1: 18 pts\n'
              '• Bot 2: 12 pts\n'
              '• Bot 3: 15 pts\n\n'
              '🎉 YOU WIN THE POT OF 400 COINS!',
              style: PatiiTypography.poppins(
                fontSize: 14,
                color: PatiiColors.textPrimary,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          GoldButton(
            label: 'Collect 400',
            icon: Icons.monetization_on,
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

  void _runBotTurns() {
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
            turnPhase = 'throw';
          });
          ToastBanner.show(context, 'Your turn! Select cards to throw', icon: Icons.touch_app);
        });
      });
    });
  }

  void _showRulesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PatiiColors.navyElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: PatiiColors.goldDark, width: 1.2),
        ),
        title: Text(
          'Dhumbal (Jhyap) Rules',
          style: PatiiTypography.cinzel(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: PatiiColors.goldLight,
          ),
        ),
        content: Text(
          '• 4 players, 5 cards each.\n'
          '• Card values: A=1, 2-10=face value, J=11, Q=12, K=13.\n'
          '• Throw 1 or more same-rank cards (or same-suit runs), then draw 1.\n'
          '• When your total is 5 or less, press "JHYAP!" to reveal hands.\n'
          '• Lowest total wins the pot!',
          style: PatiiTypography.poppins(
            fontSize: 13,
            color: PatiiColors.textPrimary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Got it', style: PatiiTypography.cinzel(color: PatiiColors.gold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMyTurn = currentTurnSeat == 0;

    return TableShell(
      gameTitle: 'Dhumbal',
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
                    infoPillText: '5 cards',
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
                  infoPillText: '5 cards',
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
                  infoPillText: '5 cards',
                ),
              ),

              // 4. Center Area: Stock Pile & Discard Pile
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
                      const SizedBox(width: 20),

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
                  infoPillText: 'Total: $handTotal',
                ),
              ),

              // 6. Center Bottom: Hand Cards Fan
              Positioned(
                left: 110,
                right: tableWidth < 700 ? 120 : 160,
                bottom: 8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Live Hand Total chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: canCallJhyap
                            ? PatiiColors.crimson.withValues(alpha: 0.85)
                            : PatiiColors.navySurface.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: canCallJhyap ? PatiiColors.gold : PatiiColors.goldDark.withValues(alpha: 0.4),
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        'Hand Total: $handTotal ${canCallJhyap ? "· JHYAP READY!" : ""}',
                        style: PatiiTypography.cinzel(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: canCallJhyap ? PatiiColors.goldLight : PatiiColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Cards Fan
                    CardHand(
                      cards: myHand,
                      selectedCardId: selectedForThrow.isNotEmpty ? selectedForThrow.first : null,
                      cardWidth: 54,
                      cardHeight: 78,
                      maxArcDegrees: 6,
                      onCardTap: _onCardTap,
                      onCardPlay: (card) {
                        setState(() {
                          selectedForThrow.add(card.id);
                        });
                        _onThrowSelected();
                      },
                    ),
                  ],
                ),
              ),

              // 7. Action Bar on Bottom Right
              Positioned(
                right: 16,
                bottom: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // JHYAP! Button (when total <= threshold)
                    if (canCallJhyap)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: DangerButton(
                          label: 'JHYAP!',
                          icon: Icons.flash_on,
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          onPressed: _onCallJhyap,
                        ),
                      ),

                    // Throw Selected Cards
                    if (isMyTurn && turnPhase == 'throw')
                      GoldButton(
                        label: 'Throw (${selectedForThrow.length})',
                        icon: Icons.arrow_upward,
                        height: 40,
                        isEnabled: selectedForThrow.isNotEmpty,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        onPressed: _onThrowSelected,
                      ),

                    // Draw Hint
                    if (isMyTurn && turnPhase == 'draw')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: PatiiColors.goldDark.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: PatiiColors.gold, width: 0.8),
                        ),
                        child: Text(
                          'Tap Stock or Discard',
                          style: PatiiTypography.caption(color: PatiiColors.goldLight, bold: true),
                        ),
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
