import 'package:patii_engine/patii_engine.dart';

enum KittiHandCategory {
  highCard,
  pair,
  color,
  run,
  pureRun,
  trail,
  special235,
}

class KittiHandEvaluation {
  final KittiHandCategory category;
  final double score;
  final String labelKey;
  final List<Card> cards;

  const KittiHandEvaluation({
    required this.category,
    required this.score,
    required this.labelKey,
    required this.cards,
  });
}

class KittiEvaluator {
  static int aceHighRank(int rank) => rank == 1 ? 14 : rank;

  /// Evaluates a 3-card hand according to Kitti / Teen Patti rules (PRD 5.4).
  static KittiHandEvaluation evaluate(List<Card> cards, {bool enable235 = true}) {
    if (cards.length != 3) {
      return KittiHandEvaluation(
        category: KittiHandCategory.highCard,
        score: 0,
        labelKey: 'kitti.hands.high_card',
        cards: cards,
      );
    }

    final sortedCards = List<Card>.from(cards)
      ..sort((a, b) => aceHighRank(b.rank).compareTo(aceHighRank(a.rank)));

    final r0 = aceHighRank(sortedCards[0].rank);
    final r1 = aceHighRank(sortedCards[1].rank);
    final r2 = aceHighRank(sortedCards[2].rank);

    final s0 = sortedCards[0].suit;
    final s1 = sortedCards[1].suit;
    final s2 = sortedCards[2].suit;

    final isFlush = s0 == s1 && s1 == s2;
    final allSuitsDifferent = s0 != s1 && s1 != s2 && s0 != s2;

    // 1. Special 2-3-5 Rule (ranks above Trail when suits are all different)
    if (enable235 && allSuitsDifferent && r0 == 5 && r1 == 3 && r2 == 2) {
      return KittiHandEvaluation(
        category: KittiHandCategory.special235,
        score: 700000,
        labelKey: 'kitti.hands.special235',
        cards: sortedCards,
      );
    }

    // 2. Trail (Three of a kind)
    if (r0 == r1 && r1 == r2) {
      return KittiHandEvaluation(
        category: KittiHandCategory.trail,
        score: 600000 + r0.toDouble(),
        labelKey: 'kitti.hands.trail',
        cards: sortedCards,
      );
    }

    // Check Sequence (Straight)
    final isStandardRun = (r0 == r1 + 1 && r1 == r2 + 1);
    final isAceLowRun = (r0 == 14 && r1 == 3 && r2 == 2);
    final isStraight = isStandardRun || isAceLowRun;
    final straightValue = isAceLowRun ? 13.5 : r0.toDouble();

    // 3. Pure Run (Straight Flush)
    if (isStraight && isFlush) {
      return KittiHandEvaluation(
        category: KittiHandCategory.pureRun,
        score: 500000 + straightValue,
        labelKey: 'kitti.hands.pure_run',
        cards: sortedCards,
      );
    }

    // 4. Run (Straight)
    if (isStraight) {
      return KittiHandEvaluation(
        category: KittiHandCategory.run,
        score: 400000 + straightValue,
        labelKey: 'kitti.hands.run',
        cards: sortedCards,
      );
    }

    // 5. Color (Flush)
    if (isFlush) {
      final tieBreak = (r0 * 400 + r1 * 20 + r2).toDouble();
      return KittiHandEvaluation(
        category: KittiHandCategory.color,
        score: 300000 + tieBreak,
        labelKey: 'kitti.hands.color',
        cards: sortedCards,
      );
    }

    // 6. Pair
    if (r0 == r1 || r1 == r2 || r0 == r2) {
      final pairRank = (r0 == r1) ? r0 : ((r1 == r2) ? r1 : r0);
      final kicker = (r0 == r1) ? r2 : ((r1 == r2) ? r0 : r1);
      final pairScore = (pairRank * 20 + kicker).toDouble();
      return KittiHandEvaluation(
        category: KittiHandCategory.pair,
        score: 200000 + pairScore,
        labelKey: 'kitti.hands.pair',
        cards: sortedCards,
      );
    }

    // 7. High Card
    final highTieBreak = (r0 * 400 + r1 * 20 + r2).toDouble();
    return KittiHandEvaluation(
      category: KittiHandCategory.highCard,
      score: 100000 + highTieBreak,
      labelKey: 'kitti.hands.high_card',
      cards: sortedCards,
    );
  }

  /// Partitions 9 cards into 3 valid hands of 3 cards optimizing for Kitti
  /// (maximizing chance to win at least 2 shows and Salami bonus).
  static List<List<Card>> bestArrangement(List<Card> nineCards) {
    if (nineCards.length != 9) return [];

    List<List<Card>> bestPartition = [];
    double highestPartitionScore = -1;

    // Indices 0..8
    final indices = List<int>.generate(9, (i) => i);

    for (int i = 0; i < 7; i++) {
      for (int j = i + 1; j < 8; j++) {
        for (int k = j + 1; k < 9; k++) {
          final h1Cards = [nineCards[i], nineCards[j], nineCards[k]];
          final remaining = indices.where((x) => x != i && x != j && x != k).toList();

          // Pick 3 from the 6 remaining
          // Fixed first element to prevent symmetric duplicates
          final r0 = remaining[0];
          for (int b1 = 1; b1 < remaining.length - 1; b1++) {
            for (int b2 = b1 + 1; b2 < remaining.length; b2++) {
              final h2Indices = [r0, remaining[b1], remaining[b2]];
              final h3Indices = remaining.where((x) => !h2Indices.contains(x)).toList();

              final h2Cards = h2Indices.map((idx) => nineCards[idx]).toList();
              final h3Cards = h3Indices.map((idx) => nineCards[idx]).toList();

              final eval1 = evaluate(h1Cards);
              final eval2 = evaluate(h2Cards);
              final eval3 = evaluate(h3Cards);

              final evals = [eval1, eval2, eval3]
                ..sort((a, b) => b.score.compareTo(a.score));

              // Prioritize mid hand (2nd show win) and best hand, plus low hand
              final partitionScore = (evals[1].score * 1000000.0) +
                  (evals[0].score * 1000.0) +
                  evals[2].score;

              if (partitionScore > highestPartitionScore) {
                highestPartitionScore = partitionScore;
                bestPartition = [evals[0].cards, evals[1].cards, evals[2].cards];
              }
            }
          }
        }
      }
    }

    return bestPartition;
  }
}
