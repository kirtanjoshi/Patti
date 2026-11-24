import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patii_engine/patii_engine.dart' as engine;
import '../../../../core/models/user_model.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/socket_service.dart';
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
/// Supports both Realtime Online Multiplayer and Offline Solo Play.
class CallbreakTableScreen extends ConsumerStatefulWidget {
  final String? tableId;
  final int mySeat;
  final List<RoomParticipantModel>? participants;

  const CallbreakTableScreen({
    super.key,
    this.tableId,
    this.mySeat = 0,
    this.participants,
  });

  @override
  ConsumerState<CallbreakTableScreen> createState() =>
      _CallbreakTableScreenState();
}

class _CallbreakTableScreenState extends ConsumerState<CallbreakTableScreen> {
  int currentRound = 1;
  int currentTurnSeat = 0; // Absolute table seat index (0..3)
  String phase = 'bidding'; // 'bidding' | 'playing' | 'roundOver'
  int _version = 1;
  int? trickWinner;
  String? selectedCardId;

  // Track bids, tricks won, and card counts across all 4 seats
  final List<int?> _bids = [null, null, null, null];
  final List<int> _tricksWon = [0, 0, 0, 0];
  final List<int> _cardCounts = [13, 13, 13, 13];
  late Map<int, List<engine.Card>> _botHands;

  Timer? _botTimer;
  StreamSubscription? _stateSub;
  StreamSubscription? _turnSub;
  StreamSubscription? _resultSub;

  // Default initial cards for player (You)
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

  @override
  void initState() {
    super.initState();
    _initOfflineBotHands();
    if (widget.tableId != null) {
      _initOnlineTable();
    }
  }

  static int _aceHighRank(int rank) => rank == 1 ? 14 : rank;

  void _initOfflineBotHands() {
    final myIds = myHand.map((c) => '${c.suit.name}_${_aceHighRank(c.rank)}').toSet();
    final remaining = <engine.Card>[];
    for (final s in [engine.Suit.S, engine.Suit.H, engine.Suit.D, engine.Suit.C]) {
      for (int r = 2; r <= 14; r++) {
        final key = '${s.name}_$r';
        if (!myIds.contains(key)) {
          remaining.add(engine.Card(
            suit: s,
            rank: r == 14 ? 1 : r,
            deck: 0,
            id: '${r == 14 ? 'A' : r}${s.name}0',
          ));
        }
      }
    }
    _botHands = {
      1: remaining.sublist(0, 13),
      2: remaining.sublist(13, 26),
      3: remaining.sublist(26, 39),
    };
    for (int s = 0; s < 4; s++) {
      _cardCounts[s] = 13;
      _tricksWon[s] = 0;
    }
  }

  void _initOnlineTable() {
    final socket = ref.read(socketServiceProvider);
    _stateSub = socket.tableStateStream.listen((data) {
      if (!mounted) return;
      if (data['tableId'] != widget.tableId) return;
      _version = (data['version'] as num?)?.toInt() ?? _version;
      final view = data['view'] as Map<String, dynamic>?;
      if (view != null) {
        _syncFromView(view);
      }
    });

    _turnSub = socket.tableTurnStream.listen((data) {
      if (!mounted) return;
      if (data['tableId'] != widget.tableId) return;
      final seat = (data['seat'] as num?)?.toInt();
      if (seat != null) {
        setState(() => currentTurnSeat = seat);
      }
    });

    _resultSub = socket.tableResultStream.listen((data) {
      if (!mounted) return;
      AudioService.instance.playWinJingle();
      ToastBanner.show(
        context,
        'Round complete! Well played.',
        icon: Icons.emoji_events,
      );
    });
  }

  static engine.Card _parseCard(Map<String, dynamic> json) {
    final suitStr = json['suit'] as String? ?? 'S';
    final rank = (json['rank'] as num?)?.toInt() ?? 1;
    final deck = (json['deck'] as num?)?.toInt() ?? 0;
    final id = json['id'] as String? ?? '$rank$suitStr$deck';
    final suit = switch (suitStr) {
      'S' => engine.Suit.S,
      'H' => engine.Suit.H,
      'D' => engine.Suit.D,
      'C' => engine.Suit.C,
      _ => engine.Suit.S,
    };
    return engine.Card(suit: suit, rank: rank, deck: deck, id: id);
  }

