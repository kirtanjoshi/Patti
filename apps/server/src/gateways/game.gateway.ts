import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import {
  QueueJoinSchema,
  RoomAddBotSchema,
  RoomCreateSchema,
  RoomInviteFriendSchema,
  RoomJoinSchema,
  RoomKickSchema,
  RoomLeaveSchema,
  RoomStartSchema,
  SocialRoomInvitePayload,
  TableMoveSchema,
  TableResyncSchema,
} from '@patii/protocol';
import { TableService } from '../modules/table/table.service.js';
import { MatchmakingService } from '../modules/matchmaking/matchmaking.service.js';
import { AuthService } from '../modules/auth/auth.service.js';
import { RoomsService } from '../modules/rooms/rooms.service.js';
import { SocialService } from '../modules/social/social.service.js';

@WebSocketGateway({
  namespace: '/game',
  cors: { origin: '*' },
})
export class GameGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server!: Server;

  private readonly userSockets = new Map<string, Set<Socket>>();

  constructor(
    private readonly tableService: TableService,
    private readonly matchmakingService: MatchmakingService,
    private readonly authService: AuthService,
    private readonly roomsService: RoomsService,
    private readonly socialService: SocialService,
  ) {}

  handleConnection(client: Socket): void {
    const token = client.handshake.auth?.token as string | undefined;
    if (token) {
      try {
        const user = this.authService.verifyAccessToken(token);
        client.data.user = user;
        this.trackUserSocket(user.userId, client);
        this.socialService.setPresence(user.userId, 'online');
      } catch {
        // Fallback for unauthenticated or dev testing
      }
    }
  }

  handleDisconnect(client: Socket): void {
    const tableId = client.data.tableId as string | undefined;
    const userId = client.data.user?.userId as string | undefined;
    const roomCode = client.data.roomCode as string | undefined;

    if (userId) {
      this.untrackUserSocket(userId, client);
      if (!this.userSockets.has(userId) || this.userSockets.get(userId)!.size === 0) {
        this.socialService.setPresence(userId, 'offline');
      }
    }

    if (tableId && userId) {
      this.tableService.handleDisconnect(tableId, userId);
    }

    if (roomCode && userId) {
      try {
        const room = this.roomsService.leaveRoom(roomCode, userId);
        if (room) {
          this.server.to(`room:${room.code}`).emit('room:state', this.roomsService.toRoomStatePayload(room));
        }
      } catch {}
    }
  }

  private trackUserSocket(userId: string, socket: Socket): void {
    let set = this.userSockets.get(userId);
    if (!set) {
      set = new Set();
      this.userSockets.set(userId, set);
    }
    set.add(socket);
  }

  private untrackUserSocket(userId: string, socket: Socket): void {
    const set = this.userSockets.get(userId);
    if (set) {
      set.delete(socket);
      if (set.size === 0) {
        this.userSockets.delete(userId);
      }
    }
  }

  @SubscribeMessage('room:create')
  handleRoomCreate(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: unknown,
  ): void {
    const parsed = RoomCreateSchema.safeParse(data);
    if (!parsed.success) {
      client.emit('error', { code: 'BAD_REQUEST', message: 'Invalid room:create payload', details: parsed.error });
      return;
    }

    const userId = client.data.user?.userId ?? `guest_${client.id}`;
    const displayName = client.data.user?.name ?? 'Host';

    try {
      const room = this.roomsService.createRoom(
        userId,
        parsed.data.gameId,
        parsed.data.rules,
        parsed.data.stake,
        parsed.data.seats,
        parsed.data.botDifficulty,
        parsed.data.turnTimerSeconds,
        displayName,
      );

      client.data.roomCode = room.code;
      client.join(`room:${room.code}`);
      this.socialService.setPresence(userId, 'in_room', room.gameId);
      client.emit('room:state', this.roomsService.toRoomStatePayload(room));
    } catch (err: any) {
      client.emit('error', { code: 'INTERNAL_ERROR', message: err.message });
    }
  }

  @SubscribeMessage('room:join')
  handleRoomJoin(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: unknown,
  ): void {
    const parsed = RoomJoinSchema.safeParse(data);
    if (!parsed.success) {
      client.emit('error', { code: 'BAD_REQUEST', message: 'Invalid room:join payload' });
      return;
    }

    const userId = client.data.user?.userId ?? `guest_${client.id}`;
    const displayName = client.data.user?.name ?? 'Player';

    try {
      const room = this.roomsService.joinRoom(parsed.data.code, userId, displayName);
      client.data.roomCode = room.code;
      client.join(`room:${room.code}`);
      this.socialService.setPresence(userId, 'in_room', room.gameId);
      this.server.to(`room:${room.code}`).emit('room:state', this.roomsService.toRoomStatePayload(room));
    } catch (err: any) {
      client.emit('error', { code: 'ROOM_NOT_FOUND', message: err.message });
    }
  }

  @SubscribeMessage('room:leave')
  handleRoomLeave(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: unknown,
  ): void {
    const parsed = RoomLeaveSchema.safeParse(data);
    if (!parsed.success) return;

    const userId = client.data.user?.userId ?? `guest_${client.id}`;
    try {
      const room = this.roomsService.leaveRoom(parsed.data.code, userId);
      client.leave(`room:${parsed.data.code}`);
      client.data.roomCode = undefined;
      this.socialService.setPresence(userId, 'online');
      if (room) {
        this.server.to(`room:${room.code}`).emit('room:state', this.roomsService.toRoomStatePayload(room));
      }
      client.emit('room:left', { code: parsed.data.code });
    } catch {}
  }

  @SubscribeMessage('room:kick')
  handleRoomKick(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: unknown,
  ): void {
    const parsed = RoomKickSchema.extend({ code: RoomJoinSchema.shape.code }).safeParse(data);
    if (!parsed.success) return;

    const userId = client.data.user?.userId ?? `guest_${client.id}`;
    try {
      const room = this.roomsService.kickPlayer(parsed.data.code, userId, parsed.data.seat);
      this.server.to(`room:${room.code}`).emit('room:state', this.roomsService.toRoomStatePayload(room));
    } catch (err: any) {
      client.emit('error', { code: 'BAD_REQUEST', message: err.message });
    }
  }

  @SubscribeMessage('room:addBot')
  handleRoomAddBot(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: unknown,
  ): void {
    const parsed = RoomAddBotSchema.extend({ code: RoomJoinSchema.shape.code }).safeParse(data);
    if (!parsed.success) return;

    const userId = client.data.user?.userId ?? `guest_${client.id}`;
    try {
      const room = this.roomsService.addBot(parsed.data.code, userId, parsed.data.seat, parsed.data.difficulty);
      this.server.to(`room:${room.code}`).emit('room:state', this.roomsService.toRoomStatePayload(room));
    } catch (err: any) {
      client.emit('error', { code: 'BAD_REQUEST', message: err.message });
    }
  }

  @SubscribeMessage('room:start')
  async handleRoomStart(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: unknown,
  ): Promise<void> {
    const parsed = RoomStartSchema.safeParse(data);
    if (!parsed.success) return;

    const userId = client.data.user?.userId ?? `guest_${client.id}`;
    try {
      const table = this.roomsService.startRoom(
        parsed.data.code,
        userId,
        (event, payload) => {
          this.server.to(`table:${payload.tableId}`).emit(event, payload);
        },
      );
      const room = this.roomsService.getRoom(parsed.data.code);

      const socketsInRoom = await this.server.in(`room:${room.code}`).fetchSockets();
      for (const s of socketsInRoom) {
        s.join(`table:${table.config.tableId}`);
        (s as any).data.tableId = table.config.tableId;
        const sUserId = (s as any).data.user?.userId;
        if (sUserId) {
          this.socialService.setPresence(sUserId, 'in_table', room.gameId);
          const view = table.getViewFor(sUserId);
          if (view) {
            s.emit('table:state', {
              tableId: table.config.tableId,
              version: table.version,
              view,
            });
          }
        }
      }

      this.server.to(`room:${room.code}`).emit('room:started', {
        code: room.code,
        tableId: table.config.tableId,
        gameId: room.gameId,
      });
    } catch (err: any) {
      client.emit('error', { code: 'BAD_REQUEST', message: err.message });
    }
  }

  @SubscribeMessage('room:invite_friend')
  handleRoomInviteFriend(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: unknown,
  ): void {
    const parsed = RoomInviteFriendSchema.safeParse(data);
    if (!parsed.success) return;

    const hostUserId = client.data.user?.userId ?? `guest_${client.id}`;
    const hostName = client.data.user?.name ?? 'A friend';

    try {
      const room = this.roomsService.getRoom(parsed.data.code);
      const targetSockets = this.userSockets.get(parsed.data.targetUserId);

      if (targetSockets && targetSockets.size > 0) {
        const payload: SocialRoomInvitePayload = {
          code: room.code,
          gameId: room.gameId,
          stake: room.stake,
          hostUserId,
          hostName,
          hostAvatarUrl: null,
        };
        for (const s of targetSockets) {
          s.emit('social:room_invite', payload);
        }
      }
    } catch {}
  }

  @SubscribeMessage('queue:join')
  async handleQueueJoin(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: unknown,
  ): Promise<void> {
    const parsed = QueueJoinSchema.safeParse(data);
    if (!parsed.success) {
      client.emit('error', { code: 'BAD_REQUEST', message: 'Invalid queue join payload' });
      return;
    }

    const userId = client.data.user?.userId ?? `guest_${client.id}`;
    client.data.gameId = parsed.data.gameId;
    client.data.tier = parsed.data.tier;

    await this.matchmakingService.joinQueue(
      userId,
      client.id,
      parsed.data.gameId,
      parsed.data.tier,
      (tableId, seat) => {
        client.data.tableId = tableId;
        client.data.seat = seat;
        client.join(`table:${tableId}`);
        client.emit('queue:matched', {
          tableId,
          gameId: parsed.data.gameId,
          seat,
        });

        const table = this.tableService.getTable(tableId);
        const view = table.getViewFor(userId);
        if (view) {
          client.emit('table:state', {
            tableId,
            version: table.version,
            view,
          });
        }
      },
      (event, payload) => {
        this.server.to(`table:${payload.tableId}`).emit(event, payload);
      },
    );
  }

  @SubscribeMessage('table:move')
  handleTableMove(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: unknown,
  ): void {
    const parsed = TableMoveSchema.safeParse(data);
    if (!parsed.success) {
      client.emit('error', { code: 'ILLEGAL_MOVE', message: 'Invalid move payload schema' });
      return;
    }

    const userId = client.data.user?.userId ?? `guest_${client.id}`;
    try {
      this.tableService.applyMove(
        parsed.data.tableId,
        userId,
        parsed.data.version,
        parsed.data.move as any,
      );
    } catch (err: any) {
      client.emit('error', {
        code: err.message === 'STALE_VERSION' ? 'STALE_VERSION' : 'ILLEGAL_MOVE',
        message: err.message,
      });
    }
  }

  @SubscribeMessage('table:resync')
  handleTableResync(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: unknown,
  ): void {
    const parsed = TableResyncSchema.safeParse(data);
    if (!parsed.success) return;

    const userId = client.data.user?.userId ?? `guest_${client.id}`;
    try {
      const table = this.tableService.getTable(parsed.data.tableId);
      const view = table.getViewFor(userId);
      client.emit('table:state', {
        tableId: parsed.data.tableId,
        version: table.version,
        view,
      });
    } catch {
      client.emit('error', { code: 'TABLE_NOT_FOUND', message: 'Table does not exist' });
    }
  }
}
