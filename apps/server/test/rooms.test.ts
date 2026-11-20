import { describe, expect, it } from 'vitest';
import { RoomsService } from '../src/modules/rooms/rooms.service.js';

describe('RoomsService (Private Rooms & Codes)', () => {
  const roomsService = new RoomsService();

  it('generates 6-char code without ambiguous characters (0, O, 1, I)', () => {
    const room = roomsService.createRoom('user_host', 'callbreak', { rounds: 5 });
    expect(room.code).toHaveLength(6);
    expect(room.code).toMatch(/^[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{6}$/);
    expect(room.hostUserId).toBe('user_host');
    expect(room.participants).toHaveLength(1);
    expect(room.participants[0]!.userId).toBe('user_host');
  });

  it('allows friends to join room up to capacity', () => {
    const room = roomsService.createRoom('user_host', 'callbreak', { rounds: 5 });
    const joined = roomsService.joinRoom(room.code, 'user_guest_1', 'Player 1');
    expect(joined.participants).toHaveLength(2);
    expect(joined.participants.map((p) => p.userId)).toContain('user_guest_1');
  });

  it('restricts rule updates to the host only', () => {
    const room = roomsService.createRoom('user_host', 'callbreak', { rounds: 5 });
    expect(() =>
      roomsService.updateRules(room.code, 'user_intruder', { rounds: 1 }),
    ).toThrow('Only room host can update rules.');

    const updated = roomsService.updateRules(room.code, 'user_host', { rounds: 1 });
    expect(updated.rules).toEqual({ rounds: 1 });
  });

  it('adds bots with difficulty and handles kick/leave', () => {
    const room = roomsService.createRoom('user_host', 'callbreak', {}, 0, 4);
    roomsService.addBot(room.code, 'user_host', 1, 'hard');
    expect(room.participants).toHaveLength(2);
    expect(room.participants[1]!.isBot).toBe(true);
    expect(room.participants[1]!.botDifficulty).toBe('hard');

    // Kick bot
    roomsService.kickPlayer(room.code, 'user_host', 1);
    expect(room.participants).toHaveLength(1);

    // Leave room
    roomsService.joinRoom(room.code, 'user_guest_2', 'Player 2');
    const afterLeave = roomsService.leaveRoom(room.code, 'user_guest_2');
    expect(afterLeave?.participants).toHaveLength(1);
  });

  it('generates valid room state payload with invite link and deep link', () => {
    const room = roomsService.createRoom('user_host', 'marriage', { mode: 'classic' }, 100, 4);
    const payload = roomsService.toRoomStatePayload(room);
    expect(payload.code).toBe(room.code);
    expect(payload.gameId).toBe('marriage');
    expect(payload.inviteUrl).toContain(`/r/${room.code}`);
    expect(payload.deepLinkUrl).toBe(`patii://room/${room.code}`);
    expect(payload.participants).toHaveLength(1);
    expect(payload.participants[0]!.displayName).toBe('Host');
  });
});
