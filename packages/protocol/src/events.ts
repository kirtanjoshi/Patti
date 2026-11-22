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
  code: z.string().min(4).max(6),
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

export const RoomInviteFriendSchema = z.object({
  code: z.string().length(6),
  targetUserId: z.string().min(1),
});

export const RoomParticipantSchema = z.object({
  seat: z.number().int().nonnegative(),
  userId: z.string(),
  displayName: z.string(),
  avatarUrl: z.string().nullable().optional(),
  isHost: z.boolean(),
  isBot: z.boolean(),
  botDifficulty: BotDifficultyEnum.optional(),
});

export const RoomStateSchema = z.object({
  code: z.string().length(6),
  pin: z.string().optional(),
  gameId: GameIdEnum,
  hostUserId: z.string(),
  rules: z.record(z.unknown()),
  stake: z.number().int().nonnegative().default(0),
  maxSeats: z.number().int().positive(),
  botDifficulty: BotDifficultyEnum.default('medium'),
  turnTimerSeconds: z.number().int().positive().default(15),
  inviteUrl: z.string().optional(),
  deepLinkUrl: z.string().optional(),
  participants: z.array(RoomParticipantSchema),
});

export const RoomStartedSchema = z.object({
  code: z.string().length(6),
  tableId: z.string().min(1),
  gameId: GameIdEnum,
});

// Social Events
export const SocialRoomInviteSchema = z.object({
  code: z.string().length(6),
  gameId: GameIdEnum,
  stake: z.number().int().nonnegative(),
  hostUserId: z.string(),
  hostName: z.string(),
  hostAvatarUrl: z.string().nullable().optional(),
});

export const SocialShakeSchema = z.object({
  gameId: GameIdEnum.optional(),
});

export const SocialShakeMatchedSchema = z.object({
  code: z.string().length(6),
  pin: z.string(),
  gameId: GameIdEnum,
});

export const SocialPresenceStatusEnum = z.enum(['online', 'in_room', 'in_table', 'offline']);
export type SocialPresenceStatus = z.infer<typeof SocialPresenceStatusEnum>;

export const SocialPresenceUpdateSchema = z.object({
  userId: z.string(),
  status: SocialPresenceStatusEnum,
  gameId: GameIdEnum.nullable().optional(),
});

export const SocialFriendEventTypeEnum = z.enum(['request_received', 'request_accepted', 'friend_removed']);
export type SocialFriendEventType = z.infer<typeof SocialFriendEventTypeEnum>;

export const SocialFriendEventSchema = z.object({
  type: SocialFriendEventTypeEnum,
  fromUser: z.object({
    userId: z.string(),
    displayName: z.string(),
    avatarUrl: z.string().nullable().optional(),
    friendCode: z.string().nullable().optional(),
  }),
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
