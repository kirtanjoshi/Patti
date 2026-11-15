export type Suit = 'S' | 'H' | 'D' | 'C' | 'X';

// Rank 1..13 for standard cards (1=Ace, 11=Jack, 12=Queen, 13=King); 0 for printed joker.
export type Rank = 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13;

export type DeckIndex = 0 | 1 | 2;

export interface Card {
  readonly suit: Suit;
  readonly rank: Rank;
  readonly deck: DeckIndex;
  readonly id: string;
}

export type GameId =
  | 'callbreak'
  | 'marriage'
  | 'teenpatti'
  | 'kitti'
  | 'dhumbal'
  | 'jutpatti'
  | 'rummy'
  | 'jokerrummy';

export type PlayerId = string;
export type SeatIndex = number;

export interface PlayerRoundScore {
  readonly playerId: PlayerId;
  readonly seat: SeatIndex;
  readonly points: number;
  readonly coinDelta: bigint | number;
  readonly placement?: number;
  readonly details?: Record<string, unknown>;
}

export interface RoundResult {
  readonly roundNumber: number;
  readonly scores: readonly PlayerRoundScore[];
  readonly pot?: bigint | number;
  readonly settled: boolean;
}

export interface BasePublicView {
  readonly gameId: GameId;
  readonly roundNumber: number;
  readonly players: readonly {
    readonly id: PlayerId;
    readonly seat: SeatIndex;
    readonly cardCount: number;
    readonly connected: boolean;
    readonly isBot: boolean;
  }[];
  readonly currentActor: PlayerId | null;
  readonly hand?: readonly Card[]; // Present only for the authenticated seat
}
