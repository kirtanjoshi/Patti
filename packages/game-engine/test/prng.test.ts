import { describe, expect, it } from 'vitest';
import { SeedRng, seededShuffle } from '../src/core/prng.js';
import { commitSeed, sha256, verifySeed } from '../src/core/crypto.js';
import { createStandardDeck } from '../src/core/card.js';

describe('Seeded PRNG & Commit-Reveal', () => {
  it('produces identical sequences given identical seeds (pure & deterministic)', () => {
    const seed = 'test-seed-12345';
    const rng1 = new SeedRng(seed);
    const rng2 = new SeedRng(seed);

    const seq1 = Array.from({ length: 20 }, () => rng1.next());
    const seq2 = Array.from({ length: 20 }, () => rng2.next());

    expect(seq1).toEqual(seq2);
  });

  it('produces different sequences for different seeds', () => {
    const rng1 = new SeedRng('seed-A');
    const rng2 = new SeedRng('seed-B');

    const seq1 = Array.from({ length: 10 }, () => rng1.next());
    const seq2 = Array.from({ length: 10 }, () => rng2.next());

    expect(seq1).not.toEqual(seq2);
  });

  it('shuffles without losing or duplicating cards', () => {
    const deck = createStandardDeck(0);
    const shuffled = seededShuffle(deck, 'arbitrary-deal-seed');

    expect(shuffled).toHaveLength(52);
    const idSet = new Set(shuffled.map((c) => c.id));
    expect(idSet.size).toBe(52);

    // Order should differ from unshuffled
    const sameOrder = deck.every((c, idx) => c.id === shuffled[idx]?.id);
    expect(sameOrder).toBe(false);
  });

  it('computes and verifies commit-reveal sha256 hash', () => {
    const seed = 'super-secret-256-bit-match-seed';
    const hash = commitSeed(seed);

    expect(hash).toHaveLength(64);
    expect(verifySeed(seed, hash)).toBe(true);
    expect(verifySeed('wrong-seed', hash)).toBe(false);
  });
});
