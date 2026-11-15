class CallbreakRoundScore {
  final int seat;
  final String playerId;
  final int bid;
  final int tricksWon;
  final double roundScore;
  final double cumulativeScore;

  const CallbreakRoundScore({
    required this.seat,
    required this.playerId,
    required this.bid,
    required this.tricksWon,
    required this.roundScore,
    required this.cumulativeScore,
  });
}

class CallbreakScoring {
  static double round(double val, int decimals) {
    return double.parse(val.toStringAsFixed(decimals));
  }

  static List<CallbreakRoundScore> calculateRoundScores({
    required String scoringStyle, // 'nepali' | 'pagat'
    required List<String> players,
    required List<int> bids,
    required List<int> tricksWon,
    required List<double> previousCumulative,
  }) {
    final result = <CallbreakRoundScore>[];

    for (int seat = 0; seat < 4; seat++) {
      final bid = bids[seat];
      final tricks = tricksWon[seat];
      double roundScore = 0.0;

      if (scoringStyle == 'nepali') {
        if (tricks >= bid) {
          final extra = tricks - bid;
          roundScore = round(bid + extra * 0.1, 1);
        } else {
          roundScore = -bid.toDouble();
        }
      } else {
        // Pagat classic:
        if (bid >= 8 && tricks >= bid) {
          roundScore = 13.0;
        } else if (tricks == bid) {
          roundScore = bid.toDouble();
        } else if (tricks == bid + 1) {
          roundScore = round(bid + 0.1, 1);
        } else {
          roundScore = -bid.toDouble();
        }
      }

      final prev = seat < previousCumulative.length ? previousCumulative[seat] : 0.0;
      final cumulative = round(prev + roundScore, 1);

      result.add(CallbreakRoundScore(
        seat: seat,
        playerId: players[seat],
        bid: bid,
        tricksWon: tricks,
        roundScore: roundScore,
        cumulativeScore: cumulative,
      ));
    }

    return result;
  }
}
