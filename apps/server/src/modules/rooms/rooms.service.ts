import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { GameId } from '@patii/protocol';
import { TableService } from '../table/table.service.js';
import { TableRuntime } from '../table/table-runtime.js';

export interface RoomParticipant {
  readonly seat: number;
  readonly userId: string;
  readonly isHost: boolean;
  readonly isBot: boolean;
}

export interface PrivateRoom {
  readonly code: string;
  readonly gameId: GameId;
  readonly hostUserId: string;
  readonly rules: Record<string, unknown>;
  readonly stake: number;
  readonly maxSeats: number;
  readonly botDifficulty: 'easy' | 'medium' | 'hard';
  readonly turnTimerSeconds: number;
  readonly participants: RoomParticipant[];
  tableId: string | null;
  readonly createdAt: number;
}

const CODE_CHARS = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ'; // Excludes 0, O, 1, I per PRD 7.2

@Injectable()
export class RoomsService {
  private readonly activeRooms = new Map<string, PrivateRoom>();

  constructor(private readonly tableService?: TableService) {}

  public updateRules(code: string, requesterUserId: string, newRules: Record<string, unknown>): PrivateRoom {
    const room = this.getRoom(code);
    if (room.hostUserId !== requesterUserId) {
      throw new BadRequestException('Only room host can update rules.');
    }
    (room as { rules: Record<string, unknown> }).rules = newRules;
    return room;
  }

  public generateRoomCode(): string {
    let code = '';
    for (let i = 0; i < 6; i++) {
      const idx = Math.floor(Math.random() * CODE_CHARS.length);
      code += CODE_CHARS[idx];
    }
    return code;
  }

  public createRoom(
    hostUserId: string,
    gameId: GameId,
    rules: Record<string, unknown>,
    stake = 0,
    maxSeats = 4,
    botDifficulty: 'easy' | 'medium' | 'hard' = 'medium',
    turnTimerSeconds = 15,
  ): PrivateRoom {
    let code = this.generateRoomCode();
    while (this.activeRooms.has(code)) {
      code = this.generateRoomCode();
    }

    const room: PrivateRoom = {
      code,
      gameId,
      hostUserId,
      rules,
      stake,
      maxSeats,
      botDifficulty,
      turnTimerSeconds,
      participants: [{ seat: 0, userId: hostUserId, isHost: true, isBot: false }],
      tableId: null,
      createdAt: Date.now(),
    };

    this.activeRooms.set(code, room);
    return room;
  }

  public getRoom(code: string): PrivateRoom {
    const room = this.activeRooms.get(code.toUpperCase());
    if (!room) {
      throw new NotFoundException(`Room with code ${code} not found.`);
    }
    return room;
  }

  public joinRoom(code: string, userId: string): PrivateRoom {
    const room = this.getRoom(code);
    if (room.participants.length >= room.maxSeats) {
      throw new BadRequestException('Room is already full.');
    }

    const nextSeat = room.participants.length;
    room.participants.push({
      seat: nextSeat,
      userId,
      isHost: false,
      isBot: false,
    });

    return room;
  }

  public addBot(code: string, requesterUserId: string, seat?: number): PrivateRoom {
    const room = this.getRoom(code);
    if (room.hostUserId !== requesterUserId) {
      throw new BadRequestException('Only the host can add bots.');
    }
    if (room.participants.length >= room.maxSeats) {
      throw new BadRequestException('Room is full.');
    }

    const targetSeat = seat ?? room.participants.length;
    const botId = `bot_${Date.now()}_${targetSeat}`;
    room.participants.push({
      seat: targetSeat,
      userId: botId,
      isHost: false,
      isBot: true,
    });

    return room;
  }

  public startRoom(code: string, requesterUserId: string): TableRuntime {
    const room = this.getRoom(code);
    if (room.hostUserId !== requesterUserId) {
      throw new BadRequestException('Only the host can start the room.');
    }
    if (room.participants.length < 2) {
      throw new BadRequestException('At least 2 players are required to start.');
    }

    if (!this.tableService) {
      throw new BadRequestException('TableService is required to start a room table.');
    }

    const tableId = `tbl_room_${code}`;
    const table = this.tableService.createTable(
      tableId,
      'private',
      BigInt(room.stake),
      () => {},
    );

    room.participants.forEach((p) => {
      table.addPlayer(p.seat, p.userId, p.isBot);
    });

    room.tableId = tableId;
    return table;
  }
}
