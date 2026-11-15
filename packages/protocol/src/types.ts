import { z } from 'zod';
import * as events from './events.js';

export type QueueJoinPayload = z.infer<typeof events.QueueJoinSchema>;
export type QueueLeavePayload = z.infer<typeof events.QueueLeaveSchema>;
export type RoomCreatePayload = z.infer<typeof events.RoomCreateSchema>;
export type RoomJoinPayload = z.infer<typeof events.RoomJoinSchema>;
export type RoomLeavePayload = z.infer<typeof events.RoomLeaveSchema>;
export type RoomKickPayload = z.infer<typeof events.RoomKickSchema>;
export type RoomAddBotPayload = z.infer<typeof events.RoomAddBotSchema>;
export type RoomStartPayload = z.infer<typeof events.RoomStartSchema>;
export type TableMovePayload = z.infer<typeof events.TableMoveSchema>;
export type TableResyncPayload = z.infer<typeof events.TableResyncSchema>;
export type TableChatClientPayload = z.infer<typeof events.TableChatClientSchema>;
export type TableRematchPayload = z.infer<typeof events.TableRematchSchema>;

export type QueueMatchedPayload = z.infer<typeof events.QueueMatchedSchema>;
export type TableStatePayload = z.infer<typeof events.TableStateSchema>;
export type TableEventPayload = z.infer<typeof events.TableEventSchema>;
export type TableTurnPayload = z.infer<typeof events.TableTurnSchema>;
export type TableResultPayload = z.infer<typeof events.TableResultSchema>;
export type TableChatServerPayload = z.infer<typeof events.TableChatServerSchema>;
export type ErrorPayload = z.infer<typeof events.ErrorPayloadSchema>;
