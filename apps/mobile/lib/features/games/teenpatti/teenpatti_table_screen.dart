import 'dart:async';
import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide Card;
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/chips.dart';
import '../../../../core/widgets/table_felt.dart';
import '../../../../core/widgets/table_shell.dart';
import '../../../../core/widgets/toast_banner.dart';
import 'teenpatti_evaluator.dart';
import 'widgets/teenpatti_action_bar.dart';
import 'widgets/teenpatti_hand_fan.dart';
import 'widgets/teenpatti_pot_center.dart';
import 'widgets/teenpatti_seat_layer.dart';

/// Redesigned Casino-Style Teen Patti Table Screen (Landscape).
/// Features:
/// - Orientation locked to Landscape via TableShell
/// - Authentic Oval Felt Table with 14px wood rail and gold inner line
/// - Evenly distributed seats around the rail with "You" at bottom-center
/// - Central 3D ChipStack pot with live stakes and parabolic chip-toss motion
/// - 3-Card hand fan with 3D flip rotation ("See Cards") and live hand ranking
/// - Premium action bar: Pack (crimson), SideShow (ghost outline), Chaal/Show (gold CTA)
class TeenPattiTableScreen extends StatefulWidget {
  final int initialPlayerCount;

  const TeenPattiTableScreen({
    super.key,
    this.initialPlayerCount = 5,
  });

  @override
  State<TeenPattiTableScreen> createState() => _TeenPattiTableScreenState();
}

class _TeenPattiTableScreenState extends State<TeenPattiTableScreen> {
  static const int _bootAmount = 100;
  static const int _maxBlindRounds = 4;

  late int _playerCount;
  late List<TeenPattiPlayerState> _players;
  int _currentTurnSeat = 0;
  int _currentStake = _bootAmount;
  int _pot = 0;
  int? _lastBetAmount;
  int _roundNumber = 1;
  bool _isGameOver = false;
  List<int> _winnerSeats = [];
  Timer? _botTimer;

  // Chip toss animation state
  bool _isTossing = false;
  Offset? _chipTossStart;
  Offset? _chipTossEnd;
  int _tossAmount = 100;

  @override
  void initState() {
    super.initState();
    _playerCount = widget.initialPlayerCount.clamp(2, 7);
    _startNewRound();
  }

  @override
  void dispose() {
    _botTimer?.cancel();
    super.dispose();
  }

  void _startNewRound() {
    final deck = TeenPattiEvaluator.createShuffledDeck();
    _players = List.generate(_playerCount, (index) {
      final hand = deck.sublist(index * 3, index * 3 + 3);
      return TeenPattiPlayerState(
        seat: index,
        name: index == 0 ? 'You' : 'Bot $index',
        isMe: index == 0,
        isBot: index != 0,
        hand: hand,
        totalBet: _bootAmount,
      );
    });

    setState(() {
      _currentStake = _bootAmount;
      _pot = _bootAmount * _playerCount;
      _lastBetAmount = _bootAmount;
      _currentTurnSeat = 0; // Local player first
      _isGameOver = false;
      _winnerSeats = [];
    });
  }

  List<TeenPattiPlayerState> get _activePlayers =>
      _players.where((p) => !p.isPacked).toList();

  TeenPattiPlayerState get _myState => _players[0];

  int _nextActiveSeat(int fromSeat) {
    for (int step = 1; step < _players.length; step++) {
      final s = (fromSeat + step) % _players.length;
      if (!_players[s].isPacked) return s;
    }
    return fromSeat;
  }

  int _previousActiveSeat(int fromSeat) {
    for (int step = 1; step < _players.length; step++) {
      final s = (fromSeat - step + _players.length) % _players.length;
      if (!_players[s].isPacked) return s;
    }
    return fromSeat;
  }

  void _triggerChipToss(Offset from, Offset to, int amount) {
    if (!mounted) return;
    setState(() {
      _chipTossStart = from;
      _chipTossEnd = to;
      _tossAmount = amount;
      _isTossing = true;
    });
  }

  void _onToggleSeen() {
    setState(() => _myState.isSeen = !_myState.isSeen);
    ToastBanner.show(
      context,
      _myState.isSeen ? 'teenpatti.cards_revealed'.tr() : 'teenpatti.cards_hidden'.tr(),
      icon: _myState.isSeen ? Icons.visibility : Icons.visibility_off,
    );
  }

