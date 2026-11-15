import { Card } from '../../core/types.js';
import { CallbreakRules, CallbreakTrick, PlayedCard } from './types.js';
import { aceHighRankValue } from '../../core/card.js';

/**
 * Returns the winning PlayedCard from a trick in progress.
 */
export function getTrickWinnerCard(trick: CallbreakTrick): PlayedCard | null {
  if (trick.cards.length === 0) return null;

  const leadCard = trick.cards[0]!.card;
  let highestPlayed = trick.cards[0]!;
  let highestIsTrump = leadCard.suit === 'S';

  for (let i = 1; i < trick.cards.length; i++) {
    const candidate = trick.cards[i]!;
    const card = candidate.card;

    if (card.suit === 'S') {
      if (!highestIsTrump) {
        highestPlayed = candidate;
        highestIsTrump = true;
      } else {
        if (aceHighRankValue(card.rank) > aceHighRankValue(highestPlayed.card.rank)) {
          highestPlayed = candidate;
        }
      }
    } else if (!highestIsTrump && card.suit === leadCard.suit) {
      if (aceHighRankValue(card.rank) > aceHighRankValue(highestPlayed.card.rank)) {
        highestPlayed = candidate;
      }
    }
  }

  return highestPlayed;
}

/**
 * Determines legal cards a player can play given their hand and current trick state.
 */
export function getLegalCards(
  hand: readonly Card[],
  trick: CallbreakTrick,
  rules: CallbreakRules,
  isFirstTrickOfRound: boolean,
): Card[] {
  if (hand.length === 0) return [];

  // Trick leader
  if (trick.cards.length === 0) {
    if (isFirstTrickOfRound && rules.noSpadeLeadFirstTrick) {
      const nonSpades = hand.filter((c) => c.suit !== 'S');
      if (nonSpades.length > 0) {
        return nonSpades;
      }
    }
    return [...hand];
  }

  const leadCard = trick.cards[0]!.card;
  const leadSuit = leadCard.suit;
  const cardsInLeadSuit = hand.filter((c) => c.suit === leadSuit);
  const currentWinner = getTrickWinnerCard(trick)!;

  // 1. Must follow led suit if able
  if (cardsInLeadSuit.length > 0) {
    if (rules.mustOvertake) {
      // Must beat winning card of led suit if able (and if winning card is in led suit)
      if (currentWinner.card.suit === leadSuit) {
        const winningRank = aceHighRankValue(currentWinner.card.rank);
        const higherInSuit = cardsInLeadSuit.filter(
          (c) => aceHighRankValue(c.rank) > winningRank,
        );
        if (higherInSuit.length > 0) {
          return higherInSuit;
        }
      }
    }
    // If overtake not required or cannot beat winning card in suit, play any card in led suit
    return cardsInLeadSuit;
  }

  // 2. Void in led suit -> Must play a spade (trump) if able
  const spades = hand.filter((c) => c.suit === 'S');
  if (spades.length > 0) {
    const highestTrumpPlayed = trick.cards
      .filter((pc) => pc.card.suit === 'S')
      .reduce<number>((max, pc) => Math.max(max, aceHighRankValue(pc.card.rank)), 0);

    if (highestTrumpPlayed > 0) {
      // A spade was already played in this trick
      const higherSpades = spades.filter(
        (c) => aceHighRankValue(c.rank) > highestTrumpPlayed,
      );

      if (higherSpades.length > 0) {
        return higherSpades;
      }

      // Cannot beat the spade that is already down
      if (rules.noWastingTrumps) {
        // Cannot play an under-trump unless forced (i.e. player only holds spades)
        const nonSpades = hand.filter((c) => c.suit !== 'S');
        if (nonSpades.length > 0) {
          return nonSpades;
        }
      }
    }

    // Default: Can play any spade (or any card if spade was down and no higher spade)
    return [...hand];
  }

  // 3. Void in led suit and holds no spades -> Can play any card
  return [...hand];
}

/**
 * Checks if a dealt hand triggers a redeal according to rules.
 */
export function checkRedeal(hands: readonly (readonly Card[])[], rules: CallbreakRules): boolean {
  for (const hand of hands) {
    const spadeCount = hand.filter((c) => c.suit === 'S').length;
    if (spadeCount === 0) {
      return true; // Default: redeal if any player holds no spade
    }
    if (rules.redealNoFaceCard) {
      const faceCardCount = hand.filter(
        (c) => c.rank === 1 || c.rank === 11 || c.rank === 12 || c.rank === 13,
      ).length;
      if (faceCardCount === 0) {
        return true;
      }
    }
  }
  return false;
}
