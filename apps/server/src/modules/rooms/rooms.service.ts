import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { GameId, RoomParticipantPayload, RoomStatePayload } from '@patii/protocol';
import { TableService } from '../table/table.service.js';
import { TableEventBroadcaster, TableRuntime } from '../table/table-runtime.js';

export interface RoomParticipant {
  seat: number;
  userId: string;
  displayName: string;
  avatarUrl?: string | null;
  isHost: boolean;
  isBot: boolean;
  botDifficulty?: 'easy' | 'medium' | 'hard';
}

export interface PrivateRoom {
  readonly code: string;
  readonly gameId: GameId;
  hostUserId: string;
  rules: Record<string, unknown>;
  readonly stake: number;
  readonly maxSeats: number;
  readonly botDifficulty: 'easy' | 'medium' | 'hard';
  readonly turnTimerSeconds: number;
  participants: RoomParticipant[];
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
    room.rules = newRules;
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
    hostDisplayName = 'Host',
    hostAvatarUrl?: string | null,
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
      participants: [
        {
          seat: 0,
          userId: hostUserId,
          displayName: hostDisplayName,
          avatarUrl: hostAvatarUrl ?? null,
          isHost: true,
          isBot: false,
        },
      ],
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

  public joinRoom(
    code: string,
    userId: string,
    displayName = 'Player',
    avatarUrl?: string | null,
  ): PrivateRoom {
    const room = this.getRoom(code);
    const existing = room.participants.find((p) => p.userId === userId);
    if (existing) {
      return room;
    }

    if (room.participants.length >= room.maxSeats) {
      throw new BadRequestException('Room is already full.');
    }

    const nextSeat = room.participants.length;
    room.participants.push({
      seat: nextSeat,
      userId,
      displayName,
      avatarUrl: avatarUrl ?? null,
      isHost: false,
      isBot: false,
    });

    return room;
  }

  public leaveRoom(code: string, userId: string): PrivateRoom | null {
    const room = this.getRoom(code);
    const idx = room.participants.findIndex((p) => p.userId === userId);
    if (idx === -1) {
      return room;
    }

    const wasHost = room.participants[idx]!.isHost;
    room.participants.splice(idx, 1);

    // Re-index seats
    room.participants.forEach((p, i) => {
      p.seat = i;
    });

    if (room.participants.length === 0) {
      this.activeRooms.delete(code.toUpperCase());
      return null;
    }

    if (wasHost) {
      const nextHuman = room.participants.find((p) => !p.isBot);
      if (nextHuman) {
        nextHuman.isHost = true;
        room.hostUserId = nextHuman.userId;
      } else {
        this.activeRooms.delete(code.toUpperCase());
        return null;
      }
    }

    return room;
  }

  public kickPlayer(code: string, requesterUserId: string, seat: number): PrivateRoom {
    const room = this.getRoom(code);
    if (room.hostUserId !== requesterUserId) {
      throw new BadRequestException('Only the host can kick players.');
    }

    const targetIdx = room.participants.findIndex((p) => p.seat === seat);
    if (targetIdx === -1) {
      throw new NotFoundException(`Player at seat ${seat} not found.`);
    }

    if (room.participants[targetIdx]!.userId === requesterUserId) {
      throw new BadRequestException('Host cannot kick themselves.');
    }

    room.participants.splice(targetIdx, 1);
    room.participants.forEach((p, i) => {
      p.seat = i;
    });

    return room;
  }

  public addBot(
    code: string,
    requesterUserId: string,
    seat?: number,
    difficulty: 'easy' | 'medium' | 'hard' = 'medium',
  ): PrivateRoom {
    const room = this.getRoom(code);
    if (room.hostUserId !== requesterUserId) {
      throw new BadRequestException('Only the host can add bots.');
    }
    if (room.participants.length >= room.maxSeats) {
      throw new BadRequestException('Room is full.');
    }

    const targetSeat = seat ?? room.participants.length;
    const botNum = room.participants.filter((p) => p.isBot).length + 1;
    const botId = `bot_${Date.now()}_${targetSeat}`;

    room.participants.push({
      seat: targetSeat,
      userId: botId,
      displayName: `Bot ${botNum} (${difficulty.toUpperCase()})`,
      avatarUrl: `https://api.dicebear.com/7.x/bottts/svg?seed=bot_${botNum}`,
      isHost: false,
      isBot: true,
      botDifficulty: difficulty,
    });

    return room;
  }

  public startRoom(
    code: string,
    requesterUserId: string,
    broadcaster?: TableEventBroadcaster,
  ): TableRuntime {
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
    const tableSeats = room.gameId === 'callbreak' ? 4 : room.maxSeats;
    const table = this.tableService.createTable(
      tableId,
      'private',
      BigInt(room.stake),
      broadcaster ?? (() => {}),
      room.gameId,
      room.rules,
      tableSeats,
    );

    // Add existing human & added bot participants
    room.participants.forEach((p) => {
      table.addPlayer(p.seat, p.userId, p.isBot);
    });

    // If room is not full, fill remaining empty seats with bots so table can deal and start
    for (let s = 0; s < tableSeats; s++) {
      const existing = room.participants.find((p) => p.seat === s);
      if (!existing) {
        const botNum = room.participants.filter((p) => p.isBot).length + 1;
        const botId = `bot_${Date.now()}_${s}`;
        const botParticipant: RoomParticipant = {
          seat: s,
          userId: botId,
          displayName: `Bot ${botNum}`,
          avatarUrl: `https://api.dicebear.com/7.x/bottts/svg?seed=bot_${botNum}`,
          isHost: false,
          isBot: true,
          botDifficulty: room.botDifficulty,
        };
        room.participants.push(botParticipant);
        table.addPlayer(s, botId, true);
      }
    }

    room.tableId = tableId;
    return table;
  }

  public toRoomStatePayload(room: PrivateRoom): RoomStatePayload {
    const baseUrl = process.env.INVITE_BASE_URL || 'https://patti-ntpv.onrender.com';
    const participants: RoomParticipantPayload[] = room.participants.map((p) => ({
      seat: p.seat,
      userId: p.userId,
      displayName: p.displayName,
      avatarUrl: p.avatarUrl,
      isHost: p.isHost,
      isBot: p.isBot,
      botDifficulty: p.botDifficulty,
    }));

    return {
      code: room.code,
      gameId: room.gameId,
      hostUserId: room.hostUserId,
      rules: room.rules,
      stake: room.stake,
      maxSeats: room.maxSeats,
      botDifficulty: room.botDifficulty,
      turnTimerSeconds: room.turnTimerSeconds,
      inviteUrl: `${baseUrl}/r/${room.code}`,
      deepLinkUrl: `patii://room/${room.code}`,
      participants,
    };
  }
}
