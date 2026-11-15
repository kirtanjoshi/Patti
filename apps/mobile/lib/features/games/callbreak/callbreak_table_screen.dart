import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patii_engine/patii_engine.dart' as engine;
import '../../table/widgets/playing_card_widget.dart';
import '../../table/widgets/seat_widget.dart';

class CallbreakTableScreen extends ConsumerStatefulWidget {
  const CallbreakTableScreen({super.key});

  @override
  ConsumerState<CallbreakTableScreen> createState() => _CallbreakTableScreenState();
}

class _CallbreakTableScreenState extends ConsumerState<CallbreakTableScreen> {
  // State for Wave 2 playable vertical slice UI
  int currentRound = 1;
  int currentTurnSeat = 0;
  String phase = 'bidding'; // 'bidding' | 'playing' | 'roundOver'
  int? myBid;
  String? selectedCardId;

  // 13 dealt cards for player 0
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

  List<Map<String, dynamic>> playedTrick = [];

  void onSelectBid(int bid) {
    setState(() {
      myBid = bid;
      phase = 'playing';
      currentTurnSeat = 0; // My turn to lead trick 1
    });
  }

  void onPlayCard(engine.Card card) {
    setState(() {
      myHand.removeWhere((c) => c.id == card.id);
      playedTrick.add({'seat': 0, 'card': card});
      currentTurnSeat = 1;

      // Simulate bot answers
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() {
          playedTrick.add({
            'seat': 1,
            'card': const engine.Card(suit: engine.Suit.H, rank: 4, deck: 0, id: '4H0'),
          });
          playedTrick.add({
            'seat': 2,
            'card': const engine.Card(suit: engine.Suit.H, rank: 8, deck: 0, id: '8H0'),
          });
          playedTrick.add({
            'seat': 3,
            'card': const engine.Card(suit: engine.Suit.S, rank: 2, deck: 0, id: '2S0'),
          });
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF1E3A2B), // Classic Nepali green felt
      body: SafeArea(
        child: Stack(
          children: [
            // Top Bar
            Positioned(
              top: 8.0,
              left: 16.0,
              right: 16.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Semantics(
                    button: true,
                    label: 'callbreak.leave'.tr(),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => showLeaveConfirmDialog(context),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Text(
                      '${'table.round'.tr()} $currentRound / 5 · ${'table.pot'.tr()}: 400',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48.0),
                ],
              ),
            ),

            // Top Seat (Opposite, Seat 2)
            Positioned(
              top: 48.0,
              left: 0,
              right: 0,
              child: Center(
                child: SeatWidget(
                  displayName: 'Bot 2',
                  bid: 3,
                  tricksWon: 1,
                  isBot: true,
                  isCurrentTurn: currentTurnSeat == 2,
                ),
              ),
            ),

            // Left Seat (Seat 1)
            Positioned(
              left: 16.0,
              top: 140.0,
              child: SeatWidget(
                displayName: 'Bot 1',
                bid: 2,
                tricksWon: 0,
                isBot: true,
                isCurrentTurn: currentTurnSeat == 1,
              ),
            ),

            // Right Seat (Seat 3)
            Positioned(
              right: 16.0,
              top: 140.0,
              child: SeatWidget(
                displayName: 'Bot 3',
                bid: 4,
                tricksWon: 2,
                isBot: true,
                isCurrentTurn: currentTurnSeat == 3,
              ),
            ),

            // Center Trick Area
            Center(
              child: Container(
                width: 220,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: playedTrick.isEmpty
                    ? Center(
                        child: Text(
                          phase == 'bidding'
                              ? 'callbreak.select_bid'.tr()
                              : 'table.your_turn'.tr(),
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                        ),
                      )
                    : Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: playedTrick
                            .map((pt) => PlayingCardWidget(card: pt['card'] as engine.Card))
                            .toList(),
                      ),
              ),
            ),

            // Bidding Dialog / Controls Overlay
            if (phase == 'bidding')
              Positioned(
                bottom: 120.0,
                left: 32.0,
                right: 32.0,
                child: Card(
                  color: colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'callbreak.select_bid'.tr(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Wrap(
                          spacing: 8.0,
                          children: List.generate(8, (index) {
                            final bidValue = index + 1;
                            return OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(48, 48), // 48x48 tap target
                              ),
                              onPressed: () => onSelectBid(bidValue),
                              child: Text('$bidValue'),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Bottom Area: My Seat & Hand Cards
            Positioned(
              bottom: 12.0,
              left: 16.0,
              right: 16.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SeatWidget(
                    displayName: 'You',
                    bid: myBid,
                    tricksWon: 1,
                    isBot: false,
                    isCurrentTurn: currentTurnSeat == 0,
                  ),
                  const SizedBox(height: 8.0),
                  SizedBox(
                    height: 90.0,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: myHand.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 4.0),
                      itemBuilder: (context, index) {
                        final card = myHand[index];
                        return PlayingCardWidget(
                          card: card,
                          isLegal: phase == 'playing' && currentTurnSeat == 0,
                          isSelected: selectedCardId == card.id,
                          onTap: () => onPlayCard(card),
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

  void showLeaveConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('callbreak.leave'.tr()),
        content: Text('callbreak.leave_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('callbreak.stay'.tr()),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: Text('callbreak.leave'.tr()),
          ),
        ],
      ),
    );
  }
}
