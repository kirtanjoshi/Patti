import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patii_engine/patii_engine.dart' as engine;
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/card_hand.dart';
import '../../../../core/widgets/player_seat.dart';
import '../../../../core/widgets/table_shell.dart';
import '../../../../core/widgets/toast_banner.dart';
import 'widgets/callbreak_bid_sheet.dart';
import 'widgets/callbreak_trick_area.dart';
import 'widgets/opponent_seat_panel.dart';

/// Redesigned Casino-Style Callbreak Table Screen (Landscape).
/// Features:
/// - Orientation locked to Landscape via TableShell
/// - Elliptical 4-player seating: You (bottom-left), Bot 1 (West), Bot 2 (North), Bot 3 (East)
/// - Center diamond trick area where cards sit toward the player who played them
/// - Overlapping 13-card hand fan that never overflows or gets cut off
/// - Single-row 1-8 bid selector floating above the hand with zero overlap
/// - Realistic trick capture animations and live trick counting
class CallbreakTableScreen extends ConsumerStatefulWidget {
  const CallbreakTableScreen({super.key});

  @override
  ConsumerState<CallbreakTableScreen> createState() =>
      _CallbreakTableScreenState();
}

class _CallbreakTableScreenState extends ConsumerState<CallbreakTableScreen> {
  int currentRound = 1;
  int currentTurnSeat = 0; // 0: You, 1: Bot 1, 2: Bot 2, 3: Bot 3
  String phase = 'bidding'; // 'bidding' | 'playing' | 'roundOver'
  int? myBid;
  int myTricksWon = 0;
  int bot1TricksWon = 0;
  int bot2TricksWon = 1;
  int? trickWinner;
  int bot3TricksWon = 0;
  String? selectedCardId;

  // 13 dealt cards for player 0 (You)
  List<engine.Card> myHand = [
    const engine.Card(suit: engine.Suit.S, rank: 1, deck: 0, id: 'AS0'),
    const engine.Card(suit: engine.Suit.S, rank: 12, deck: 0, id: 'QS0'),
    const engine.Card(suit: engine.Suit.S, rank: 7, deck: 0, id: '7S0'),
    const engine.Card(suit: engine.Suit.H, rank: 13, deck: 0, id: 'KH0'),
    const engine.Card(suit: engine.Suit.H, rank: 10, deck: 0, id: '10H0'),
    const engine.Card(suit: engine.Suit.H, rank: 5, deck: 0, id: '5H0'),
    const engine.Card(suit: engine.Suit.D, rank: 14, deck: 0, id: 'AD0'),
    const engine.Card(suit: engine.Suit.D, rank: 9, deck: 0, id: '9D0'),
    const engine.Card(suit: engine.Suit.D, rank: 3, deck: 0, id: '3D0'),
    const engine.Card(suit: engine.Suit.C, rank: 11, deck: 0, id: 'JC0'),
    const engine.Card(suit: engine.Suit.C, rank: 8, deck: 0, id: '8C0'),
    const engine.Card(suit: engine.Suit.C, rank: 6, deck: 0, id: '6C0'),
    const engine.Card(suit: engine.Suit.C, rank: 2, deck: 0, id: '2C0'),
  ];

  List<PlayedTrickCard> playedTrick = [];

  void _onBidConfirmed(int bid) {
    setState(() {
      myBid = bid;
      phase = 'playing';
      currentTurnSeat = 0; // Your turn to lead trick 1
    });
    ToastBanner.show(
      context,
      'Bid $bid placed! Your turn to lead.',
      icon: Icons.gavel,
    );
  }

