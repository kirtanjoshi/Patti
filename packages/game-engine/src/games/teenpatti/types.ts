import { Card, GameId, PlayerId, SeatIndex } from '../../core/types.js';

export type TeenPattiVariant =
  | 'classic'
  | 'muflis'
  | 'ak47'
  | 'joker'
  | 'low_joker'
  | '999'
  | 'two_three_five';

export interface TeenPattiRules {
  readonly variant: TeenPattiVariant;
  readonly boot: number;
  readonly blindLimitRounds: number;
  readonly chaalLimitMultiplier: number;
  readonly potLimitMultiplier: number;
}

export const DEFAULT_TEEN_PATTI_RULES: TeenPattiRules = {
  variant: 'classic',
  boot: 100,
  blindLimitRounds: 4,
  chaalLimitMultiplier: 128,
  potLimitMultiplier: 1024,
};

export type TeenPattiMove =
  | { readonly type: 'blind'; readonly amount: number }
  | { readonly type: 'chaal'; readonly amount: number }
  | { readonly type: 'seeCards' }
  | { readonly type: 'pack' }
  | { readonly type: 'sideShow'; readonly targetSeat: SeatIndex }
  | { readonly type: 'show' };

export interface TeenPattiPlayerState {
  readonly playerId: PlayerId;
  readonly seat: SeatIndex;
  readonly isSeen: boolean;
  readonly isPacked: boolean;
  readonly totalBet: number;
  readonly blindRoundsPlayed: number;
}

export interface TeenPattiState {
  readonly gameId: 'teenpatti';
  readonly rules: TeenPattiRules;
  readonly seed: string;
  readonly players: readonly PlayerId[];
  readonly dealerSeat: SeatIndex;
  readonly currentTurnSeat: SeatIndex;
  readonly hands: readonly (readonly Card[])[];
  readonly playerStates: readonly TeenPattiPlayerState[];
  readonly currentStake: number;
  readonly pot: number;
  readonly isGameOver: boolean;
  readonly winnerSeats: readonly SeatIndex[];
}

export interface TeenPattiPublicView {
  readonly gameId: 'teenpatti';
  readonly rules: TeenPattiRules;
  readonly currentTurnSeat: SeatIndex;
  readonly currentStake: number;
  readonly pot: number;
  readonly isGameOver: boolean;
  readonly winnerSeats: readonly SeatIndex[];
  readonly players: readonly {
    readonly id: PlayerId;
    readonly seat: SeatIndex;
    readonly isSeen: boolean;
    readonly isPacked: boolean;
    readonly totalBet: number;
  }[];
  readonly myHand?: readonly Card[];
}
