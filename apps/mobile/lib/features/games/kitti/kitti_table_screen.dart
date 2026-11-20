import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patii_engine/patii_engine.dart' as engine;
import '../../../../core/widgets/player_seat.dart';
import '../../../../core/widgets/table_shell.dart';
import 'kitti_action_bar.dart';
import 'kitti_arrange_board.dart';
import 'kitti_dialogs.dart';
import 'kitti_evaluator.dart';
import 'kitti_models.dart';
import 'kitti_reveal_board.dart';

/// Casino-Style Kitti Table Screen (Landscape).
/// Features:
/// - Screen locked to landscape via TableShell
/// - Elliptical 4-player seating: You (bottom-left), Bot 1 (West), Bot 2 (North), Bot 3 (East)
/// - 3x3 Arrange Board in center felt with drag-and-drop slots and Auto Arrange button
/// - Smooth reveal phase showing winning shows and Salami bonus
class KittiTableScreen extends ConsumerStatefulWidget {
  const KittiTableScreen({super.key});

  @override
  ConsumerState<KittiTableScreen> createState() => _KittiTableScreenState();
}

class _KittiTableScreenState extends ConsumerState<KittiTableScreen> {
  static const int arrangeTimeSeconds = 45;
  static const int bootAmount = 100;

  int currentDeal = 1;
  int pot = 400; // 4 players * 100 boot
  bool isCarryover = false;
  KittiPhase phase = KittiPhase.arranging;

  Timer? _arrangeTimer;
  final List<Timer> _botTimers = [];
  int _remainingSeconds = arrangeTimeSeconds;

  late List<KittiPlayer> players;
  List<engine.Card> myRawCards = [];
  List<engine.Card> unassignedCards = [];
  List<List<engine.Card>> mySlots = [[], [], []];
  engine.Card? selectedCard;

  KittiRoundSummary? roundSummary;

  @override
  void initState() {
    super.initState();
    _startNewDeal(isFirstDeal: true);
  }

  @override
  void dispose() {
    _arrangeTimer?.cancel();
    _cancelBotTimers();
    super.dispose();
  }

  void _cancelBotTimers() {
    for (final t in _botTimers) {
      t.cancel();
    }
    _botTimers.clear();
  }

