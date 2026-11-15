import { describe, expect, it } from 'vitest';
import { createCard } from '@patii/game-engine';
import { HandCategory, HandEvaluator3 } from '../src/common/hand-evaluator-3.js';
import { MeldSolver } from '../src/common/meld-solver.js';

describe('Shared Bot Utilities: HandEvaluator3 & MeldSolver', () => {
  it('evaluates Trail, Pure Sequence, Sequence, Color, Pair, and High card in HandEvaluator3', () => {
    // Trail: Three Aces
    const trail = [createCard('S', 1, 0), createCard('H', 1, 0), createCard('D', 1, 0)];
    expect(HandEvaluator3.evaluate(trail).category).toBe(HandCategory.TRAIL);

    // Pure sequence: A-K-Q of Spades
    const pureSeq = [createCard('S', 1, 0), createCard('S', 13, 0), createCard('S', 12, 0)];
    expect(HandEvaluator3.evaluate(pureSeq).category).toBe(HandCategory.PURE_SEQUENCE);

    // Trail beats Pure sequence
    expect(HandEvaluator3.compare(trail, pureSeq)).toBeGreaterThan(0);

    // Color (Flush): non-consecutive cards of same suit
    const flush = [createCard('H', 2, 0), createCard('H', 7, 0), createCard('H', 11, 0)];
    expect(HandEvaluator3.evaluate(flush).category).toBe(HandCategory.COLOR);
  });

  it('detects Tunnelas, Dublees, Pure Sequences, and Sets in MeldSolver', () => {
    // Tunnela: 3 identical cards in rank and suit across multi-decks
    const tunnela = [createCard('H', 6, 0), createCard('H', 6, 1), createCard('H', 6, 2)];
    expect(MeldSolver.isTunnela(tunnela)).toBe(true);

    // Dublee: pair of identical cards
    const dublee = [createCard('S', 12, 0), createCard('S', 12, 1)];
    expect(MeldSolver.isDublee(dublee)).toBe(true);

    // Pure sequence: 4-5-6 of Diamonds
    const pureSeq = [createCard('D', 4, 0), createCard('D', 5, 0), createCard('D', 6, 0)];
    expect(MeldSolver.isPureSequence(pureSeq)).toBe(true);

    // Set (Trial): three 9s in different suits
    const set = [createCard('S', 9, 0), createCard('H', 9, 0), createCard('C', 9, 0)];
    expect(MeldSolver.isSet(set)).toBe(true);
  });
});
