import { describe, expect, it } from 'vitest';
import { RoomsService } from '../src/modules/rooms/rooms.service.js';

describe('RoomsService (Private Rooms & Codes)', () => {
  const roomsService = new RoomsService();

  it('generates 6-char code without ambiguous characters (0, O, 1, I)', () => {
    const room = roomsService.createRoom('user_host', 'CALLBREAK', { rounds: 5 });
    expect(room.code).toHaveLength(6);
    expect(room.code).toMatch(/^[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{6}$/);
    expect(room.hostUserId).toBe('user_host');
    expect(room.participants).toHaveLength(1);
    expect(room.participants[0]!.userId).toBe('user_host');
  });

  it('allows friends to join room up to capacity', () => {
    const room = roomsService.createRoom('user_host', 'CALLBREAK', { rounds: 5 });
    const joined = roomsService.joinRoom(room.code, 'user_guest_1');
    expect(joined.participants).toHaveLength(2);
    expect(joined.participants.map((p) => p.userId)).toContain('user_guest_1');
  });

  it('restricts rule updates to the host only', () => {
    const room = roomsService.createRoom('user_host', 'CALLBREAK', { rounds: 5 });
    expect(() =>
      roomsService.updateRules(room.code, 'user_intruder', { rounds: 1 }),
    ).toThrow('Only room host can update rules.');

    const updated = roomsService.updateRules(room.code, 'user_host', { rounds: 1 });
    expect(updated.rules).toEqual({ rounds: 1 });
  });
});