  void _onChaal(int amount) {
    if (_isGameOver || _currentTurnSeat != 0) return;

    _triggerChipToss(const Offset(380, 260), const Offset(420, 140), amount);

    setState(() {
      _myState.totalBet += amount;
      _pot += amount;
      _lastBetAmount = amount;

      final isRaise = _myState.isSeen
          ? amount > _currentStake * 2
          : amount > _currentStake;
      if (isRaise) {
        _currentStake = _myState.isSeen ? amount ~/ 2 : amount;
      }

      if (!_myState.isSeen) {
        _myState.blindRounds++;
      }

      _currentTurnSeat = _nextActiveSeat(0);
    });

    _triggerBotTurnIfNeeded();
  }

  void _onPack() {
    if (_isGameOver || _currentTurnSeat != 0) return;

    setState(() {
      _myState.isPacked = true;
      _checkRemainingWinner();
      if (!_isGameOver) {
        _currentTurnSeat = _nextActiveSeat(0);
      }
    });

    ToastBanner.show(context, 'You packed your hand', icon: Icons.close);

    if (!_isGameOver) {
      _triggerBotTurnIfNeeded();
    }
  }

  void _onSideShow() {
    final prevSeat = _previousActiveSeat(0);
    final prevPlayer = _players[prevSeat];

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: PatiiColors.navyElevated,
        shape: RoundedRectangleBorder(
          borderRadius: PatiiSpacing.rounded16,
          side: const BorderSide(color: PatiiColors.hairline),
        ),
        title: Text(
          'teenpatti.sideshow'.tr(),
          style: PatiiTypography.display(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: PatiiColors.goldLight,
          ),
        ),
        content: Text(
          '${'teenpatti.sideshow_request'.tr()} -> ${prevPlayer.name}',
          style: PatiiTypography.body(
            fontSize: 14,
            color: PatiiColors.textPrimary,
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PatiiColors.gold,
              foregroundColor: PatiiColors.navy,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              _resolveSideShow(0, prevSeat);
            },
            child: Text('actions.confirm'.tr()),
          ),
        ],
      ),
    );
  }

  void _resolveSideShow(int seatA, int seatB) {
    final scoreA = TeenPattiEvaluator.evaluateScore(_players[seatA].hand);
    final scoreB = TeenPattiEvaluator.evaluateScore(_players[seatB].hand);

    setState(() {
      if (scoreA <= scoreB) {
        _players[seatA].isPacked = true;
        ToastBanner.show(context, '${_players[seatA].name} lost side show and packed!');
      } else {
        _players[seatB].isPacked = true;
        ToastBanner.show(context, '${_players[seatB].name} lost side show and packed!');
      }
      _checkRemainingWinner();
      if (!_isGameOver) {
        _currentTurnSeat = _nextActiveSeat(seatA);
      }
    });

    if (!_isGameOver) {
      _triggerBotTurnIfNeeded();
    }
  }

  void _onShow() {
    if (_activePlayers.length != 2) return;

    int bestScore = -1;
    int winnerSeat = _activePlayers.first.seat;

    for (final player in _activePlayers) {
      final score = TeenPattiEvaluator.evaluateScore(player.hand);
      if (score > bestScore) {
        bestScore = score;
        winnerSeat = player.seat;
      }
    }

    setState(() {
      _isGameOver = true;
      _winnerSeats = [winnerSeat];
      for (final p in _players) {
        p.isSeen = true; // Reveal all hands on show
      }
    });

    _showWinnerDialog(winnerSeat);
  }

  void _checkRemainingWinner() {
    final remaining = _activePlayers;
    if (remaining.length == 1) {
      final winner = remaining.first;
      _isGameOver = true;
      _winnerSeats = [winner.seat];
      _showWinnerDialog(winner.seat);
    }
  }

  void _triggerBotTurnIfNeeded() {
    if (_isGameOver || _currentTurnSeat == 0) return;

    _botTimer?.cancel();
    _botTimer = Timer(const Duration(milliseconds: 650), () {
      if (!mounted || _isGameOver) return;

      final bot = _players[_currentTurnSeat];
      if (bot.isPacked) {
        setState(() => _currentTurnSeat = _nextActiveSeat(_currentTurnSeat));
        _triggerBotTurnIfNeeded();
        return;
      }

      final shouldPack = math.Random().nextDouble() < 0.10 && _activePlayers.length > 2;

      setState(() {
        if (shouldPack) {
          bot.isPacked = true;
          _checkRemainingWinner();
        } else {
          final betAmount = bot.isSeen ? _currentStake * 2 : _currentStake;
          bot.totalBet += betAmount;
          _pot += betAmount;
          _lastBetAmount = betAmount;
          if (!bot.isSeen) {
            bot.blindRounds++;
            if (bot.blindRounds >= _maxBlindRounds) {
              bot.isSeen = true;
            }
          }
        }

        if (!_isGameOver) {
          _currentTurnSeat = _nextActiveSeat(_currentTurnSeat);
        }
      });

      if (!_isGameOver && _currentTurnSeat != 0) {
        _triggerBotTurnIfNeeded();
      }
    });
  }

  void _showWinnerDialog(int winnerSeat) {
    final winner = _players[winnerSeat];
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: PatiiColors.navyElevated,
        shape: RoundedRectangleBorder(
          borderRadius: PatiiSpacing.rounded16,
          side: const BorderSide(color: PatiiColors.hairline),
        ),
        title: Text(
          winner.isMe ? 'teenpatti.you_won'.tr() : 'teenpatti.winner'.tr(),
          style: PatiiTypography.display(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: PatiiColors.goldLight,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 48, color: PatiiColors.gold),
            const SizedBox(height: 12),
            Text(
              'teenpatti.player_won'.tr(args: [winner.name]),
              style: PatiiTypography.body(
                fontSize: 15,
                color: PatiiColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              '+$_pot chips',
              style: PatiiTypography.display(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: PatiiColors.goldLight,
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: PatiiColors.gold,
                foregroundColor: PatiiColors.navy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogCtx);
                setState(() {
                  _roundNumber++;
                  _startNewRound();
                });
              },
              child: Text(
                'teenpatti.next_deal'.tr(),
                style: PatiiTypography.body(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: PatiiColors.navy,
                ),
              ),
            ),
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
          borderRadius: PatiiSpacing.rounded16,
          side: const BorderSide(color: PatiiColors.hairline),
        ),
        title: Row(
          children: [
            const Icon(Icons.style, color: PatiiColors.gold),
            const SizedBox(width: 8),
            Text(
              'teenpatti.rules_title'.tr(),
              style: PatiiTypography.display(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: PatiiColors.goldLight,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            'teenpatti.rules_summary'.tr(),
            style: PatiiTypography.body(
              fontSize: 13,
              color: PatiiColors.textPrimary,
              height: 1.5,
            ),
          ),
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
    final prevSeat = _previousActiveSeat(0);
    final canSideShow = _myState.isSeen &&
        _activePlayers.length > 2 &&
        _players[prevSeat].isSeen;

    // Pot lives on the table (the hero), so the HUD doesn't repeat it.
    return TableShell(
      gameTitle: 'Teen Patti',
      roundInfo: '${'table.round'.tr()} $_roundNumber · ${'teenpatti.stake'.tr()} $_currentStake',
      feltShape: TableFeltShape.oval,
      onRulesTap: _showRulesDialog,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Pot: centre of the table, slightly above middle
              Positioned(
                left: 0,
                right: 0,
                top: h * 0.36,
                child: Center(
                  child: TeenPattiPotCenter(
                    pot: _pot,
                    currentStake: _currentStake,
                    lastBetAmount: _lastBetAmount,
                  ),
                ),
              ),

              // 2. Opponents on an arc (left -> top -> right) + my seat
              TeenPattiSeatLayer(
                players: _players,
                currentTurnSeat: _currentTurnSeat,
                isGameOver: _isGameOver,
                winnerSeats: _winnerSeats,
                constraints: constraints,
              ),

              // 3. My 3 cards, right of my seat, bleeding off the bottom
              Positioned(
                left: 92,
                bottom: -14,
                child: TeenPattiHandFan(
                  cards: _myState.hand,
                  isSeen: _myState.isSeen,
                  onToggleSeen: _onToggleSeen,
                ),
              ),

              // 4. Actions in the right thumb zone
              Positioned(
                right: 12,
                bottom: 10,
                left: 300,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: TeenPattiActionBar(
                    isMyTurn: _currentTurnSeat == 0 &&
                        !_myState.isPacked &&
                        !_isGameOver,
                    isSeen: _myState.isSeen,
                    currentStake: _currentStake,
                    activePlayerCount: _activePlayers.length,
                    canSideShow: canSideShow,
                    canShow: _activePlayers.length == 2,
                    isBlindLimitReached:
                        _myState.blindRounds >= _maxBlindRounds,
                    onChaal: _onChaal,
                    onPack: _onPack,
                    onSideShow: _onSideShow,
                    onShow: _onShow,
                    onSeeCards: _onToggleSeen,
                  ),
                ),
              ),

              // 5. Parabolic Chip Toss Overlay (if active)
              if (_isTossing && _chipTossStart != null && _chipTossEnd != null)
                ChipToss(
                  startOffset: _chipTossStart!,
                  endOffset: _chipTossEnd!,
                  amount: _tossAmount,
                  onComplete: () {
                    if (mounted) setState(() => _isTossing = false);
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
