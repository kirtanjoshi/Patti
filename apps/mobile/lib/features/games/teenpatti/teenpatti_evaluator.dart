import 'package:easy_localization/easy_localization.dart';
import 'package:patii_engine/patii_engine.dart';

/// 3-card hand evaluator for Teen Patti adhering to PRD Section 5.3.
/// Ranking (high to low): Trail > Pure Sequence > Sequence > Color > Pair > High Card.
class TeenPattiEvaluator {
  const TeenPattiEvaluator._();

  static int evaluateScore(List<Card> hand) {
    if (hand.length < 3) return 0;
    final ranks = hand.map((c) => c.rank == 1 ? 14 : c.rank).toList()
      ..sort((a, b) => b.compareTo(a));
    final suits = hand.map((c) => c.suit).toList();
    final isFlush = suits[0] == suits[1] && suits[1] == suits[2];
    final r0 = ranks[0], r1 = ranks[1], r2 = ranks[2];

    // 1. Trail (Three of a kind)
    if (r0 == r1 && r1 == r2) return 600000 + r0;

    // 2. Straight (Sequence)
    final isStandardRun = (r0 == r1 + 1 && r1 == r2 + 1);
    final isAceLowRun = (r0 == 14 && r1 == 3 && r2 == 2);
    final isStraight = isStandardRun || isAceLowRun;
    final straightVal = isAceLowRun ? 13 : r0;

    // Pure Sequence (Straight Flush)
    if (isStraight && isFlush) return 500000 + straightVal;

    // Sequence (Straight)
    if (isStraight) return 400000 + straightVal;

    // Color (Flush)
    if (isFlush) return 300000 + r0 * 400 + r1 * 20 + r2;

    // Pair
    if (r0 == r1 || r1 == r2 || r0 == r2) {
      final pairRank = r0 == r1 ? r0 : (r1 == r2 ? r1 : r0);
      final kicker = r0 == r1 ? r2 : (r1 == r2 ? r0 : r1);
      return 200000 + pairRank * 20 + kicker;
    }

    // High Card
    return 100000 + r0 * 400 + r1 * 20 + r2;
  }

  static List<Card> createShuffledDeck() {
    return [
      for (final suit in [Suit.S, Suit.H, Suit.D, Suit.C])
        for (int rank = 1; rank <= 13; rank++)
          Card(suit: suit, rank: rank, deck: 0, id: '$rank${suit.name}0'),
    ]..shuffle();
  }

  static String evaluateRankName(List<Card> hand) {
    if (hand.length < 3) return '';
    final ranks = hand.map((c) => c.rank == 1 ? 14 : c.rank).toList()
      ..sort((a, b) => b.compareTo(a));
    final suits = hand.map((c) => c.suit).toList();
    final isFlush = suits[0] == suits[1] && suits[1] == suits[2];
    final r0 = ranks[0], r1 = ranks[1], r2 = ranks[2];

    if (r0 == r1 && r1 == r2) {
      return 'teenpatti.hands.trail'.tr();
    }
    final isStandardRun = (r0 == r1 + 1 && r1 == r2 + 1);
    final isAceLowRun = (r0 == 14 && r1 == 3 && r2 == 2);
    final isStraight = isStandardRun || isAceLowRun;

    if (isStraight && isFlush) {
      return 'teenpatti.hands.pure_sequence'.tr();
    }
    if (isStraight) {
      return 'teenpatti.hands.sequence'.tr();
    }
    if (isFlush) {
      return 'teenpatti.hands.color'.tr();
    }
    if (r0 == r1 || r1 == r2 || r0 == r2) {
      return 'teenpatti.hands.pair'.tr();
    }
    return 'teenpatti.hands.high_card'.tr();
  }
}
