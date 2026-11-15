import { Card, Rank, Suit } from '../../core/types.js';
import { sameRankAndSuit } from '../../core/card.js';
import { MarriageRules } from './types.js';

export function getRankAbove(rank: Rank): Rank {
  if (rank === 13) return 1; // King -> Ace wraps
  if (rank === 0) return 0;
  return (rank + 1) as Rank;
}

export function getRankBelow(rank: Rank): Rank {
  if (rank === 1) return 13; // Ace -> King wraps
  if (rank === 0) return 0;
  return (rank - 1) as Rank;
}

export function getAlterSuit(suit: Suit): Suit {
  if (suit === 'C') return 'S';
  if (suit === 'S') return 'C';
  if (suit === 'H') return 'D';
  if (suit === 'D') return 'H';
  return 'X';
}

export interface SpecialCardsInfo {
  readonly tipluRank: Rank;
  readonly tipluSuit: Suit;
  readonly popluRank: Rank;
  readonly jhipluRank: Rank;
  readonly alterSuit: Suit;
}

export function getSpecialCardsInfo(maal: Card): SpecialCardsInfo {
  return {
    tipluRank: maal.rank,
    tipluSuit: maal.suit,
    popluRank: getRankAbove(maal.rank),
    jhipluRank: getRankBelow(maal.rank),
    alterSuit: getAlterSuit(maal.suit),
  };
}

export function isWildCard(card: Card, maal: Card | null, alterEnabled = true): boolean {
  if (!maal) return false;
  if (card.suit === 'X') return true; // Printed joker / Man card

  // Same rank as maal (Tiplu, Alter, or ordinary jokers)
  if (card.rank === maal.rank) return true;

  // Poplu (same suit, rank above)
  if (card.suit === maal.suit && card.rank === getRankAbove(maal.rank)) return true;

  // Jhiplu (same suit, rank below)
  if (card.suit === maal.suit && card.rank === getRankBelow(maal.rank)) return true;

  return false;
}

/**
 * Calculates maal points of a player's final hand as specified in PRD Section 5.2.
 */
export function calculateHandMaalPoints(
  hand: readonly Card[],
  maal: Card,
  rules: MarriageRules,
  exposedTunnelasCount = 0,
): number {
  const info = getSpecialCardsInfo(maal);

  let tipluCount = 0;
  let popluCount = 0;
  let jhipluCount = 0;
  let alterCount = 0;
  let manCount = 0;

  for (const c of hand) {
    if (c.suit === 'X') {
      manCount++;
      continue;
    }
    if (c.suit === info.tipluSuit && c.rank === info.tipluRank) {
      tipluCount++;
    } else if (c.suit === info.tipluSuit && c.rank === info.popluRank) {
      popluCount++;
    } else if (c.suit === info.tipluSuit && c.rank === info.jhipluRank) {
      jhipluCount++;
    } else if (rules.alterEnabled && c.suit === info.alterSuit && c.rank === info.tipluRank) {
      alterCount++;
    }
  }

  // Count Marriage sets (jhiplu + tiplu + poplu held together)
  const marriageSets = Math.min(tipluCount, popluCount, jhipluCount);
  tipluCount -= marriageSets;
  popluCount -= marriageSets;
  jhipluCount -= marriageSets;

  let points = 0;

  // Marriage sets: 10 for single, 30 for double
  if (marriageSets === 1) points += 10;
  else if (marriageSets >= 2) points += 30;

  // Tiplu: 1 -> 3, 2 -> 8
  if (tipluCount === 1) points += 3;
  else if (tipluCount >= 2) points += 8;

  // Poplu: 1 -> 2, 2 -> 5, 3 -> 10
  if (popluCount === 1) points += 2;
  else if (popluCount === 2) points += 5;
  else if (popluCount >= 3) points += 10;

  // Jhiplu: 1 -> 2, 2 -> 5, 3 -> 10
  if (jhipluCount === 1) points += 2;
  else if (jhipluCount === 2) points += 5;
  else if (jhipluCount >= 3) points += 10;

  // Alter: 1 -> 5, 2 -> 15, 3 -> 25
  if (rules.alterEnabled) {
    if (alterCount === 1) points += 5;
    else if (alterCount === 2) points += 15;
    else if (alterCount >= 3) points += 25;
  }

  // Man card bonus (toggle 0 or 5 each)
  points += manCount * rules.manCardPoints;

  // Tunnela bonus (5 per exposed tunnela at start)
  points += exposedTunnelasCount * 5;

  return points;
}
