import 'dart:async';
import 'package:flutter/material.dart' hide Card;
import 'package:patii_engine/patii_engine.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/card_hand.dart';
import '../../../core/widgets/player_seat.dart';
import '../../../core/widgets/stacked_deck.dart';
import '../../../core/widgets/table_shell.dart';
import '../../../core/widgets/toast_banner.dart';

/// Jutpatti Casino Table Screen (Landscape).
/// Classical Nepali pair-making game.
/// Features:
/// - Screen locked to landscape via TableShell
/// - Elliptical 2-4 player seating
/// - Stock & Discard pile in center felt
/// - Pairs ("Jodi") tray and remaining hand cards
/// - Declare victory when all cards are paired
class JutpattiTableScreen extends StatefulWidget {
  const JutpattiTableScreen({super.key});

  @override
  State<JutpattiTableScreen> createState() => _JutpattiTableScreenState();
}

class _JutpattiTableScreenState extends State<JutpattiTableScreen> {
  int currentRound = 1;
  int currentTurnSeat = 0; // 0: You, 1: Bot 1
  String turnPhase = 'draw'; // 'draw' | 'discard'
  int pot = 300;
  String? selectedCardId;
  Timer? _botTimer;

  List<Card> stockPile = [
    const Card(suit: Suit.S, rank: 9, deck: 0, id: '9S1'),
    const Card(suit: Suit.H, rank: 4, deck: 0, id: '4H1'),
    const Card(suit: Suit.D, rank: 11, deck: 0, id: 'JD1'),
    const Card(suit: Suit.C, rank: 7, deck: 0, id: '7C1'),
    const Card(suit: Suit.H, rank: 12, deck: 0, id: 'QH1'),
    const Card(suit: Suit.D, rank: 9, deck: 0, id: '9D1'),
    const Card(suit: Suit.C, rank: 4, deck: 0, id: '4C1'),
    const Card(suit: Suit.S, rank: 11, deck: 0, id: 'JS1'),
    const Card(suit: Suit.D, rank: 7, deck: 0, id: '7D1'),
    const Card(suit: Suit.C, rank: 10, deck: 0, id: '10C1'),
    const Card(suit: Suit.D, rank: 12, deck: 0, id: 'QD1'),
    const Card(suit: Suit.S, rank: 3, deck: 0, id: '3S1'),
    const Card(suit: Suit.H, rank: 3, deck: 0, id: '3H1'),
  ];

  List<Card> discardPile = [
    const Card(suit: Suit.H, rank: 10, deck: 0, id: '10H0'),
  ];

  List<Card> myHand = [
    const Card(suit: Suit.S, rank: 5, deck: 0, id: '5S0'),
    const Card(suit: Suit.H, rank: 5, deck: 0, id: '5H0'), // Pair 1
    const Card(suit: Suit.D, rank: 8, deck: 0, id: '8D0'),
    const Card(suit: Suit.C, rank: 8, deck: 0, id: '8C0'), // Pair 2
    const Card(suit: Suit.S, rank: 12, deck: 0, id: 'QS0'), // Single
  ];

  int get pairsCount {
    final rankCounts = <int, int>{};
    for (final c in myHand) {
      rankCounts[c.rank] = (rankCounts[c.rank] ?? 0) + 1;
    }
    int pairs = 0;
    for (final count in rankCounts.values) {
      pairs += count ~/ 2;
    }
    return pairs;
  }

  bool get canDeclare =>
      myHand.length % 2 == 0 && (pairsCount * 2 == myHand.length);

  @override
  void dispose() {
    _botTimer?.cancel();
    super.dispose();
  }

  void _ensureStockNotEmpty() {
    if (stockPile.length <= 2 && discardPile.length > 1) {
      final top = discardPile.removeLast();
      final recycled = List<Card>.from(discardPile)..shuffle();
      discardPile = [top];
      stockPile.insertAll(0, recycled);
    }
  }

  void _onDrawStock() {
    _ensureStockNotEmpty();
    if (currentTurnSeat != 0 || turnPhase != 'draw' || stockPile.isEmpty) {
      return;
    }
    AudioService.instance.playCardSlide();
    setState(() {
      final drawn = stockPile.removeLast();
      myHand.add(drawn);
      turnPhase = 'discard';
      selectedCardId = drawn.id;
    });
    ToastBanner.show(context, 'Select a card to discard',
        icon: Icons.touch_app);
  }

  void _onDrawDiscard() {
    if (currentTurnSeat != 0 || turnPhase != 'draw' || discardPile.isEmpty) {
      return;
    }
    AudioService.instance.playCardSlide();
    setState(() {
      final drawn = discardPile.removeLast();
      myHand.add(drawn);
      turnPhase = 'discard';
      selectedCardId = drawn.id;
    });
    ToastBanner.show(context, 'Select a card to discard',
        icon: Icons.touch_app);
  }

