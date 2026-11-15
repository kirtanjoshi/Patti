import { Card, DeckIndex, Rank, Suit } from './types.js';

export const STANDARD_SUITS: readonly Suit[] = ['S', 'H', 'D', 'C'] as const;

export const RANK_NAMES: Record<Rank, string> = {
  0: 'X',
  1: 'A',
  2: '2',
  3: '3',
  4: '4',
  5: '5',
  6: '6',
  7: '7',
  8: '8',
  9: '9',
  10: '10',
  11: 'J',
  12: 'Q',
  13: 'K',
};

export function cardId(suit: Suit, rank: Rank, deck: DeckIndex, extraId?: string): string {
  if (suit === 'X') {
    return `X0_${deck}${extraId ? `_${extraId}` : ''}`;
  }
  return `${RANK_NAMES[rank]}${suit}${deck}`;
}

export function createCard(suit: Suit, rank: Rank, deck: DeckIndex = 0, extraId?: string): Card {
  return {
    suit,
    rank,
    deck,
    id: cardId(suit, rank, deck, extraId),
  };
}

export function createJoker(deck: DeckIndex = 0, index = 0): Card {
  return {
    suit: 'X',
    rank: 0,
    deck,
    id: cardId('X', 0, deck, `${index}`),
  };
}

export function createStandardDeck(deckIndex: DeckIndex = 0): Card[] {
  const cards: Card[] = [];
  for (const suit of STANDARD_SUITS) {
    for (let rank = 1; rank <= 13; rank++) {
      cards.push(createCard(suit, rank as Rank, deckIndex));
    }
  }
  return cards;
}

export function createMultiDeck(
  numDecks: 1 | 2 | 3 = 1,
  printedJokersPerDeck = 0,
): Card[] {
  const deck: Card[] = [];
  for (let d = 0; d < numDecks; d++) {
    const deckIdx = d as DeckIndex;
    deck.push(...createStandardDeck(deckIdx));
    for (let j = 0; j < printedJokersPerDeck; j++) {
      deck.push(createJoker(deckIdx, j));
    }
  }
  return deck;
}

export function sameRankAndSuit(a: Card, b: Card): boolean {
  return a.suit === b.suit && a.rank === b.rank;
}

export function isExactCard(a: Card, b: Card): boolean {
  return a.id === b.id;
}

export function aceHighRankValue(rank: Rank): number {
  if (rank === 1) return 14;
  return rank;
}

export function aceLowRankValue(rank: Rank): number {
  return rank;
}
