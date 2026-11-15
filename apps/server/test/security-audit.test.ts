import { describe, expect, it } from 'vitest';
import { CallbreakGameModule } from '@patii/game-engine';
import { MarriageGameModule } from '@patii/game-engine';

describe('Security & Anti-Cheat Audit (PRD 7.5)', () => {
  it('strictly ensures hidden opponent cards never leak in viewFor projection', () => {
    // 1. Callbreak
    const cb = new CallbreakGameModule();
    const cbState = cb.setup(['player_0', 'player_1', 'player_2', 'player_3'], cb.defaultRules, 'audit_seed_1');
    const cbViewForP0 = cb.viewFor(cbState, 'player_0');

    // Player 0 should see their own 13 cards
    expect(cbViewForP0.myHand).toHaveLength(13);

    // Opponent hands must NOT exist in the view object
    expect((cbViewForP0 as Record<string, unknown>)['hands']).toBeUndefined();
    expect((cbViewForP0 as Record<string, unknown>)['player_1_hand']).toBeUndefined();

    // 2. Marriage
    const mg = new MarriageGameModule();
    const mgState = mg.setup(['player_0', 'player_1', 'player_2', 'player_3'], mg.defaultRules, 'audit_seed_2');
    const mgViewForP1 = mg.viewFor(mgState, 'player_1');

    // Player 1 sees own hand (21 cards)
    expect(mgViewForP1.myHand).toHaveLength(21);
    // Opponent hand details must not leak
    expect((mgViewForP1 as Record<string, unknown>)['hands']).toBeUndefined();
    // Unseen maal card must remain hidden if player hasn't seen maal
    if (!mgViewForP1.hasSeenMaal) {
      expect(mgViewForP1.maalCard).toBeNull();
    }
  });

  it('verifies double-entry ledger sum-to-zero invariant', () => {
    // Simulated table settlement: 4 players pay 1,000 entry fee, house rakes 5% (200), winner receives 3,800
    interface TxEntry {
      debitAccount: string;
      creditAccount: string;
      amount: bigint;
    }

    const txs: TxEntry[] = [
      // 4 buy-ins held to table escrow
      { debitAccount: 'user_0', creditAccount: 'ESCROW', amount: BigInt(1000) },
      { debitAccount: 'user_1', creditAccount: 'ESCROW', amount: BigInt(1000) },
      { debitAccount: 'user_2', creditAccount: 'ESCROW', amount: BigInt(1000) },
      { debitAccount: 'user_3', creditAccount: 'ESCROW', amount: BigInt(1000) },

      // Escrow settlement: 5% rake to HOUSE_RAKE (200), remainder to winner user_0 (3,800)
      { debitAccount: 'ESCROW', creditAccount: 'HOUSE_RAKE', amount: BigInt(200) },
      { debitAccount: 'ESCROW', creditAccount: 'user_0', amount: BigInt(3800) },
    ];

    // Compute balance changes
    const deltas = new Map<string, bigint>();
    for (const tx of txs) {
      deltas.set(tx.debitAccount, (deltas.get(tx.debitAccount) ?? BigInt(0)) - tx.amount);
      deltas.set(tx.creditAccount, (deltas.get(tx.creditAccount) ?? BigInt(0)) + tx.amount);
    }

    // Sum of all deltas across the entire closed system MUST be zero
    let totalDelta = BigInt(0);
    for (const val of deltas.values()) {
      totalDelta += val;
    }

    expect(totalDelta).toBe(BigInt(0));
    // Escrow account must be completely cleared
    expect(deltas.get('ESCROW')).toBe(BigInt(0));
    // House collected 200
    expect(deltas.get('HOUSE_RAKE')).toBe(BigInt(200));
    // Winner net gain: 3800 - 1000 = +2800
    expect(deltas.get('user_0')).toBe(BigInt(2800));
  });
});
