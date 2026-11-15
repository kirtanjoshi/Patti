import 'dart:async';
import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:patii_engine/patii_engine.dart' as engine;
import '../../table/widgets/seat_widget.dart';
import 'teenpatti_action_bar.dart';
import 'teenpatti_evaluator.dart';
import 'teenpatti_hand_widget.dart';
import 'teenpatti_pot_widget.dart';

/// Player state for Teen Patti table simulation.
class _PlayerState {
  final int seat;
  final String name;
  final bool isMe;
  final bool isBot;
  bool isSeen = false;
  bool isPacked = false;
  int totalBet;
  int blindRounds = 0;
  List<engine.Card> hand;

  _PlayerState({
    required this.seat,
    required this.name,
    required this.isMe,
    required this.isBot,
    this.totalBet = 100,
    required this.hand,
  });
}

/// Teen Patti Table Screen implementing PRD Section 5.3 and 10.2.
/// Supports 2 to 7 players around an oval table layout, 3-card hand display
/// with toggleable Blind/Seen mode, animated pot/chips, and action bar controls.
class TeenPattiTableScreen extends StatefulWidget {
  final int initialPlayerCount;

  const TeenPattiTableScreen({
    super.key,
    this.initialPlayerCount = 5, // PRD 5.3 default quick match: 5
  });

  @override
  State<TeenPattiTableScreen> createState() => _TeenPattiTableScreenState();
}

class _TeenPattiTableScreenState extends State<TeenPattiTableScreen> {
  static const int _bootAmount = 100;
  static const int _maxBlindRounds = 4;

