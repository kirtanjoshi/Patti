import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:patii_engine/patii_engine.dart' as engine;
import '../../../../core/widgets/player_seat.dart';

/// State representation for a player at the Teen Patti table.
class TeenPattiPlayerState {
  final int seat;
  final String name;
  final bool isMe;
  final bool isBot;
  bool isSeen = false;
  bool isPacked = false;
  int totalBet;
  int blindRounds = 0;
  List<engine.Card> hand;

  TeenPattiPlayerState({
    required this.seat,
    required this.name,
    required this.isMe,
    required this.isBot,
    this.totalBet = 100,
    required this.hand,
  });
}

/// Seats for the Teen Patti table.
///
/// "You" sit bottom-left next to your cards. Opponents are spread clockwise
/// on an arc from the left side, over the top, to the right side, so the
/// bottom band stays free for your hand and the action bar.
class TeenPattiSeatLayer extends StatelessWidget {
  final List<TeenPattiPlayerState> players;
  final int currentTurnSeat;
  final bool isGameOver;
  final List<int> winnerSeats;
  final BoxConstraints constraints;

  const TeenPattiSeatLayer({
    super.key,
    required this.players,
    required this.currentTurnSeat,
    required this.isGameOver,
    required this.winnerSeats,
    required this.constraints,
  });

  static const _seatW = 96.0;
  static const _seatH = 92.0;

  String _status(TeenPattiPlayerState p) {
    final raw = p.isPacked
        ? 'teenpatti.packed'.tr()
        : '${p.isSeen ? 'teenpatti.seen'.tr() : 'teenpatti.blind'.tr()} · ${p.totalBet}';
    return winnerSeats.contains(p.seat) ? '🏆 $raw' : raw;
  }

  @override
  Widget build(BuildContext context) {
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;
    final cx = w / 2;
    final cy = h * 0.5;
    final rx = w * 0.40;
    final ry = h * 0.40;

    final opponents = players.where((p) => !p.isMe).toList();
    final n = opponents.length;
    // Clockwise from left (~170deg) over the top (270deg) to right (~370deg).
    const start = 165.0, end = 375.0;

    return Stack(
      children: [
        for (final p in players.where((p) => p.isMe))
          Positioned(
            left: 4,
            bottom: 6,
            child: SizedBox(
              width: _seatW,
              child: PlayerSeat(
                displayName: p.name,
                isCurrentTurn: currentTurnSeat == p.seat && !isGameOver,
                isFolded: p.isPacked,
                infoPillText: _status(p),
                remainingSeconds: 12,
              ),
            ),
          ),
        for (var i = 0; i < n; i++)
          () {
            final p = opponents[i];
            final t = n == 1 ? 0.5 : i / (n - 1);
            final a = (start + (end - start) * t) * math.pi / 180;
            final x = (cx + rx * math.cos(a) - _seatW / 2)
                .clamp(4.0, math.max(4.0, w - _seatW - 4))
                .toDouble();
            final y = (cy + ry * math.sin(a) - _seatH / 2)
                .clamp(28.0, math.max(28.0, h - _seatH - 70))
                .toDouble();
            return Positioned(
              left: x,
              top: y,
              child: SizedBox(
                width: _seatW,
                child: PlayerSeat(
                  displayName: p.name,
                  isCurrentTurn: currentTurnSeat == p.seat && !isGameOver,
                  isDealer: p.seat == 1,
                  isBot: p.isBot,
                  isFolded: p.isPacked,
                  infoPillText: _status(p),
                  remainingSeconds: 10,
                ),
              ),
            );
          }(),
      ],
    );
  }
}
