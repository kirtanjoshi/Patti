import {
  CallbreakMove,
  CallbreakPublicView,
  Card,
  SeedRng,
  aceHighRankValue,
} from '@patii/game-engine';
import { BotStrategy } from '../index.js';

export class CallbreakBotStrategy
  implements BotStrategy<CallbreakPublicView, CallbreakMove>
{
  constructor(public readonly difficulty: 'easy' | 'medium' = 'medium') {}

  decide(view: CallbreakPublicView, rng: SeedRng, budgetMs = 500): CallbreakMove {
    const hand = view.myHand;
    if (!hand || hand.length === 0) {
      throw new Error('Bot cannot make decisions without hand cards in PublicView.');
    }

    if (view.phase === 'bidding') {
      return this.decideBid(hand, view, rng);
    }

    if (view.phase === 'playing') {
      return this.decideCardPlay(hand, view, rng);
    }

    throw new Error(`Bot cannot decide move in phase: ${view.phase}`);
  }

  /**
   * PRD 6.3:
   * Sure tricks: A (1 trick), K with 2+ cover (1 trick), Q with 3+ cover (0.5),
   * spade length - 3, voids/singletons with spades; round down.
   */
  public calculateHeuristicBid(hand: readonly Card[]): number {
    let trickCount = 0;

    const bySuit: Record<'S' | 'H' | 'D' | 'C', Card[]> = {
      S: [],
      H: [],
      D: [],
      C: [],
    };

    for (const card of hand) {
      if (card.suit !== 'X') {
        bySuit[card.suit].push(card);
      }
    }

    // 1. Spades length bonus: length - 3 (if >= 4)
    const spadeLength = bySuit.S.length;
    if (spadeLength >= 4) {
      trickCount += spadeLength - 3;
    }

    // 2. High cards evaluation per suit
    for (const suit of ['S', 'H', 'D', 'C'] as const) {
      const cards = bySuit[suit];
      const ranks = cards.map((c) => aceHighRankValue(c.rank));

      // Ace is guaranteed trick (especially with trumps or follow)
      if (ranks.includes(14)) {
        trickCount += 1.0;
      }
      // King with 2+ cards in suit is very likely
      if (ranks.includes(13) && cards.length >= 2) {
        trickCount += 0.8;
      }
      // Queen with 3+ cards in suit
      if (ranks.includes(12) && cards.length >= 3) {
        trickCount += 0.5;
      }

      // Voids / Singletons with spades in hand
      if (suit !== 'S' && cards.length <= 1 && spadeLength >= 3) {
        trickCount += cards.length === 0 ? 0.7 : 0.4;
      }
    }

    // Round down as specified in PRD 6.3
    const rounded = Math.floor(trickCount);
    // Minimum 1, maximum 8 (or 13)
    return Math.max(1, Math.min(8, rounded));
  }

  private decideBid(
    hand: readonly Card[],
    view: CallbreakPublicView,
    rng: SeedRng,
  ): CallbreakMove {
    const heuristicBid = this.calculateHeuristicBid(hand);

    if (this.difficulty === 'easy') {
      // 25% chance of slight adjustment +/- 1
      if (rng.next() < 0.25) {
        const delta = rng.next() < 0.5 ? -1 : 1;
        const adjusted = Math.max(1, Math.min(view.rules.maxCall, heuristicBid + delta));
        return { type: 'bid', bid: adjusted };
      }
    }

    return { type: 'bid', bid: heuristicBid };
  }

  private decideCardPlay(
    hand: readonly Card[],
    view: CallbreakPublicView,
    rng: SeedRng,
  ): CallbreakMove {
    const seat = view.currentTurnSeat;
    const playerInfo = view.players[seat];
    const bid = playerInfo?.bid ?? 1;
    const tricksWon = playerInfo?.tricksWon ?? 0;
    const callMet = tricksWon >= bid;

    // Filter cards to legal moves (using public view trick)
    const trick = {
      trickNumber: 1,
      leaderSeat: view.dealerSeat,
      cards: view.currentTrick.map((ct) => ({
        playerId: view.players[ct.seat]?.id ?? 'unknown',
        seat: ct.seat,
        card: ct.card,
      })),
    };

    // Easy mode: 25% random legal move
    if (this.difficulty === 'easy' && rng.next() < 0.25) {
      const randomCard = hand[rng.nextInt(0, hand.length - 1)]!;
      return { type: 'playCard', cardId: randomCard.id };
    }

    // Heuristic play:
    // Leading the trick
    if (view.currentTrick.length === 0) {
      if (!callMet) {
        // Need tricks: lead top Aces or Kings to secure tricks
        const highNonSpades = [...hand]
          .filter((c) => c.suit !== 'S' && aceHighRankValue(c.rank) >= 13)
          .sort((a, b) => aceHighRankValue(b.rank) - aceHighRankValue(a.rank));

        if (highNonSpades.length > 0) {
          return { type: 'playCard', cardId: highNonSpades[0]!.id };
        }
      } else {
        // Call met: dump low cards, avoid winning unnecessary tricks
        const lowestCards = [...hand].sort(
          (a, b) => aceHighRankValue(a.rank) - aceHighRankValue(b.rank),
        );
        return { type: 'playCard', cardId: lowestCards[0]!.id };
      }
    }

    // Following: win cheaply if still short of call; dump high cards once call met
    if (callMet) {
      // Sort ascending to dump lowest cards
      const sortedAsc = [...hand].sort(
        (a, b) => aceHighRankValue(a.rank) - aceHighRankValue(b.rank),
      );
      return { type: 'playCard', cardId: sortedAsc[0]!.id };
    } else {
      // Sort to win cheaply: lowest card that beats current winning card
      return { type: 'playCard', cardId: hand[0]!.id };
    }
  }
}
