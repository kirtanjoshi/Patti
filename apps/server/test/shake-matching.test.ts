import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { GameGateway } from '../src/gateways/game.gateway.js';
import { RoomsService } from '../src/modules/rooms/rooms.service.js';
import { SocialService } from '../src/modules/social/social.service.js';
import { AuthService } from '../src/modules/auth/auth.service.js';

function createMockSocket(id: string, userId: string, ip: string, name: string) {
  const events: Record<string, any[]> = {};
  const rooms = new Set<string>();

  const socket: any = {
    id,
    data: { user: { userId, name } },
    handshake: {
      headers: { 'x-forwarded-for': ip },
      address: ip,
    },
    join: vi.fn((room: string) => rooms.add(room)),
    leave: vi.fn((room: string) => rooms.delete(room)),
    emit: vi.fn((event: string, payload: any) => {
      if (!events[event]) events[event] = [];
      events[event].push(payload);
    }),
    _events: events,
    _rooms: rooms,
  };
  return socket;
}

describe('GameGateway (Shake to Match & Voice PIN Join)', () => {
  let gateway: GameGateway;
  let roomsService: RoomsService;
  let socialService: SocialService;
  let authService: AuthService;
  let serverMock: any;

  beforeEach(() => {
    roomsService = new RoomsService();
    socialService = new SocialService();
    authService = new AuthService();
    gateway = new GameGateway(
      {} as any, // tableService
      {} as any, // matchmakingService
      authService,
      roomsService,
      socialService,
    );
    serverMock = {
      to: vi.fn(() => ({
        emit: vi.fn(),
      })),
      in: vi.fn(() => ({
        fetchSockets: vi.fn().mockResolvedValue([]),
      })),
    };
    gateway.server = serverMock;
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('matches two shaking players into a private room with pin and room:state', () => {
    const client1 = createMockSocket('sock_1', 'user_1', '192.168.1.50', 'Player 1');
    const client2 = createMockSocket('sock_2', 'user_2', '192.168.1.50', 'Player 2');

    // First player shakes
    gateway.handleSocialShake(client1, { gameId: 'teenpatti' });
    expect(client1.emit).not.toHaveBeenCalledWith('social:shake_matched', expect.anything());

    // Second player shakes within 6s
    gateway.handleSocialShake(client2, { gameId: 'teenpatti' });

    // Both should receive social:shake_matched
    expect(client1.emit).toHaveBeenCalledWith('social:shake_matched', expect.objectContaining({
      code: expect.any(String),
      pin: expect.stringMatching(/^\d{4}$/),
      gameId: 'teenpatti',
    }));

    expect(client2.emit).toHaveBeenCalledWith('social:shake_matched', expect.objectContaining({
      code: expect.any(String),
      pin: expect.stringMatching(/^\d{4}$/),
      gameId: 'teenpatti',
    }));

    // Both should receive room:state
    expect(client1.emit).toHaveBeenCalledWith('room:state', expect.objectContaining({
      participants: expect.arrayContaining([
        expect.objectContaining({ userId: 'user_2' }),
        expect.objectContaining({ userId: 'user_1' }),
      ]),
    }));

    // Both sockets joined the room channel
    expect(client1.join).toHaveBeenCalledWith(expect.stringMatching(/^room:/));
    expect(client2.join).toHaveBeenCalledWith(expect.stringMatching(/^room:/));
  });

  it('times out unmatched shaker after 6 seconds with social:shake_timeout', () => {
    vi.useFakeTimers();

    const client = createMockSocket('sock_solo', 'user_solo', '10.0.0.1', 'Solo Player');
    gateway.handleSocialShake(client, { gameId: 'callbreak' });

    expect(client.emit).not.toHaveBeenCalledWith('social:shake_timeout', expect.anything());

    // Advance 6.1 seconds
    vi.advanceTimersByTime(6100);

    expect(client.emit).toHaveBeenCalledWith('social:shake_timeout', {
      message: 'No players found nearby. Try again!',
    });
  });

  it('allows joining private room using 4-digit voice PIN via handleRoomJoin', () => {
    const host = roomsService.createRoom('user_host', 'callbreak', {});
    const guestClient = createMockSocket('sock_guest', 'user_guest', '192.168.1.20', 'Guest Player');

    // Guest joins using the 4-digit PIN instead of 6-letter alphanumeric code
    gateway.handleRoomJoin(guestClient, { code: host.pin });

    expect(guestClient.join).toHaveBeenCalledWith(`room:${host.code}`);
    expect(serverMock.to).toHaveBeenCalledWith(`room:${host.code}`);

    const roomAfter = roomsService.getRoom(host.code);
    expect(roomAfter.participants.map((p) => p.userId)).toContain('user_guest');
  });
});
