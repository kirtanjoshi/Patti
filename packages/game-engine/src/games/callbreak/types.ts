import { Card, GameId, PlayerId, SeatIndex } from '../../core/types.js';

export type ScoringStyle = 'nepali' | 'pagat';
export type PlayDirection = 'counterClockwise' | 'clockwise';

export interface CallbreakRules {
  readonly scoringStyle: ScoringStyle;
  readonly maxCall: 8 | 13;
  readonly mustOvertake: boolean;
  readonly noSpadeLeadFirstTrick: boolean;
  readonly noWastingTrumps: boolean;
  readonly minTotalCalls: 0 | 10;
  readonly numberOfDeals: 3 | 5 | 10;
  readonly redealNoFaceCard: boolean;
  readonly playDirection: PlayDirection;
}

export const DEFAULT_CALLBREAK_RULES: CallbreakRules = {
  scoringStyle: 'nepali',
  maxCall: 8,
  mustOvertake: true,
  noSpadeLeadFirstTrick: false,
  noWastingTrumps: false,
  minTotalCalls: 0,
  numberOfDeals: 5,
  redealNoFaceCard: false,
  playDirection: 'counterClockwise',
};

export type CallbreakMove =
  | { readonly type: 'bid'; readonly bid: number }
  | { readonly type: 'playCard'; readonly cardId: string };

export type CallbreakPhase = 'bidding' | 'playing' | 'roundOver' | 'gameOver';

export interface PlayedCard {
  readonly playerId: PlayerId;
  readonly seat: SeatIndex;
  readonly card: Card;
}

export interface CallbreakTrick {
  readonly trickNumber: number;
  readonly leaderSeat: SeatIndex;
  readonly cards: readonly PlayedCard[];
  readonly winnerSeat?: SeatIndex;
}

export interface CallbreakRoundScore {
  readonly seat: SeatIndex;
  readonly playerId: PlayerId;
  readonly bid: number;
  readonly tricksWon: number;
  readonly roundScore: number;
  readonly cumulativeScore: number;
}

export interface CallbreakState {
  readonly gameId: 'callbreak';
  readonly rules: CallbreakRules;
  readonly seed: string;
  readonly players: readonly PlayerId[];
  readonly dealerSeat: SeatIndex;
  readonly currentRound: number;
  readonly phase: CallbreakPhase;
  readonly hands: readonly (readonly Card[])[]; // SeatIndex -> cards
  readonly bids: readonly (number | null)[];
  readonly tricksWon: readonly number[];
  readonly currentTrick: CallbreakTrick;
  readonly completedTricks: readonly CallbreakTrick[];
  readonly scoresHistory: readonly (readonly CallbreakRoundScore[])[];
  readonly cumulativeScores: readonly number[];
  readonly currentTurnSeat: SeatIndex;
}

export interface CallbreakPublicView {
  readonly gameId: 'callbreak';
  readonly roundNumber: number;
  readonly phase: CallbreakPhase;
  readonly dealerSeat: SeatIndex;
  readonly currentTurnSeat: SeatIndex;
  readonly rules: CallbreakRules;
  readonly players: readonly {
    readonly id: PlayerId;
    readonly seat: SeatIndex;
    readonly cardCount: number;
    readonly bid: number | null;
    readonly tricksWon: number;
    readonly cumulativeScore: number;
  }[];
  readonly myHand?: readonly Card[];
  readonly currentTrick: readonly {
    readonly seat: SeatIndex;
    readonly card: Card;
  }[];
  readonly leadSuit?: 'S' | 'H' | 'D' | 'C' | null;
  readonly lastCompletedTrick?: CallbreakTrick;
  readonly scoresHistory: readonly (readonly CallbreakRoundScore[])[];
}
