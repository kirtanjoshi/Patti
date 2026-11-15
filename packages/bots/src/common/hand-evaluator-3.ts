import { Card, aceHighRankValue } from '@patii/game-engine';

export enum HandCategory {
  HIGH_CARD = 1,
  PAIR = 2,
  COLOR = 3,          // Flush
  SEQUENCE = 4,       // Straight
  PURE_SEQUENCE = 5,  // Straight flush
  TRAIL = 6,          // Three of a kind
}

export interface HandEvaluation3 {
  readonly category: HandCategory;
  readonly score: number; // Higher is better
  readonly rankName: string;
}

/**
 * HandEvaluator3: Evaluates 3-card hands for Teen Patti and Kitti (PRD 6.4 & 5.3).
 * Hand ranking: Trail > Pure sequence > Sequence > Color > Pair > High card.
 */
export class HandEvaluator3 {
  public static evaluate(cards: readonly Card[], variant = 'classic'): HandEvaluation3 {
    if (cards.length !== 3) {
      throw new Error(`HandEvaluator3 requires exactly 3 cards, got ${cards.length}`);
    }

    const ranks = cards.map((c) => aceHighRankValue(c.rank)).sort((a, b) => b - a);
    const suits = cards.map((c) => c.suit);
    const isFlush = suits[0] === suits[1] && suits[1] === suits[2];

    const [r0, r1, r2] = [ranks[0]!, ranks[1]!, ranks[2]!];

    // 1. Trail (Three of a kind)
    if (r0 === r1 && r1 === r2) {
      return {
        category: HandCategory.TRAIL,
        score: 600000 + r0,
        rankName: 'Trail',
      };
    }

    // Check Sequence (Straight)
    // In Teen Patti: A-K-Q (14, 13, 12) is highest, followed by A-2-3 (14, 3, 2), then K-Q-J ...
    const isStandardRun = (r0 === r1 + 1 && r1 === r2 + 1);
    const isAceLowRun = (r0 === 14 && r1 === 3 && r2 === 2);
    const isStraight = isStandardRun || isAceLowRun;

    // Run rank value for tie breaking: A-K-Q is 14, A-2-3 is 13.5 (second highest in Indian/Nepali rules), else r0
    const straightValue = isAceLowRun ? 13.5 : r0;

    // 2. Pure Sequence (Straight Flush)
    if (isStraight && isFlush) {
      return {
        category: HandCategory.PURE_SEQUENCE,
        score: 500000 + straightValue,
        rankName: 'Pure Sequence',
      };
    }

    // 3. Sequence (Straight)
    if (isStraight) {
      return {
        category: HandCategory.SEQUENCE,
        score: 400000 + straightValue,
        rankName: 'Sequence',
      };
    }

    // 4. Color (Flush)
    if (isFlush) {
      const tieBreak = r0 * 400 + r1 * 20 + r2;
      return {
        category: HandCategory.COLOR,
        score: 300000 + tieBreak,
        rankName: 'Color',
      };
    }

    // 5. Pair
    if (r0 === r1 || r1 === r2 || r0 === r2) {
      const pairRank = r0 === r1 ? r0 : (r1 === r2 ? r1 : r0);
      const kicker = r0 === r1 ? r2 : (r1 === r2 ? r0 : r1);
      return {
        category: HandCategory.PAIR,
        score: 200000 + pairRank * 20 + kicker,
        rankName: 'Pair',
      };
    }

    // 6. High Card
    const highTieBreak = r0 * 400 + r1 * 20 + r2;
    return {
      category: HandCategory.HIGH_CARD,
      score: 100000 + highTieBreak,
      rankName: 'High Card',
    };
  }

  /**
   * Compares hand A vs hand B.
   * Returns > 0 if A beats B, < 0 if B beats A, 0 if tie.
   */
  public static compare(handA: readonly Card[], handB: readonly Card[], variant = 'classic'): number {
    const evalA = this.evaluate(handA, variant);
    const evalB = this.evaluate(handB, variant);
    return evalA.score - evalB.score;
  }
}
