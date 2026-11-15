import { Card, GameId, PlayerId, SeatIndex } from '../../core/types.js';

export interface JutpattiRules {
  readonly handSize: 5 | 7 | 9 | 11;
  readonly jokerCardEnabled: boolean;
  readonly pointsMode: boolean;
}

export const DEFAULT_JUTPATTI_RULES: JutpattiRules = {
  handSize: 9,
  jokerCardEnabled: true,
  pointsMode: false,
};

export type JutpattiMove =
  | { readonly type: 'draw'; readonly source: 'stock' | 'discard' }
  | { readonly type: 'discard'; readonly cardId: string }
  | { readonly type: 'declare' };

export interface JutpattiState {
  readonly gameId: 'jutpatti';
  readonly rules: JutpattiRules;
  readonly seed: string;
  readonly players: readonly PlayerId[];
  readonly hands: readonly (readonly Card[])[];
  readonly jokerCard: Card | null;
  readonly stock: readonly Card[];
  readonly discardPile: readonly Card[];
  readonly currentTurnSeat: SeatIndex;
  readonly phase: 'draw' | 'discard';
  readonly isGameOver: boolean;
  readonly winnerSeat: SeatIndex | null;
}

export interface JutpattiPublicView {
  readonly gameId: 'jutpatti';
  readonly rules: JutpattiRules;
  readonly jokerCard: Card | null;
  readonly topDiscard: Card | null;
  readonly stockCount: number;
  readonly currentTurnSeat: SeatIndex;
  readonly phase: 'draw' | 'discard';
  readonly isGameOver: boolean;
  readonly winnerSeat: SeatIndex | null;
  readonly players: readonly {
    readonly id: PlayerId;
    readonly seat: SeatIndex;
    readonly cardCount: number;
  }[];
  readonly myHand?: readonly Card[];
}
