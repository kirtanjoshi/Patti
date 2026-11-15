import { describe, expect, it } from 'vitest';
import {
  ErrorCodeEnum,
  GameIdEnum,
  QueueJoinSchema,
  RoomCreateSchema,
  TableMoveSchema,
  TableResultSchema,
} from '../src/events.js';

describe('Protocol Zod Validation', () => {
  it('validates queue join event', () => {
    const valid = { gameId: 'callbreak', tier: 'beginner' };
    const parsed = QueueJoinSchema.parse(valid);
    expect(parsed.gameId).toBe('callbreak');
    expect(parsed.tier).toBe('beginner');

    expect(() => QueueJoinSchema.parse({ gameId: 'invalid_game', tier: 'gold' })).toThrow();
  });

  it('validates room creation event with defaults', () => {
    const valid = {
      gameId: 'marriage',
      rules: { alter: true, manCards: 2 },
      seats: 4,
    };
    const parsed = RoomCreateSchema.parse(valid);
    expect(parsed.gameId).toBe('marriage');
    expect(parsed.stake).toBe(0);
    expect(parsed.botDifficulty).toBe('medium');
    expect(parsed.turnTimerSeconds).toBe(15);
  });

  it('validates table moves and table results', () => {
    const move = {
      tableId: 'tbl_123',
      version: 1,
      move: { type: 'playCard', cardId: 'QS0' },
    };
    expect(TableMoveSchema.parse(move)).toEqual(move);

    const result = {
      tableId: 'tbl_123',
      gameId: 'callbreak',
      roundNumber: 5,
      isGameOver: true,
      results: [
        {
          seat: 0,
          playerId: 'p1',
          points: 5.2,
          coinDelta: 1000,
          xpGained: 50,
          placement: 1,
        },
      ],
    };
    expect(TableResultSchema.parse(result).isGameOver).toBe(true);
  });
});
