import { Card, GameId, PlayerId, SeatIndex } from '../../core/types.js';

export interface KittiRules {
  readonly winRule: 'any_two' | 'two_consecutive';
  readonly salamiBonus: boolean;
  readonly twoThreeFiveRule: boolean;
  readonly maxKittiCarryOvers: number;
}

export const DEFAULT_KITTI_RULES: KittiRules = {
  winRule: 'any_two',
  salamiBonus: true,
  twoThreeFiveRule: true,
  maxKittiCarryOvers: 3,
};

export type KittiMove =
  | { readonly type: 'arrange'; readonly hands: readonly [readonly Card[], readonly Card[], readonly Card[]] }
  | { readonly type: 'fold' };

export interface KittiState {
  readonly gameId: 'kitti';
  readonly rules: KittiRules;
  readonly seed: string;
  readonly players: readonly PlayerId[];
  readonly rawHands: readonly (readonly Card[])[];
  readonly arrangedHands: readonly (readonly [readonly Card[], readonly Card[], readonly Card[]] | null)[];
  readonly showWins: readonly number[]; // Wins per seat
  readonly currentShow: number; // 1, 2, 3
  readonly pot: number;
  readonly isRoundOver: boolean;
  readonly isGameOver: boolean;
  readonly winnerSeat: SeatIndex | null;
  readonly isKittiCarryOver: boolean;
}

export interface KittiPublicView {
  readonly gameId: 'kitti';
  readonly rules: KittiRules;
  readonly currentShow: number;
  readonly pot: number;
  readonly isRoundOver: boolean;
  readonly isGameOver: boolean;
  readonly winnerSeat: SeatIndex | null;
  readonly isKittiCarryOver: boolean;
  readonly players: readonly {
    readonly id: PlayerId;
    readonly seat: SeatIndex;
    readonly isArranged: boolean;
    readonly showWins: number;
  }[];
  readonly myCards?: readonly Card[];
}