  void _syncFromView(Map<String, dynamic> view) {
    setState(() {
      phase = view['phase'] as String? ?? phase;
      currentRound = (view['roundNumber'] as num?)?.toInt() ?? currentRound;
      currentTurnSeat =
          (view['currentTurnSeat'] as num?)?.toInt() ?? currentTurnSeat;

      if (view['myHand'] is List) {
        myHand = (view['myHand'] as List)
            .map((c) => _parseCard(Map<String, dynamic>.from(c as Map)))
            .toList();
      }

      if (view['currentTrick'] is List) {
        playedTrick = (view['currentTrick'] as List).map((item) {
          final m = Map<String, dynamic>.from(item as Map);
          return PlayedTrickCard(
            seat: (m['seat'] as num).toInt(),
            card: _parseCard(Map<String, dynamic>.from(m['card'] as Map)),
          );
        }).toList();
      }

      if (view['players'] is List) {
        final playersList = view['players'] as List;
        for (final p in playersList) {
          final m = Map<String, dynamic>.from(p as Map);
          final s = (m['seat'] as num).toInt();
          if (s >= 0 && s < 4) {
            _bids[s] = (m['bid'] as num?)?.toInt();
            _tricksWon[s] = (m['tricksWon'] as num?)?.toInt() ?? 0;
            _cardCounts[s] = (m['cardCount'] as num?)?.toInt() ?? 13;
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _botTimer?.cancel();
    _stateSub?.cancel();
    _turnSub?.cancel();
    _resultSub?.cancel();
    super.dispose();
  }

  void _onBidConfirmed(int bid) {
    AudioService.instance.playChip();
    if (widget.tableId != null) {
      ref.read(socketServiceProvider).sendMove(
        widget.tableId!,
        _version,
        {'type': 'bid', 'bid': bid},
      );
      setState(() {
        _bids[widget.mySeat] = bid;
      });
      ToastBanner.show(context, 'Bid $bid placed!', icon: Icons.gavel);
    } else {
      setState(() {
        _bids[0] = bid;
        _bids[1] = 3;
        _bids[2] = 3;
        _bids[3] = 4;
        phase = 'playing';
        currentTurnSeat = 0;
      });
      ToastBanner.show(
        context,
        'Bid $bid placed! Your turn to lead.',
        icon: Icons.gavel,
      );
    }
  }

  Set<String> _computePlayableIds() {
    if (phase != 'playing' || currentTurnSeat != widget.mySeat) {
      return const <String>{};
    }
    if (playedTrick.isEmpty) {
      return myHand.map((c) => c.id).toSet();
    }
    final leadSuit = playedTrick.first.card.suit;
    final sameSuit = myHand.where((c) => c.suit == leadSuit).toList();
    if (sameSuit.isNotEmpty) {
      return sameSuit.map((c) => c.id).toSet();
    }
    final spades = myHand.where((c) => c.suit == engine.Suit.S).toList();
    if (spades.isNotEmpty) {
      return spades.map((c) => c.id).toSet();
    }
    return myHand.map((c) => c.id).toSet();
  }

  void _onPlayCard(engine.Card card) {
    if (phase != 'playing' || currentTurnSeat != widget.mySeat) return;
    if (playedTrick.length >= 4) return;

    final isTrumpCut = playedTrick.isNotEmpty &&
        playedTrick.first.card.suit != engine.Suit.S &&
        card.suit == engine.Suit.S;
    if (isTrumpCut) {
      AudioService.instance.playSpecialHand();
    } else {
      AudioService.instance.playCardSnap();
    }

    if (widget.tableId != null) {
      ref.read(socketServiceProvider).sendMove(
        widget.tableId!,
        _version,
        {'type': 'playCard', 'cardId': card.id},
      );
      setState(() {
        myHand.removeWhere((c) => c.id == card.id);
        _cardCounts[widget.mySeat] = myHand.length;
        selectedCardId = null;
      });
    } else {
      setState(() {
        myHand.removeWhere((c) => c.id == card.id);
        _cardCounts[0] = myHand.length;
        selectedCardId = null;
        playedTrick.add(PlayedTrickCard(seat: 0, card: card));
        if (playedTrick.length < 4) {
          currentTurnSeat = 1;
        }
      });

      _botTimer?.cancel();
      if (playedTrick.length >= 4) {
        _botTimer = Timer(const Duration(milliseconds: 650), _resolveTrick);
      } else {
        _scheduleNextOfflineBotIfNeeded();
      }
    }
  }

  engine.Card _pickBotCard(int seat) {
    final hand = _botHands[seat] ?? [];
    if (hand.isEmpty) {
      return engine.Card(
          suit: engine.Suit.C, rank: 2, deck: 0, id: '2C_bot$seat');
    }

    if (playedTrick.isEmpty) {
      // Bot leads: prefer highest non-spade, otherwise lowest card
      final nonSpades = hand.where((c) => c.suit != engine.Suit.S).toList()
        ..sort((a, b) => _aceHighRank(b.rank).compareTo(_aceHighRank(a.rank)));
      return nonSpades.isNotEmpty ? nonSpades.first : hand.first;
    }

    final leadSuit = playedTrick.first.card.suit;
    final currentBest = _currentWinningCard();
    final sameSuit = hand.where((c) => c.suit == leadSuit).toList()
      ..sort((a, b) => _aceHighRank(a.rank).compareTo(_aceHighRank(b.rank)));

    if (sameSuit.isNotEmpty) {
      if (currentBest.card.suit == leadSuit) {
        final higher = sameSuit.where(
            (c) => _aceHighRank(c.rank) > _aceHighRank(currentBest.card.rank));
        if (higher.isNotEmpty) return higher.first;
      }
      return sameSuit.first;
    }

    // Void in lead suit: must play spade if available
    final spades = hand.where((c) => c.suit == engine.Suit.S).toList()
      ..sort((a, b) => _aceHighRank(a.rank).compareTo(_aceHighRank(b.rank)));
    if (spades.isNotEmpty) {
      if (currentBest.card.suit == engine.Suit.S) {
        final higherSpades = spades.where(
            (c) => _aceHighRank(c.rank) > _aceHighRank(currentBest.card.rank));
        if (higherSpades.isNotEmpty) return higherSpades.first;
      }
      return spades.first;
    }

    final sorted = [...hand]
      ..sort((a, b) => _aceHighRank(a.rank).compareTo(_aceHighRank(b.rank)));
    return sorted.first;
  }

  void _scheduleNextOfflineBotIfNeeded() {
    if (widget.tableId != null ||
        phase != 'playing' ||
        currentTurnSeat == widget.mySeat ||
        playedTrick.length >= 4) {
      return;
    }

    _botTimer?.cancel();
    _botTimer = Timer(const Duration(milliseconds: 480), () {
      if (!mounted || phase != 'playing') return;
      final seat = currentTurnSeat;
      if (seat == widget.mySeat || playedTrick.length >= 4) return;

      final botCard = _pickBotCard(seat);
      _botHands[seat]?.removeWhere((c) => c.id == botCard.id);
      AudioService.instance.playCardSnap();

      setState(() {
        _cardCounts[seat] = _botHands[seat]?.length ?? 0;
        playedTrick.add(PlayedTrickCard(seat: seat, card: botCard));
        if (playedTrick.length < 4) {
          currentTurnSeat = (seat + 1) % 4;
        }
      });

      if (playedTrick.length >= 4) {
        _botTimer = Timer(const Duration(milliseconds: 650), _resolveTrick);
      } else if (currentTurnSeat != widget.mySeat) {
        _scheduleNextOfflineBotIfNeeded();
      }
    });
  }

  PlayedTrickCard _currentWinningCard() {
    PlayedTrickCard best = playedTrick.first;
    for (final pt in playedTrick) {
      if (pt.card.suit == engine.Suit.S && best.card.suit != engine.Suit.S) {
        best = pt;
      } else if (pt.card.suit == best.card.suit &&
          _aceHighRank(pt.card.rank) > _aceHighRank(best.card.rank)) {
        best = pt;
      }
    }
    return best;
  }

  void _resolveTrick() {
    if (!mounted || playedTrick.isEmpty) return;
    final winningPlay = _currentWinningCard();
    final winningSeat = winningPlay.seat;

    if (winningSeat == widget.mySeat) {
      AudioService.instance.playPotCollect();
    } else {
      AudioService.instance.playCardSlide();
    }

    setState(() => trickWinner = winningSeat);
    final winnerName =
        winningSeat == widget.mySeat ? 'You' : _displayNameForSeat(winningSeat);
    ToastBanner.show(
      context,
      '$winnerName won the trick!',
      icon: Icons.emoji_events,
    );

    _botTimer?.cancel();
    _botTimer = Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      setState(() {
        _tricksWon[winningSeat] = _tricksWon[winningSeat] + 1;
        playedTrick.clear();
        trickWinner = null;
        currentTurnSeat = winningSeat;
      });

      // Check if all 13 tricks in offline round are complete
      if (widget.tableId == null && myHand.isEmpty) {
        AudioService.instance.playWinJingle();
        setState(() {
          currentRound = currentRound < 5 ? currentRound + 1 : 1;
          phase = 'bidding';
          currentTurnSeat = 0;
          _bids.fillRange(0, 4, null);
          myHand = [
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
          _initOfflineBotHands();
        });
        return;
      }

      // If a bot won the trick, that bot must lead the next trick!
      if (widget.tableId == null && winningSeat != widget.mySeat) {
        _scheduleNextOfflineBotIfNeeded();
      }
    });
  }

  String _displayNameForSeat(int seat) {
    if (seat == widget.mySeat) return 'You';
    if (widget.participants != null) {
      for (final p in widget.participants!) {
        if (p.seat == seat) return p.displayName;
      }
    }
    return 'Bot $seat';
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
    final isMyTurn = phase == 'playing' && currentTurnSeat == widget.mySeat;
    final isBiddingTurn = phase == 'bidding' &&
        (widget.tableId == null || currentTurnSeat == widget.mySeat);
    final playableIds = _computePlayableIds();

    final westSeat = (widget.mySeat + 1) % 4;
    final northSeat = (widget.mySeat + 2) % 4;
    final eastSeat = (widget.mySeat + 3) % 4;
    final southSeat = widget.mySeat;

    final relativeTrick = playedTrick.map((pt) {
      final relSeat = (pt.seat - widget.mySeat + 4) % 4;
      return PlayedTrickCard(seat: relSeat, card: pt.card);
    }).toList();
    final relativeWinner =
        trickWinner == null ? null : (trickWinner! - widget.mySeat + 4) % 4;

    return TableShell(
      gameTitle: 'Callbreak',
      roundInfo: '${'table.round'.tr()} $currentRound / 5',
      trumpSuit: 'Spades',
      pot: 400,
      onRulesTap: () => _showRulesDialog(context),
      child: Stack(
        children: [
          // 1. Top Opponent (North, relative 2)
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: OpponentSeatPanel(
                displayName: _displayNameForSeat(northSeat),
                bid: _bids[northSeat] ?? 3,
                tricksWon: _tricksWon[northSeat],
                cardCount: _cardCounts[northSeat],
                isCurrentTurn: currentTurnSeat == northSeat,
                isDealer: true,
              ),
            ),
          ),

          // 2. Left Opponent (West, relative 1)
          Positioned(
            left: 14,
            top: 40,
            bottom: 70,
            child: Center(
              child: OpponentSeatPanel(
                displayName: _displayNameForSeat(westSeat),
                bid: _bids[westSeat] ?? 2,
                tricksWon: _tricksWon[westSeat],
                cardCount: _cardCounts[westSeat],
                isCurrentTurn: currentTurnSeat == westSeat,
              ),
            ),
          ),

          // 3. Right Opponent (East, relative 3)
          Positioned(
            right: 14,
            top: 40,
            bottom: 70,
            child: Center(
              child: OpponentSeatPanel(
                displayName: _displayNameForSeat(eastSeat),
                stackOnLeft: true,
                bid: _bids[eastSeat] ?? 4,
                tricksWon: _tricksWon[eastSeat],
                cardCount: _cardCounts[eastSeat],
                isCurrentTurn: currentTurnSeat == eastSeat,
              ),
            ),
          ),

          // 4. Center Diamond Trick Area
          Positioned.fill(
            child: Center(
              child: CallbreakTrickArea(
                playedCards: relativeTrick,
                phase: phase,
                currentTurnSeat: (currentTurnSeat - widget.mySeat + 4) % 4,
                winningSeat: relativeWinner,
              ),
            ),
          ),

          // 5. You Seat (South, relative 0)
          Positioned(
            left: 14,
            bottom: 8,
            child: PlayerSeat(
              displayName: 'You',
              isCurrentTurn: isMyTurn,
              infoPillText: _bids[southSeat] != null
                  ? '${_tricksWon[southSeat]} / ${_bids[southSeat]} tricks'
                  : '${_tricksWon[southSeat]} tricks',
              remainingSeconds: isMyTurn ? 12 : 15,
            ),
          ),

          // 6. Hand fan
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
                    if (!isMyTurn || !playableIds.contains(card.id)) return;
                    if (selectedCardId == card.id) {
                      _onPlayCard(card);
                    } else {
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

          // 7. Single-Row Bidding Sheet
          if (isBiddingTurn)
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