  void _onDiscardCard(Card card) {
    if (currentTurnSeat != 0 || turnPhase != 'discard') return;
    AudioService.instance.playCardSnap();
    setState(() {
      myHand.removeWhere((c) => c.id == card.id);
      discardPile.add(card);
      selectedCardId = null;
      turnPhase = 'draw';
      currentTurnSeat = 1;
    });

    _botTimer?.cancel();
    _botTimer = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _ensureStockNotEmpty();
      if (stockPile.isNotEmpty) {
        discardPile.add(stockPile.removeAt(0));
      }
      AudioService.instance.playCardSlide();
      setState(() {
        currentTurnSeat = 0;
        turnPhase = 'draw';
      });
      ToastBanner.show(context, 'Your turn to draw', icon: Icons.touch_app);
    });
  }

  void _onDeclare() {
    AudioService.instance.playWinJingle();
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
              'JUTPATTI WIN!',
              style: PatiiTypography.display(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: PatiiColors.goldLight,
              ),
            ),
          ],
        ),
        content: Text(
          'All your cards are paired into Jodis!\n\n'
          '🎉 You won the round and 300 coins!',
          style: PatiiTypography.body(
              fontSize: 14, color: PatiiColors.textPrimary),
        ),
        actions: [
          GoldButton(
            label: 'Collect 300',
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
          'Jutpatti Rules',
          style: PatiiTypography.display(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: PatiiColors.goldLight,
          ),
        ),
        content: Text(
          '• Fast-paced Nepali 2-4 player game.\n'
          '• Form pairs ("Jodi") of cards with the same rank.\n'
          '• Draw 1 card from Stock or Discard, then discard 1.\n'
          '• First player to pair all cards declares and wins!',
          style: PatiiTypography.body(
            fontSize: 13,
            color: PatiiColors.textPrimary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Got it',
                style: PatiiTypography.display(color: PatiiColors.gold)),
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
      gameTitle: 'Jutpatti',
      roundInfo: 'Round $currentRound · Pot $pot',
      pot: pot,
      onRulesTap: _showRulesDialog,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth = constraints.maxWidth;
          final tableHeight = constraints.maxHeight;

          return Stack(
            children: [
              // 1. Opponent (Bot 1, North)
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: PlayerSeat(
                    displayName: 'Bot 1',
                    isBot: true,
                    isCurrentTurn: currentTurnSeat == 1,
                    infoPillText: '5 cards · 2 Pairs',
                  ),
                ),
              ),

              // 2. Center Table: Stock & Discard
              Positioned(
                left: 0,
                right: 0,
                top: (tableHeight - 150) / 2,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Stock Pile (Physical 3D stacked deck)
                      StackedDeck(
                        topCard: const Card(
                            suit: Suit.S, rank: 1, deck: 0, id: 'back'),
                        isFaceDown: true,
                        cardCount: stockPile.length,
                        width: 48,
                        height: 68,
                        label: 'STOCK',
                        isInteractive: isMyTurn && turnPhase == 'draw',
                        onTap: isMyTurn && turnPhase == 'draw'
                            ? _onDrawStock
                            : null,
                      ),
                      const SizedBox(width: 20),

                      // Discard Pile (Layered discard stack)
                      StackedDeck(
                        topCard: discardPile.isNotEmpty ? discardPile.last : null,
                        isFaceDown: false,
                        cardCount: discardPile.length,
                        width: 48,
                        height: 68,
                        label: 'DISCARD',
                        spreadDiscard: true,
                        isInteractive: isMyTurn &&
                            turnPhase == 'draw' &&
                            discardPile.isNotEmpty,
                        onTap: isMyTurn &&
                                turnPhase == 'draw' &&
                                discardPile.isNotEmpty
                            ? _onDrawDiscard
                            : null,
                      ),
                    ],
                  ),
                ),
              ),

              // 3. You (Bottom Left PlayerSeat)
              Positioned(
                left: 16,
                bottom: 8,
                child: PlayerSeat(
                  displayName: 'You',
                  isBot: false,
                  isCurrentTurn: isMyTurn,
                  infoPillText: '$pairsCount Pairs',
                ),
              ),

              // 4. Center Bottom: Hand Cards Fan
              Positioned(
                left: 110,
                right: tableWidth < 700 ? 110 : 150,
                bottom: 8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pairs status pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: PatiiColors.navySurface.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: PatiiColors.goldDark.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'Pairs: $pairsCount / ${myHand.length ~/ 2}',
                        style: PatiiTypography.display(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: PatiiColors.goldLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Cards Fan with Jodi Pair Badges
                    CardHand(
                      cards: myHand,
                      selectedCardId: selectedCardId,
                      cardWidth: 56,
                      cardHeight: 80,
                      maxArcDegrees: 6,
                      cardBadgeBuilder: (card) {
                        final count = myHand.where((c) => c.rank == card.rank).length;
                        return count >= 2 ? 'JODI' : null;
                      },
                      onCardTap: (card) {
                        setState(() {
                          selectedCardId =
                              selectedCardId == card.id ? null : card.id;
                        });
                      },
                      onCardPlay: (card) {
                        if (isMyTurn && turnPhase == 'discard') {
                          _onDiscardCard(card);
                        }
                      },
                    ),
                  ],
                ),
              ),

              // 5. Actions on Right Bottom
              Positioned(
                right: 16,
                bottom: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (canDeclare)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: GoldButton(
                          label: 'Declare Jodi!',
                          icon: Icons.emoji_events,
                          height: 42,
                          onPressed: _onDeclare,
                        ),
                      ),
                    if (isMyTurn &&
                        turnPhase == 'discard' &&
                        selectedCard != null)
                      DangerButton(
                        label: 'Discard',
                        icon: Icons.arrow_upward,
                        height: 40,
                        onPressed: () => _onDiscardCard(selectedCard),
                      ),
                    if (isMyTurn && turnPhase == 'draw')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: PatiiColors.goldDark.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: PatiiColors.gold, width: 0.8),
                        ),
                        child: Text(
                          'Draw 1 card',
                          style: PatiiTypography.caption(
                              color: PatiiColors.goldLight, bold: true),
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
