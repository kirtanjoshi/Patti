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

/// Widget that builds all seat positions distributed evenly around the oval felt.
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

  @override
  Widget build(BuildContext context) {
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;
    final cx = w / 2;
    final cy = h / 2 - 14; // slight vertical bias upwards to clear bottom hand
    final rx = w * 0.40;
    final ry = h * 0.36;

    final maxLeft = math.max(8.0, w - 80.0);
    final maxTop = math.max(8.0, h - 80.0);

    return Stack(
      children: List.generate(players.length, (i) {
        final player = players[i];
        // Distribute seats around oval: Seat 0 at bottom center (angle = pi/2)
        final angle = (math.pi / 2) + (i * 2 * math.pi / players.length);
        final x = cx - rx * math.cos(angle - (math.pi / 2));
        final y = cy + ry * math.sin(angle - (math.pi / 2));

        // Info text for seat pill
        final isWinner = winnerSeats.contains(player.seat);
        final rawStatus = player.isPacked
            ? 'teenpatti.packed'.tr()
            : player.isSeen
                ? '${'teenpatti.seen'.tr()} · ${player.totalBet}'
                : '${'teenpatti.blind'.tr()} · ${player.totalBet}';
        final infoText = isWinner ? '🏆 $rawStatus' : rawStatus;

        // Seat 0 (You) is handled cleanly near bottom center
        if (player.isMe) {
          return Positioned(
            left: (cx - 36).clamp(8.0, maxLeft),
            bottom: 74,
            child: PlayerSeat(
              displayName: player.name,
              isCurrentTurn: currentTurnSeat == 0 && !isGameOver,
              isDealer: false,
              isBot: false,
              isFolded: player.isPacked,
              infoPillText: infoText,
              remainingSeconds: currentTurnSeat == 0 ? 12 : 15,
            ),
          );
        }

        return Positioned(
          left: (x - 36).clamp(8.0, maxLeft),
          top: (y - 36).clamp(8.0, maxTop),
          child: PlayerSeat(
            displayName: player.name,
            isCurrentTurn: currentTurnSeat == player.seat && !isGameOver,
            isDealer: player.seat == 1,
            isBot: player.isBot,
            isFolded: player.isPacked,
            infoPillText: infoText,
            remainingSeconds: currentTurnSeat == player.seat ? 10 : 15,
          ),
        );
      }),
    );
  }
}