  late int _playerCount;
  late List<_PlayerState> _players;
  int _currentTurnSeat = 0;
  int _currentStake = _bootAmount;
  int _pot = 0;
  int? _lastBetAmount;
  int _roundNumber = 1;
  bool _isGameOver = false;
  List<int> _winnerSeats = [];
  Timer? _botTimer;

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
      return _PlayerState(
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
      _currentTurnSeat = 0; // Local player first or dealer next
      _isGameOver = false;
      _winnerSeats = [];
    });
  }

  List<_PlayerState> get _activePlayers =>
      _players.where((p) => !p.isPacked).toList();

  _PlayerState get _myState => _players[0];

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

  void _onToggleSeen() => setState(() => _myState.isSeen = !_myState.isSeen);

  void _onChaal(int amount) {
    if (_isGameOver || _currentTurnSeat != 0) return;

    setState(() {
      _myState.totalBet += amount;
      _pot += amount;
      _lastBetAmount = amount;

      // Update stake if raise occurred
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

    if (!_isGameOver) {
      _triggerBotTurnIfNeeded();
    }
  }

  void _onSideShow() {
    final prevSeat = _previousActiveSeat(0);
    final prevPlayer = _players[prevSeat];

    // Side Show between Seat 0 and previous active seen player
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('teenpatti.sideshow'.tr()),
        content: Text('${'teenpatti.sideshow_request'.tr()} -> ${prevPlayer.name}'),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
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
      // In Teen Patti tie or lower score: requester packs
      if (scoreA <= scoreB) {
        _players[seatA].isPacked = true;
      } else {
        _players[seatB].isPacked = true;
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

    // Evaluate both players
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
    _botTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted || _isGameOver) return;

      final bot = _players[_currentTurnSeat];
      if (bot.isPacked) {
        setState(() => _currentTurnSeat = _nextActiveSeat(_currentTurnSeat));
        _triggerBotTurnIfNeeded();
        return;
      }

      // Simple heuristic bot: 10% pack, else chaal
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
        title: Text(winner.isMe ? 'teenpatti.you_won'.tr() : 'teenpatti.winner'.tr()),
        content: Text('teenpatti.player_won'.tr(args: [winner.name])),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: () {
              Navigator.pop(dialogCtx);
              setState(() {
                _roundNumber++;
                _startNewRound();
              });
            },
            child: Text('teenpatti.next_deal'.tr()),
          ),
        ],
      ),
    );
  }

  void _showRulesDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('teenpatti.rules_title'.tr()),
        content: Text('teenpatti.rules_summary'.tr()),
        actions: [
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('actions.confirm'.tr()),
          ),
        ],
      ),
    );
  }

  void _showLeaveConfirmDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('teenpatti.leave'.tr()),
        content: Text('teenpatti.leave_confirm'.tr()),
        actions: [
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('teenpatti.stay'.tr()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: () {
              Navigator.pop(dialogCtx);
              Navigator.pop(context);
            },
            child: Text('teenpatti.leave'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final prevSeat = _previousActiveSeat(0);
    final canSideShow = _myState.isSeen &&
        _activePlayers.length > 2 &&
        _players[prevSeat].isSeen;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(theme, colorScheme),

            // Oval Table Playing Area with 2 to 7 player seats
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      // Oval felt table
                      _buildOvalFelt(constraints, colorScheme),

                      // Center Pot and Stakes Display with Chip Toss Animation
                      Center(
                        child: TeenPattiPotWidget(
                          pot: _pot,
                          currentStake: _currentStake,
                          lastBetAmount: _lastBetAmount,
                        ),
                      ),

                      // Elliptical distribution of 2 to 7 players
                      ..._buildSeats(constraints),
                    ],
                  );
                },
              ),
            ),

            // User's 3-card Hand Display (with Blind/Seen 3D flip toggle)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: TeenPattiHandWidget(
                cards: _myState.hand,
                isSeen: _myState.isSeen,
                onToggleSeen: _onToggleSeen,
              ),
            ),

            // Teen Patti Action Bar
            TeenPattiActionBar(
              isMyTurn: _currentTurnSeat == 0 &&
                  !_myState.isPacked &&
                  !_isGameOver,
              isSeen: _myState.isSeen,
              currentStake: _currentStake,
              activePlayerCount: _activePlayers.length,
              canSideShow: canSideShow,
              canShow: _activePlayers.length == 2,
              isBlindLimitReached: _myState.blindRounds >= _maxBlindRounds,
              onChaal: _onChaal,
              onPack: _onPack,
              onSideShow: _onSideShow,
              onShow: _onShow,
              onSeeCards: _onToggleSeen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Semantics(
            button: true,
            label: 'teenpatti.leave'.tr(),
            child: IconButton(
              style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
              icon: const Icon(Icons.arrow_back),
              onPressed: _showLeaveConfirmDialog,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Text(
              '${'table.round'.tr()} $_roundNumber · ${'teenpatti.players_count'.tr(args: ['$_playerCount'])}',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Player count switch popup (2-7 players)
              PopupMenuButton<int>(
                icon: const Icon(Icons.group_outlined),
                tooltip: 'teenpatti.players_count'.tr(args: ['$_playerCount']),
                onSelected: (count) {
                  setState(() {
                    _playerCount = count;
                    _startNewRound();
                  });
                },
                itemBuilder: (context) => [2, 3, 4, 5, 6, 7].map(
                  (count) => PopupMenuItem(
                    value: count,
                    child: Text('teenpatti.players_count'.tr(args: ['$count'])),
                  ),
                ).toList(),
              ),
              IconButton(
                style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
                icon: const Icon(Icons.info_outline),
                onPressed: _showRulesDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOvalFelt(BoxConstraints constraints, ColorScheme colorScheme) {
    return Center(
      child: Container(
        width: constraints.maxWidth * 0.90,
        height: constraints.maxHeight * 0.86,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.all(
            Radius.elliptical(
              constraints.maxWidth * 0.45,
              constraints.maxHeight * 0.43,
            ),
          ),
          border: Border.all(
            color: colorScheme.outlineVariant,
            width: 2.0,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSeats(BoxConstraints constraints) {
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;
    final cx = w / 2;
    final cy = h / 2;
    final rx = w * 0.38;
    final ry = h * 0.35;

    return List.generate(_players.length, (i) {
      final player = _players[i];
      // Distribute seats clockwise around oval, Seat 0 at bottom center
      final angle = (math.pi / 2) + (i * 2 * math.pi / _players.length);
      final x = cx - rx * math.cos(angle - (math.pi / 2));
      final y = cy + ry * math.sin(angle - (math.pi / 2));

      final statusText = player.isPacked
          ? 'teenpatti.packed'.tr()
          : player.isSeen
              ? '${'teenpatti.seen'.tr()} · ${player.totalBet}'
              : '${'teenpatti.blind'.tr()} · ${player.totalBet}';

      final maxLeft = math.max(8.0, w - 128.0);
      final maxTop = math.max(8.0, h - 64.0);
      return Positioned(
        left: (x - 60).clamp(8.0, maxLeft),
        top: (y - 28).clamp(8.0, maxTop),
        child: SeatWidget(
          displayName: player.name,
          statusText: statusText,
          isCurrentTurn: _currentTurnSeat == player.seat && !_isGameOver,
          isBot: player.isBot,
          isPacked: player.isPacked,
          isWinner: _winnerSeats.contains(player.seat),
        ),
      );
    });
  }
}
