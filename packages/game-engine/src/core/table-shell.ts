import { GameId, PlayerId, SeatIndex } from './types.js';

export enum TableState {
  WAITING = 'WAITING',
  READY = 'READY',
  DEALING = 'DEALING',
  PLAYING = 'PLAYING',
  ROUND_END = 'ROUND_END',
  GAME_END = 'GAME_END',
  SETTLED = 'SETTLED',
  ABANDONED = 'ABANDONED',
}

export enum SeatStatus {
  EMPTY = 'EMPTY',
  OCCUPIED = 'OCCUPIED',
  DISCONNECTED = 'DISCONNECTED',
  AWAY = 'AWAY',
}

export interface TableTimerConfig {
  readonly turnSeconds: number;
  readonly extraBankSeconds: number;
}

export const GAME_TIMER_CONFIGS: Record<GameId, TableTimerConfig> = {
  callbreak: { turnSeconds: 10, extraBankSeconds: 20 },
  marriage: { turnSeconds: 20, extraBankSeconds: 40 },
  teenpatti: { turnSeconds: 15, extraBankSeconds: 15 },
  kitti: { turnSeconds: 45, extraBankSeconds: 15 },
  dhumbal: { turnSeconds: 12, extraBankSeconds: 20 },
  jutpatti: { turnSeconds: 10, extraBankSeconds: 20 },
  rummy: { turnSeconds: 20, extraBankSeconds: 40 },
  jokerrummy: { turnSeconds: 20, extraBankSeconds: 40 },
};

export interface TableSeat {
  readonly seat: SeatIndex;
  readonly playerId: PlayerId | null;
  readonly status: SeatStatus;
  readonly isBot: boolean;
  readonly botDifficulty?: 'easy' | 'medium' | 'hard';
  readonly extraBankRemainingSeconds: number;
  readonly missedTurnsCount: number;
}

export interface TableShellSnapshot {
  readonly tableId: string;
  readonly gameId: GameId;
  readonly state: TableState;
  readonly seats: readonly TableSeat[];
  readonly currentTurnSeat: SeatIndex | null;
  readonly turnDeadlineEpochMs: number | null;
  readonly version: number;
}