  void _startNewDeal({bool isFirstDeal = false}) {
    _arrangeTimer?.cancel();
    _cancelBotTimers();

    final deck = _generateDeck();
    myRawCards = deck.sublist(0, 9);
    unassignedCards = List<engine.Card>.from(myRawCards);
    mySlots = [[], [], []];
    selectedCard = null;

    final bot1Cards = deck.sublist(9, 18);
    final bot2Cards = deck.sublist(18, 27);
    final bot3Cards = deck.sublist(27, 36);

    players = [
      const KittiPlayer(seatIndex: 0, displayName: 'You'),
      const KittiPlayer(seatIndex: 1, displayName: 'Bot 1', isBot: true),
      const KittiPlayer(seatIndex: 2, displayName: 'Bot 2', isBot: true),
      const KittiPlayer(seatIndex: 3, displayName: 'Bot 3', isBot: true),
    ];

    if (!isFirstDeal && !isCarryover) {
      pot += players.length * bootAmount;
      currentDeal++;
    }

    phase = KittiPhase.arranging;
    _remainingSeconds = arrangeTimeSeconds;
    roundSummary = null;

    _arrangeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _arrangeTimer?.cancel();
          _handleTimeExpired();
        }
      });
    });

    _simulateBots(1, bot1Cards, 8);
    _simulateBots(2, bot2Cards, 12);
    _simulateBots(3, bot3Cards, 16);
  }

  List<engine.Card> _generateDeck() {
    final suits = [engine.Suit.S, engine.Suit.H, engine.Suit.D, engine.Suit.C];
    final deck = <engine.Card>[];
    for (final s in suits) {
      for (int r = 1; r <= 13; r++) {
        deck.add(engine.Card(suit: s, rank: r, deck: 0, id: '$r${s.name}'));
      }
    }
    deck.shuffle();
    return deck;
  }

  void _simulateBots(int seatIndex, List<engine.Card> cards, int delaySeconds) {
    final timer = Timer(Duration(seconds: delaySeconds), () {
      if (!mounted) return;
      setState(() {
        final arrangement = KittiEvaluator.bestArrangement(cards);
        players[seatIndex] = players[seatIndex].copyWith(
          isReady: true,
          arrangedHands: arrangement,
        );
      });
    });
    _botTimers.add(timer);
  }

  void _handleTimeExpired() {
    if (!_isAllSlotsFilled) {
      _applyBestArrangement();
    }
    _confirmArrangement();
  }

  void _applyBestArrangement() {
    final best = KittiEvaluator.bestArrangement(myRawCards);
    if (best.length == 3) {
      setState(() {
        mySlots = [
          List<engine.Card>.from(best[0]),
          List<engine.Card>.from(best[1]),
          List<engine.Card>.from(best[2]),
        ];
        unassignedCards.clear();
        selectedCard = null;
      });
    }
  }

  void _confirmArrangement() {
    _arrangeTimer?.cancel();
    _cancelBotTimers();

    for (int i = 1; i < players.length; i++) {
      if (players[i].arrangedHands == null) {
        final dummyHand = _generateDeck().sublist(0, 9);
        players[i] = players[i].copyWith(
          isReady: true,
          arrangedHands: KittiEvaluator.bestArrangement(dummyHand),
        );
      }
    }

    setState(() {
      players[0] = players[0].copyWith(
        isReady: true,
        arrangedHands: [
          List<engine.Card>.from(mySlots[0]),
          List<engine.Card>.from(mySlots[1]),
          List<engine.Card>.from(mySlots[2]),
        ],
      );
      _evaluateAllShows();
      phase = KittiPhase.revealing;
    });
  }

  void _onFold() {
    KittiDialogs.showFoldConfirm(context, () {
      _arrangeTimer?.cancel();
      setState(() {
        players[0] = players[0].copyWith(isFolded: true);
        _confirmArrangement();
      });
    });
  }

  void _evaluateAllShows() {
    final showWins = List<int>.filled(players.length, 0);
    final showResults = <KittiShowResult>[];

    for (int showIdx = 0; showIdx < 3; showIdx++) {
      final evaluations = <int, KittiHandEvaluation>{};
      int? bestSeat;
      double highestScore = -1;
      bool isTie = false;

      for (final p in players) {
        if (p.isFolded || p.arrangedHands == null) continue;
        final hand = p.arrangedHands![showIdx];
        final eval = KittiEvaluator.evaluate(hand);
        evaluations[p.seatIndex] = eval;

        if (eval.score > highestScore) {
          highestScore = eval.score;
          bestSeat = p.seatIndex;
          isTie = false;
        } else if (eval.score == highestScore) {
          isTie = true;
        }
      }

      final winningSeat = isTie ? null : bestSeat;
      if (winningSeat != null) {
        showWins[winningSeat]++;
      }

      showResults.add(KittiShowResult(
        showIndex: showIdx,
        winnerSeat: winningSeat,
        isVoid: isTie,
        handEvaluations: evaluations,
      ));
    }

    for (int i = 0; i < players.length; i++) {
      players[i] = players[i].copyWith(showWins: showWins[i]);
    }

    int? overallWinner;
    bool isSalami = false;

    for (int i = 0; i < players.length; i++) {
      if (showWins[i] >= 2) {
        overallWinner = i;
        if (showWins[i] == 3) isSalami = true;
        break;
      }
    }

    final isKitti = overallWinner == null;
    isCarryover = isKitti;

    roundSummary = KittiRoundSummary(
      winnerSeat: overallWinner,
      isKittiCarryover: isKitti,
      isSalami: isSalami,
      showResults: showResults,
      pot: pot,
    );
  }

  void _onUnassignedCardTap(engine.Card card) {
    setState(() {
      if (selectedCard?.id == card.id) {
        selectedCard = null;
      } else {
        selectedCard = card;
        for (int i = 0; i < 3; i++) {
          if (mySlots[i].length < 3) {
            mySlots[i].add(card);
            unassignedCards.removeWhere((c) => c.id == card.id);
            selectedCard = null;
            break;
          }
        }
      }
    });
  }

  void _onSlotTap(int slotIndex) {
    if (selectedCard == null) return;
    if (mySlots[slotIndex].length < 3) {
      setState(() {
        mySlots[slotIndex].add(selectedCard!);
        unassignedCards.removeWhere((c) => c.id == selectedCard!.id);
        selectedCard = null;
      });
    }
  }

  void _onCardTapInSlot(int slotIndex, engine.Card card) {
    setState(() {
      mySlots[slotIndex].removeWhere((c) => c.id == card.id);
      unassignedCards.add(card);
    });
  }

  void _onClearSlot(int slotIndex) {
    setState(() {
      unassignedCards.addAll(mySlots[slotIndex]);
      mySlots[slotIndex].clear();
    });
  }

  bool get _isAllSlotsFilled =>
      mySlots[0].length == 3 && mySlots[1].length == 3 && mySlots[2].length == 3;

  @override
  Widget build(BuildContext context) {
    return TableShell(
      gameTitle: 'Kitti',
      roundInfo: '${'table.round'.tr()} $currentDeal · ${'table.pot'.tr()}: $pot',
      pot: pot,
      onRulesTap: () => KittiDialogs.showRules(context),
      onLeave: () => KittiDialogs.showLeaveConfirm(context),
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
                    infoPillText: players[2].isReady
                        ? 'Ready'
                        : (players[2].isFolded ? 'Folded' : '$_remainingSeconds s'),
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
                  infoPillText: players[1].isReady
                      ? 'Ready'
                      : (players[1].isFolded ? 'Folded' : '$_remainingSeconds s'),
                ),
              ),

              // 3. Right Opponent (Bot 3, East)
              Positioned(
                right: 12,
                top: (tableHeight - 160) / 2,
                child: PlayerSeat(
                  displayName: 'Bot 3',
                  isBot: true,
                  infoPillText: players[3].isReady
                      ? 'Ready'
                      : (players[3].isFolded ? 'Folded' : '$_remainingSeconds s'),
                ),
              ),

              // 4. Center Area: Arrange Board OR Reveal Board
              Positioned(
                left: tableWidth < 700 ? 50 : 90,
                right: tableWidth < 700 ? 50 : 90,
                top: 48,
                bottom: phase == KittiPhase.arranging ? 128 : 12,
                child: Center(
                  child: phase == KittiPhase.arranging
                      ? KittiArrangeBoard(
                          slots: mySlots,
                          selectedCard: selectedCard,
                          onCardTapInSlot: _onCardTapInSlot,
                          onSlotTap: _onSlotTap,
                          onClearSlot: _onClearSlot,
                          onCardDropped: (slotIdx, card) {
                            if (mySlots[slotIdx].length < 3) {
                              setState(() {
                                mySlots[slotIdx].add(card);
                                unassignedCards.removeWhere((c) => c.id == card.id);
                              });
                            }
                          },
                        )
                      : (roundSummary != null
                          ? KittiRevealBoard(
                              players: players,
                              summary: roundSummary!,
                              onNextDeal: () => _startNewDeal(),
                            )
                          : const SizedBox.shrink()),
                ),
              ),

              // 5. You (Bottom Left PlayerSeat)
              Positioned(
                left: 16,
                bottom: 8,
                child: PlayerSeat(
                  displayName: 'You',
                  isBot: false,
                  infoPillText: players[0].isFolded
                      ? 'Folded'
                      : '${unassignedCards.length} left',
                ),
              ),

              // 6. Action Bar at Bottom Center (when arranging)
              if (phase == KittiPhase.arranging)
                Positioned(
                  left: tableWidth < 700 ? 90 : 130,
                  right: tableWidth < 700 ? 20 : 60,
                  bottom: 8,
                  child: KittiActionBar(
                    unassignedCards: unassignedCards,
                    selectedCard: selectedCard,
                    isAllSlotsFilled: _isAllSlotsFilled,
                    onCardTap: _onUnassignedCardTap,
                    onBestArrangement: _applyBestArrangement,
                    onConfirmShow: _confirmArrangement,
                    onFold: _onFold,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
