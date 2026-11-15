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
  TableMoveSchema,
  TableResyncSchema,
} from '@patii/protocol';
import { TableService } from '../modules/table/table.service.js';
import { MatchmakingService } from '../modules/matchmaking/matchmaking.service.js';
import { AuthService } from '../modules/auth/auth.service.js';

@WebSocketGateway({
  namespace: '/game',
  cors: { origin: '*' },
})
export class GameGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server!: Server;

  constructor(
    private readonly tableService: TableService,
    private readonly matchmakingService: MatchmakingService,
    private readonly authService: AuthService,
  ) {}

  handleConnection(client: Socket): void {
    const token = client.handshake.auth?.token as string | undefined;
    if (token) {
      try {
        const user = this.authService.verifyAccessToken(token);
        client.data.user = user;
      } catch {
        // Unauthenticated client can connect as guest or provide token later
      }
    }
  }

  handleDisconnect(client: Socket): void {
    const tableId = client.data.tableId as string | undefined;
    const userId = client.data.user?.userId as string | undefined;
    if (tableId && userId) {
      this.tableService.handleDisconnect(tableId, userId);
    }
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
