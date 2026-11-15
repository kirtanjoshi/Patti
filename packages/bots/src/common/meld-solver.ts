import { Card, aceHighRankValue, sameRankAndSuit } from '@patii/game-engine';

export type MeldType =
  | 'pure_sequence'
  | 'sequence'
  | 'set'
  | 'tunnela'
  | 'dublee';

export interface Meld {
  readonly type: MeldType;
  readonly cards: readonly Card[];
}

export interface MeldSolution {
  readonly melds: readonly Meld[];
  readonly deadwood: readonly Card[];
  readonly deadwoodPoints: number;
  readonly isComplete: boolean;
}

export class MeldSolver {
  /**
   * Checks if 3 cards form a valid Tunnela (three identical cards in rank and suit).
   */
  public static isTunnela(cards: readonly Card[]): boolean {
    if (cards.length !== 3) return false;
    const [c0, c1, c2] = [cards[0]!, cards[1]!, cards[2]!];
    return (
      c0.suit !== 'X' &&
      sameRankAndSuit(c0, c1) &&
      sameRankAndSuit(c1, c2) &&
      c0.id !== c1.id &&
      c1.id !== c2.id &&
      c0.id !== c2.id
    );
  }

  /**
   * Checks if 2 cards form a valid Dublee (two identical cards in rank and suit).
   */
  public static isDublee(cards: readonly Card[]): boolean {
    if (cards.length !== 2) return false;
    const [c0, c1] = [cards[0]!, cards[1]!];
    return c0.suit !== 'X' && sameRankAndSuit(c0, c1) && c0.id !== c1.id;
  }

  /**
   * Checks if cards form a Pure Sequence (3+ cards, same suit, consecutive ranks, no wilds).
   */
  public static isPureSequence(cards: readonly Card[]): boolean {
    if (cards.length < 3) return false;
    const suit = cards[0]!.suit;
    if (suit === 'X' || !cards.every((c) => c.suit === suit)) return false;

    // Check rank continuity (Ace high or Ace low)
    const sortedRanks = cards.map((c) => c.rank).sort((a, b) => a - b);

    // Standard run: e.g. 4, 5, 6
    let isRun = true;
    for (let i = 0; i < sortedRanks.length - 1; i++) {
      if (sortedRanks[i + 1]! !== sortedRanks[i]! + 1) {
        isRun = false;
        break;
      }
    }
    if (isRun) return true;

    // Check Ace high: 12, 13, 1 (Q, K, A)
    if (sortedRanks.includes(1)) {
      const aceHighRanks = cards.map((c) => aceHighRankValue(c.rank)).sort((a, b) => a - b);
      let isAceHighRun = true;
      for (let i = 0; i < aceHighRanks.length - 1; i++) {
        if (aceHighRanks[i + 1]! !== aceHighRanks[i]! + 1) {
          isAceHighRun = false;
          break;
        }
      }
      if (isAceHighRun) return true;
    }

    return false;
  }

  /**
   * Checks if cards form a valid Set (3 or 4 cards of same rank in different suits).
   */
  public static isSet(cards: readonly Card[]): boolean {
    if (cards.length < 3 || cards.length > 4) return false;
    const rank = cards[0]!.rank;
    if (rank === 0 || !cards.every((c) => c.rank === rank)) return false;

    // All suits must be distinct
    const suits = new Set(cards.map((c) => c.suit));
    return suits.size === cards.length;
  }

  /**
   * Calculates deadwood points (unmelded cards) according to Rummy rules:
   * 2-10 face value, J/Q/K/A = 10, Wilds = 0.
   */
  public static calculateDeadwoodPoints(cards: readonly Card[]): number {
    let sum = 0;
    for (const c of cards) {
      if (c.suit === 'X' || c.rank === 0) continue;
      if (c.rank === 1 || c.rank >= 10) {
        sum += 10;
      } else {
        sum += c.rank;
      }
    }
    return sum;
  }
}
