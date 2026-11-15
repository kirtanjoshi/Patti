import { describe, expect, it } from 'vitest';
import { TableRuntime } from '../src/modules/table/table-runtime.js';
import { DEFAULT_CALLBREAK_RULES, TableState } from '@patii/game-engine';

describe('TableRuntime Callbreak Lifecycle', () => {
  it('initializes table, transitions from WAITING to PLAYING when 4 players join', () => {
    const events: Array<{ event: string; payload: any }> = [];
    const broadcaster = (event: string, payload: any) => {
      events.push({ event, payload });
    };

    const table = new TableRuntime(
      {
        tableId: 'test_table_1',
        gameId: 'callbreak',
        tier: 'beginner',
        stake: BigInt(100),
        rules: { ...DEFAULT_CALLBREAK_RULES, numberOfDeals: 3 },
        seatsCount: 4,
      },
      broadcaster,
    );

    expect(table.state).toBe(TableState.WAITING);

    table.addPlayer(0, 'p0', false);
    table.addPlayer(1, 'b1', true);
    table.addPlayer(2, 'b2', true);
    table.addPlayer(3, 'b3', true);

    expect(table.state).toBe(TableState.PLAYING);
    expect(table.engineState).toBeDefined();
    expect(table.engineState?.phase).toBe('bidding');

    // Bidding turn should have been broadcast
    expect(events.some((e) => e.event === 'table:turn')).toBe(true);
  });

  it('handles disconnect and reconnect state updates', () => {
    const events: any[] = [];
    const table = new TableRuntime(
      {
        tableId: 'test_table_2',
        gameId: 'callbreak',
        tier: 'beginner',
        stake: BigInt(100),
        rules: DEFAULT_CALLBREAK_RULES,
        seatsCount: 4,
      },
      (event, payload) => events.push({ event, payload }),
    );

    table.addPlayer(0, 'p0', false);
    table.addPlayer(1, 'b1', true);
    table.addPlayer(2, 'b2', true);
    table.addPlayer(3, 'b3', true);

    table.markDisconnected('p0');
    expect(table.seats[0]?.status).toBe('DISCONNECTED');

    table.markReconnected('p0');
    expect(table.seats[0]?.status).toBe('OCCUPIED');
  });
});
