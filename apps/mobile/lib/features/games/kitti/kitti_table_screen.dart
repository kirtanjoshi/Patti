import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patii_engine/patii_engine.dart' as engine;
import '../../table/widgets/seat_widget.dart';
import 'kitti_action_bar.dart';
import 'kitti_arrange_board.dart';
import 'kitti_dialogs.dart';
import 'kitti_evaluator.dart';
import 'kitti_models.dart';
import 'kitti_reveal_board.dart';

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

    _simulateBotArrangements(bot1Cards, bot2Cards, bot3Cards);
  }

  void _simulateBotArrangements(
    List<engine.Card> b1,
    List<engine.Card> b2,
    List<engine.Card> b3,
  ) {
    _botTimers.add(Timer(const Duration(seconds: 2), () {
      if (!mounted || phase != KittiPhase.arranging) return;
      setState(() {
        players[1] = players[1].copyWith(
          isReady: true,
          arrangedHands: KittiEvaluator.bestArrangement(b1),
        );
      });
    }));

    _botTimers.add(Timer(const Duration(seconds: 3), () {
      if (!mounted || phase != KittiPhase.arranging) return;
      setState(() {
        players[2] = players[2].copyWith(
          isReady: true,
          arrangedHands: KittiEvaluator.bestArrangement(b2),
        );
      });
    }));

    _botTimers.add(Timer(const Duration(seconds: 4), () {
      if (!mounted || phase != KittiPhase.arranging) return;
      setState(() {
        players[3] = players[3].copyWith(
          isReady: true,
          arrangedHands: KittiEvaluator.bestArrangement(b3),
        );
      });
    }));
  }

  void _handleTimeExpired() {
    if (phase != KittiPhase.arranging) return;
    _applyBestArrangement();
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(theme, colorScheme),
            _buildOpponentsBar(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: phase == KittiPhase.arranging
                    ? SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: KittiArrangeBoard(
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
                          ),
                        ),
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
            if (phase == KittiPhase.arranging)
              KittiActionBar(
                unassignedCards: unassignedCards,
                selectedCard: selectedCard,
                isAllSlotsFilled: _isAllSlotsFilled,
                onCardTap: _onUnassignedCardTap,
                onBestArrangement: _applyBestArrangement,
                onConfirmShow: _confirmArrangement,
                onFold: _onFold,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Semantics(
            button: true,
            label: 'actions.leave'.tr(),
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => KittiDialogs.showLeaveConfirm(context),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: isCarryover ? colorScheme.primary : colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      '${'table.round'.tr()} $currentDeal · ${'table.pot'.tr()}: $pot',
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (isCarryover) ...[
                    const SizedBox(width: 8.0),
                    Icon(Icons.sync, size: 14, color: colorScheme.primary),
                  ],
                ],
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (phase == KittiPhase.arranging)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: _remainingSeconds <= 10
                        ? colorScheme.errorContainer
                        : colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    '$_remainingSeconds${'kitti.seconds_short'.tr()}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: _remainingSeconds <= 10
                          ? colorScheme.onErrorContainer
                          : colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(width: 4.0),
              Semantics(
                button: true,
                label: 'kitti.rules_title'.tr(),
                child: IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => KittiDialogs.showRules(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOpponentsBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Flexible(
            child: SeatWidget(
              displayName: players[1].displayName,
              statusText: players[1].isFolded
                  ? 'kitti.folded'.tr()
                  : (players[1].isReady ? 'kitti.ready'.tr() : 'kitti.arranging'.tr()),
              isBot: true,
              isWinner: roundSummary?.winnerSeat == 1,
            ),
          ),
          const SizedBox(width: 4.0),
          Flexible(
            child: SeatWidget(
              displayName: players[2].displayName,
              statusText: players[2].isFolded
                  ? 'kitti.folded'.tr()
                  : (players[2].isReady ? 'kitti.ready'.tr() : 'kitti.arranging'.tr()),
              isBot: true,
              isWinner: roundSummary?.winnerSeat == 2,
            ),
          ),
          const SizedBox(width: 4.0),
          Flexible(
            child: SeatWidget(
              displayName: players[3].displayName,
              statusText: players[3].isFolded
                  ? 'kitti.folded'.tr()
                  : (players[3].isReady ? 'kitti.ready'.tr() : 'kitti.arranging'.tr()),
              isBot: true,
              isWinner: roundSummary?.winnerSeat == 3,
            ),
          ),
        ],
      ),
    );
  }

  List<engine.Card> _generateDeck() {
    final suits = [engine.Suit.S, engine.Suit.H, engine.Suit.D, engine.Suit.C];
    final deck = <engine.Card>[];
    for (final s in suits) {
      for (int r = 1; r <= 13; r++) {
        deck.add(engine.Card(
          suit: s,
          rank: r,
          deck: 0,
          id: '${s.name}$r',
        ));
      }
    }
    deck.shuffle();
    return deck;
  }
}
