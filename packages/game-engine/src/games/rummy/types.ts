import { Card, GameId, PlayerId, SeatIndex } from '../../core/types.js';

export type RummyGameMode = 'pool101' | 'pool201' | 'points' | 'deals';

export interface RummyRules {
  readonly handSize: 10 | 13;
  readonly isPaplu: boolean; // false for Nepali Rummy (10-card), true for Joker Rummy (Paplu)
  readonly gameMode: RummyGameMode;
  readonly printedJokersCount: number;
  readonly papluBonusesEnabled: boolean;
}

export const DEFAULT_NEPALI_RUMMY_RULES: RummyRules = {
  handSize: 10,
  isPaplu: false,
  gameMode: 'pool101',
  printedJokersCount: 0,
  papluBonusesEnabled: false,
};

export const DEFAULT_JOKER_RUMMY_RULES: RummyRules = {
  handSize: 13,
  isPaplu: true,
  gameMode: 'points',
  printedJokersCount: 4,
  papluBonusesEnabled: true,
};

export type RummyMove =
  | { readonly type: 'draw'; readonly source: 'stock' | 'discard' }
  | { readonly type: 'discard'; readonly cardId: string }
  | { readonly type: 'drop' }
  | { readonly type: 'declare'; readonly discardCardId: string };

export interface RummyState {
  readonly gameId: 'rummy' | 'jokerrummy';
  readonly rules: RummyRules;
  readonly seed: string;
  readonly players: readonly PlayerId[];
  readonly hands: readonly (readonly Card[])[];
  readonly cutJoker: Card;
  readonly stock: readonly Card[];
  readonly discardPile: readonly Card[];
  readonly currentTurnSeat: SeatIndex;
  readonly phase: 'draw' | 'discard';
  readonly cumulativeScores: readonly number[];
  readonly isRoundOver: boolean;
  readonly isGameOver: boolean;
  readonly winnerSeat: SeatIndex | null;
}

export interface RummyPublicView {
  readonly gameId: 'rummy' | 'jokerrummy';
  readonly rules: RummyRules;
  readonly cutJoker: Card;
  readonly topDiscard: Card | null;
  readonly stockCount: number;
  readonly currentTurnSeat: SeatIndex;
  readonly phase: 'draw' | 'discard';
  readonly isRoundOver: boolean;
  readonly isGameOver: boolean;
  readonly winnerSeat: SeatIndex | null;
  readonly players: readonly {
    readonly id: PlayerId;
    readonly seat: SeatIndex;
    readonly cardCount: number;
    readonly cumulativeScore: number;
  }[];
  readonly myHand?: readonly Card[];
}
