import { describe, expect, it } from 'vitest';
import {
  aceHighRankValue,
  aceLowRankValue,
  createCard,
  createJoker,
  createMultiDeck,
  createStandardDeck,
  isExactCard,
  sameRankAndSuit,
} from '../src/core/card.js';

describe('Card Model & Creation', () => {
  it('creates unique card representations', () => {
    const card1 = createCard('S', 12, 0); // Queen of Spades deck 0
    expect(card1.id).toBe('QS0');
    expect(card1.suit).toBe('S');
    expect(card1.rank).toBe(12);
    expect(card1.deck).toBe(0);

    const card2 = createCard('S', 12, 1); // Queen of Spades deck 1
    expect(card2.id).toBe('QS1');
    expect(sameRankAndSuit(card1, card2)).toBe(true);
    expect(isExactCard(card1, card2)).toBe(false);
  });

  it('creates standard 52-card deck with unique IDs', () => {
    const deck = createStandardDeck(0);
    expect(deck).toHaveLength(52);
    const ids = new Set(deck.map((c) => c.id));
    expect(ids.size).toBe(52);
  });

  it('creates multi-deck with printed jokers correctly for Marriage', () => {
    // 3 decks with 1 printed joker per deck = 156 + 3 = 159 cards
    const multiDeck = createMultiDeck(3, 1);
    expect(multiDeck).toHaveLength(159);
    const jokers = multiDeck.filter((c) => c.suit === 'X');
    expect(jokers).toHaveLength(3);
  });

  it('evaluates Ace high and Ace low rank values', () => {
    expect(aceHighRankValue(1)).toBe(14);
    expect(aceHighRankValue(13)).toBe(13);
    expect(aceLowRankValue(1)).toBe(1);
    expect(aceLowRankValue(13)).toBe(13);
  });
});
