import { z } from 'zod';

export const GameIdEnum = z.enum([
  'callbreak',
  'marriage',
  'teenpatti',
  'kitti',
  'dhumbal',
  'jutpatti',
  'rummy',
  'jokerrummy',
]);
export type GameId = z.infer<typeof GameIdEnum>;

export const StakeTierEnum = z.enum([
  'beginner',
  'bronze',
  'silver',
  'gold',
  'diamond',
]);
export type StakeTier = z.infer<typeof StakeTierEnum>;

export const BotDifficultyEnum = z.enum(['easy', 'medium', 'hard']);
export type BotDifficulty = z.infer<typeof BotDifficultyEnum>;

// Client -> Server Events
export const QueueJoinSchema = z.object({
  gameId: GameIdEnum,
  tier: StakeTierEnum,
});

export const QueueLeaveSchema = z.object({
  gameId: GameIdEnum,
  tier: StakeTierEnum,
});

export const RoomCreateSchema = z.object({
  gameId: GameIdEnum,
  rules: z.record(z.unknown()),
  stake: z.number().int().nonnegative().default(0),
  seats: z.number().int().min(2).max(7),
  botDifficulty: BotDifficultyEnum.default('medium'),
  turnTimerSeconds: z.number().int().positive().default(15),
});

export const RoomJoinSchema = z.object({
  code: z.string().length(6),
});

export const RoomLeaveSchema = z.object({
  code: z.string().length(6),
});

export const RoomKickSchema = z.object({
  seat: z.number().int().nonnegative(),
});

export const RoomAddBotSchema = z.object({
  seat: z.number().int().nonnegative(),
  difficulty: BotDifficultyEnum.default('medium'),
});

export const RoomStartSchema = z.object({
  code: z.string().length(6),
});

export const TableMoveSchema = z.object({
  tableId: z.string().min(1),
  version: z.number().int().nonnegative(),
  move: z.record(z.unknown()),
});

export const TableResyncSchema = z.object({
  tableId: z.string().min(1),
});

export const TableChatClientSchema = z.object({
  tableId: z.string().min(1),
  phraseId: z.string().optional(),
  emojiId: z.string().optional(),
});

export const TableRematchSchema = z.object({
  tableId: z.string().min(1),
  accept: z.boolean(),
});

// Server -> Client Events
export const QueueMatchedSchema = z.object({
  tableId: z.string().min(1),
  gameId: GameIdEnum,
  seat: z.number().int().nonnegative(),
});

export const TableStateSchema = z.object({
  tableId: z.string().min(1),
  version: z.number().int().nonnegative(),
  view: z.record(z.unknown()),
});

export const TableEventSchema = z.object({
  tableId: z.string().min(1),
  version: z.number().int().nonnegative(),
  event: z.string().min(1),
  payload: z.record(z.unknown()).optional(),
  patch: z.record(z.unknown()).optional(),
});

export const TableTurnSchema = z.object({
  tableId: z.string().min(1),
  seat: z.number().int().nonnegative(),
  deadlineEpochMs: z.number().int().positive(),
  legalMoveHints: z.array(z.record(z.unknown())).optional(),
});

export const SeatResultSchema = z.object({
  seat: z.number().int().nonnegative(),
  playerId: z.string(),
  points: z.number(),
  coinDelta: z.number(),
  xpGained: z.number().int().nonnegative(),
  placement: z.number().int().positive(),
});

export const TableResultSchema = z.object({
  tableId: z.string().min(1),
  gameId: GameIdEnum,
  roundNumber: z.number().int().positive(),
  isGameOver: z.boolean(),
  results: z.array(SeatResultSchema),
});

export const TableChatServerSchema = z.object({
  seat: z.number().int().nonnegative(),
  phraseId: z.string().optional(),
  emojiId: z.string().optional(),
});

export const ErrorCodeEnum = z.enum([
  'ILLEGAL_MOVE',
  'NOT_YOUR_TURN',
  'STALE_VERSION',
  'INSUFFICIENT_COINS',
  'TABLE_NOT_FOUND',
  'ROOM_FULL',
  'ROOM_NOT_FOUND',
  'RATE_LIMITED',
  'UNAUTHORIZED',
  'INTERNAL_ERROR',
]);
export type ErrorCode = z.infer<typeof ErrorCodeEnum>;

export const ErrorPayloadSchema = z.object({
  code: ErrorCodeEnum,
  message: z.string(),
  details: z.record(z.unknown()).optional(),
});
