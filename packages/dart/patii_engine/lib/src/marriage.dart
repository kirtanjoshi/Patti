class SettlementPlayer {
  final int seat;
  final int rawMaalPoints;
  final bool hasSeenMaal;

  const SettlementPlayer({
    required this.seat,
    required this.rawMaalPoints,
    required this.hasSeenMaal,
  });
}

class MarriageSettlementResult {
  final int seat;
  final int paymentToWinner; // P_i
  final int coinDelta;

  const MarriageSettlementResult({
    required this.seat,
    required this.paymentToWinner,
    required this.coinDelta,
  });
}

class MarriageScoring {
  static List<MarriageSettlementResult> calculateMarriageSettlement({
    required List<SettlementPlayer> players,
    required int winnerSeat,
    required bool finishedWithDublees,
    required String mode, // 'classic' | 'murder' | 'kidnap'
    int unseenPenalty = 10,
    int seenPenalty = 3,
    int pointRate = 10,
  }) {
    final n = players.length;
    var adjustedMaal = players.map((p) => p.rawMaalPoints).toList();
    var kidnappedPoints = 0;

    if (mode == 'murder') {
      adjustedMaal = players.map((p) => p.hasSeenMaal ? p.rawMaalPoints : 0).toList();
    } else if (mode == 'kidnap') {
      adjustedMaal = [];
      for (int i = 0; i < players.length; i++) {
        final p = players[i];
        if (i == winnerSeat) {
          adjustedMaal.add(p.rawMaalPoints);
        } else if (!p.hasSeenMaal) {
          kidnappedPoints += p.rawMaalPoints;
          adjustedMaal.add(0);
        } else {
          adjustedMaal.add(p.rawMaalPoints);
        }
      }
      adjustedMaal[winnerSeat] += kidnappedPoints;
    }

    final int T = adjustedMaal.fold(0, (sum, val) => sum + val);
    final results = <MarriageSettlementResult>[];
    int winnerGain = 0;

    for (int i = 0; i < n; i++) {
      if (i == winnerSeat) continue;

      final player = players[i];
      int wI = player.hasSeenMaal ? seenPenalty : unseenPenalty;
      if (finishedWithDublees) {
        wI += 5;
      }

      final sI = adjustedMaal[i];
      final pI = T + wI - n * sI;
      final coinDelta = -pI * pointRate;
      winnerGain += pI * pointRate;

      results.add(MarriageSettlementResult(
        seat: i,
        paymentToWinner: pI,
        coinDelta: coinDelta,
      ));
    }

    results.add(MarriageSettlementResult(
      seat: winnerSeat,
      paymentToWinner: 0,
      coinDelta: winnerGain,
    ));

    results.sort((a, b) => a.seat.compareTo(b.seat));
    return results;
  }
}
