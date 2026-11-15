import { Card, GameId, PlayerId, SeatIndex } from '../../core/types.js';

export interface DhumbalRules {
  readonly callThreshold: number; // 5 default
  readonly failPenalty: number;   // 25 default
  readonly eliminationScore: number; // 100 default
  readonly jokersEnabled: boolean;
  readonly cardValuesStyle: 'app' | 'classic';
}

export const DEFAULT_DHUMBAL_RULES: DhumbalRules = {
  callThreshold: 5,
  failPenalty: 25,
  eliminationScore: 100,
  jokersEnabled: false,
  cardValuesStyle: 'app',
};

export type DhumbalMove =
  | { readonly type: 'callJhyap' }
  | { readonly type: 'playTurn'; readonly discardCards: readonly Card[]; readonly drawSource: 'stock' | 'discard' };

export interface DhumbalState {
  readonly gameId: 'dhumbal';
  readonly rules: DhumbalRules;
  readonly seed: string;
  readonly players: readonly PlayerId[];
  readonly hands: readonly (readonly Card[])[];
  readonly cumulativeScores: readonly number[];
  readonly stock: readonly Card[];
  readonly discardPile: readonly Card[];
  readonly currentTurnSeat: SeatIndex;
  readonly isRoundOver: boolean;
  readonly isGameOver: boolean;
  readonly roundWinnerSeat: SeatIndex | null;
  readonly callerSeat: SeatIndex | null;
  readonly callerSucceeded: boolean | null;
}

export interface DhumbalPublicView {
  readonly gameId: 'dhumbal';
  readonly rules: DhumbalRules;
  readonly currentTurnSeat: SeatIndex;
  readonly topDiscard: Card | null;
  readonly stockCount: number;
  readonly isRoundOver: boolean;
  readonly isGameOver: boolean;
  readonly roundWinnerSeat: SeatIndex | null;
  readonly players: readonly {
    readonly id: PlayerId;
    readonly seat: SeatIndex;
    readonly cardCount: number;
    readonly cumulativeScore: number;
  }[];
  readonly myHand?: readonly Card[];
}
