import { Card, GameId, PlayerId, SeatIndex } from '../../core/types.js';

export type MarriageMode = 'classic' | 'murder' | 'kidnap';

export interface MarriageRules {
  readonly mode: MarriageMode;
  readonly alterEnabled: boolean;
  readonly manCardsCount: 0 | 1 | 2 | 3;
  readonly manCardPoints: 0 | 5;
  readonly dubleeRouteEnabled: boolean;
  readonly stockOutRule: 'reshuffle' | 'void';
  readonly unseenPenalty: number; // 10 default (5-20)
  readonly seenPenalty: number;   // 3 default
  readonly pointRate: number;     // 10 coins per point default
}

export const DEFAULT_MARRIAGE_RULES: MarriageRules = {
  mode: 'classic',
  alterEnabled: true,
  manCardsCount: 0,
  manCardPoints: 0,
  dubleeRouteEnabled: true,
  stockOutRule: 'reshuffle',
  unseenPenalty: 10,
  seenPenalty: 3,
  pointRate: 10,
};

export type MarriageMove =
  | { readonly type: 'draw'; readonly source: 'stock' | 'discard' }
  | { readonly type: 'seeMaal'; readonly pureCombinations: readonly (readonly Card[])[] }
  | { readonly type: 'seeMaalDublee'; readonly dublees: readonly (readonly [Card, Card])[] }
  | { readonly type: 'finish'; readonly combinations: readonly (readonly Card[])[]; readonly discardCardId: string }
  | { readonly type: 'discard'; readonly cardId: string };

export interface MarriagePlayerState {
  readonly playerId: PlayerId;
  readonly seat: SeatIndex;
  readonly hasSeenMaal: boolean;
  readonly exposedTunnelasAtStart: readonly (readonly Card[])[];
  readonly maalPoints: number;
}

export interface MarriageState {
  readonly gameId: 'marriage';
  readonly rules: MarriageRules;
  readonly seed: string;
  readonly players: readonly PlayerId[];
  readonly hands: readonly (readonly Card[])[];
  readonly playerStates: readonly MarriagePlayerState[];
  readonly stock: readonly Card[];
  readonly discardPile: readonly Card[];
  readonly maalCard: Card | null;
  readonly currentTurnSeat: SeatIndex;
  readonly phase: 'draw' | 'discard';
  readonly isGameOver: boolean;
  readonly winnerSeat: SeatIndex | null;
  readonly settlements: readonly {
    readonly seat: SeatIndex;
    readonly paymentToWinner: number;
    readonly coinDelta: number;
  }[];
}

export interface MarriagePublicView {
  readonly gameId: 'marriage';
  readonly rules: MarriageRules;
  readonly currentTurnSeat: SeatIndex;
  readonly phase: 'draw' | 'discard';
  readonly topDiscard: Card | null;
  readonly stockCount: number;
  readonly maalCard: Card | null; // Null until player has seen maal
  readonly isGameOver: boolean;
  readonly winnerSeat: SeatIndex | null;
  readonly players: readonly {
    readonly id: PlayerId;
    readonly seat: SeatIndex;
    readonly cardCount: number;
    readonly hasSeenMaal: boolean;
  }[];
  readonly myHand?: readonly Card[];
}