  void _onPlayCard(engine.Card card) {
    if (phase != 'playing' || currentTurnSeat != 0) return;

    setState(() {
      myHand.removeWhere((c) => c.id == card.id);
      selectedCardId = null;
      playedTrick.add(PlayedTrickCard(seat: 0, card: card));
      currentTurnSeat = 1;
    });

    // Simulate bot responses in sequence
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        playedTrick.add(
          const PlayedTrickCard(
            seat: 1,
            card: engine.Card(suit: engine.Suit.H, rank: 4, deck: 0, id: '4H0'),
          ),
        );
        currentTurnSeat = 2;
      });

      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        setState(() {
          playedTrick.add(
            const PlayedTrickCard(
              seat: 2,
              card:
                  engine.Card(suit: engine.Suit.H, rank: 8, deck: 0, id: '8H0'),
            ),
          );
          currentTurnSeat = 3;
        });

        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          setState(() {
            playedTrick.add(
              const PlayedTrickCard(
                seat: 3,
                card: engine.Card(
                    suit: engine.Suit.S, rank: 2, deck: 0, id: '2S0'),
              ),
            );
          });

          // Conclude trick after 800ms
          Future.delayed(const Duration(milliseconds: 800), () {
            if (!mounted) return;
            _resolveTrick();
          });
        });
      });
    });
  }

  void _resolveTrick() {
    // Determine winner (Spades trump or highest rank)
    int winningSeat = 0;
    engine.Card bestCard = playedTrick.first.card;

    for (final pt in playedTrick) {
      if (pt.card.suit == engine.Suit.S && bestCard.suit != engine.Suit.S) {
        bestCard = pt.card;
        winningSeat = pt.seat;
      } else if (pt.card.suit == bestCard.suit && pt.card.rank > bestCard.rank) {
        bestCard = pt.card;
        winningSeat = pt.seat;
      }
    }

    // Show the sweep toward the winner, then score and clear.
    setState(() => trickWinner = winningSeat);
    final winnerName = winningSeat == 0 ? 'You' : 'Bot $winningSeat';
    ToastBanner.show(
      context,
      '$winnerName won the trick!',
      icon: Icons.emoji_events,
    );

    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      setState(() {
        if (winningSeat == 0) {
          myTricksWon++;
        } else if (winningSeat == 1) {
          bot1TricksWon++;
        } else if (winningSeat == 2) {
          bot2TricksWon++;
        } else {
          bot3TricksWon++;
        }
        playedTrick.clear();
        trickWinner = null;
        currentTurnSeat = winningSeat;
      });
    });
  }

  void _showRulesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PatiiColors.navyElevated,
        shape: RoundedRectangleBorder(
          borderRadius: PatiiSpacing.rounded16,
          side: const BorderSide(color: PatiiColors.hairline),
        ),
        title: Row(
          children: [
            const Icon(Icons.style, color: PatiiColors.gold),
            const SizedBox(width: 8),
            Text(
              'Callbreak Rules',
              style: PatiiTypography.display(
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
              '• 4 players, 13 cards each, 5 rounds total.\n'
              '• Spades (♠) are permanent trumps.\n'
              '• Must follow lead suit if possible; otherwise must play a spade.\n'
              '• Win at least as many tricks as your bid to score positive points.',
              style: PatiiTypography.body(
                fontSize: 13,
                color: PatiiColors.textPrimary,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PatiiColors.gold,
              foregroundColor: PatiiColors.navy,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMyTurn = phase == 'playing' && currentTurnSeat == 0;
    final playableIds = isMyTurn
        ? myHand.map((c) => c.id).toSet()
        : const <String>{};

    return TableShell(
      gameTitle: 'Callbreak',
      roundInfo: '${'table.round'.tr()} $currentRound / 5',
      trumpSuit: 'Spades',
      pot: 400,
      onRulesTap: () => _showRulesDialog(context),
      child: Stack(
        children: [
          // 1. Top Opponent (Seat 2, Bot 2, North)
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: OpponentSeatPanel(
                displayName: 'Bot 2',
                bid: 3,
                tricksWon: bot2TricksWon,
                cardCount: 13 - playedTrick.length,
                isCurrentTurn: currentTurnSeat == 2,
                isDealer: true,
              ),
            ),
          ),

          // 2. Left Opponent (Seat 1, Bot 1, West)
          Positioned(
            left: 14,
            top: 40,
            bottom: 70,
            child: Center(
              child: OpponentSeatPanel(
                displayName: 'Bot 1',
                bid: 2,
                tricksWon: bot1TricksWon,
                cardCount: 13 - playedTrick.length,
                isCurrentTurn: currentTurnSeat == 1,
              ),
            ),
          ),

          // 3. Right Opponent (Seat 3, Bot 3, East)
          Positioned(
            right: 14,
            top: 40,
            bottom: 70,
            child: Center(
              child: OpponentSeatPanel(
                displayName: 'Bot 3',
                stackOnLeft: true,
                bid: 4,
                tricksWon: bot3TricksWon,
                cardCount: 13 - playedTrick.length,
                isCurrentTurn: currentTurnSeat == 3,
              ),
            ),
          ),

          // 4. Center Diamond Trick Area
          Positioned.fill(
            child: Center(
              child: CallbreakTrickArea(
                playedCards: playedTrick,
                phase: phase,
                currentTurnSeat: currentTurnSeat,
                winningSeat: trickWinner,
              ),
            ),
          ),

          // 5. You Seat (Seat 0, South) - Positioned bottom-left, clear of cards
          Positioned(
            left: 14,
            bottom: 8,
            child: PlayerSeat(
              displayName: 'You',
              isCurrentTurn: isMyTurn,
              infoPillText: myBid != null
                  ? '$myTricksWon / $myBid tricks'
                  : '$myTricksWon tricks',
              remainingSeconds: isMyTurn ? 12 : 15,
            ),
          ),

          // 6. 13-Card Hand Overlapping Fan (Bottom Center)
          Positioned(
            bottom: -16,
            left: 104,
            right: 24,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 118),
                child: CardHand(
                  cards: myHand,
                  selectedCardId: selectedCardId,
                  playableCardIds: playableIds,
                  cardWidth: 60,
                  cardHeight: 86,
                  onCardTap: (card) {
                    if (isMyTurn) {
                      setState(() {
                        selectedCardId = card.id;
                      });
                    }
                  },
                  onCardPlay: _onPlayCard,
                ),
              ),
            ),
          ),

          // 7. Single-Row Bidding Sheet (Bids 1 to 8) - Floats strictly above the hand
          if (phase == 'bidding')
            Positioned(
              bottom: 104,
              left: 40,
              right: 40,
              child: Center(
                child: CallbreakBidSheet(
                  initialBid: 2,
                  onBidConfirmed: _onBidConfirmed,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
