/**
 * Pure deterministic Seeded PRNG and Fisher-Yates Shuffle
 * Guaranteed to produce identical sequences across Node.js, Web, and Dart ports.
 */

export class SeedRng {
  private state: number;

  constructor(seed: string) {
    this.state = SeedRng.hashSeed(seed);
  }

  private static hashSeed(seed: string): number {
    let h = 0x811c9dc5;
    for (let i = 0; i < seed.length; i++) {
      h ^= seed.charCodeAt(i);
      h = Math.imul(h, 0x01000193);
    }
    return h >>> 0;
  }

  /**
   * Mulberry32 algorithm
   * Returns a float in [0, 1)
   */
  public next(): number {
    let z = (this.state += 0x6d2b79f5);
    z = Math.imul(z ^ (z >>> 15), z | 1);
    z ^= z + Math.imul(z ^ (z >>> 7), z | 61);
    return ((z ^ (z >>> 14)) >>> 0) / 4294967296;
  }

  /**
   * Returns an integer in range [min, max] inclusive
   */
  public nextInt(min: number, max: number): number {
    if (min > max) {
      throw new Error(`min (${min}) must be <= max (${max})`);
    }
    const range = max - min + 1;
    return min + Math.floor(this.next() * range);
  }

  /**
   * Pure Fisher-Yates shuffle returning a newly shuffled array.
   * Does not mutate original array.
   */
  public shuffle<T>(array: readonly T[]): T[] {
    const copy = [...array];
    for (let i = copy.length - 1; i > 0; i--) {
      const j = this.nextInt(0, i);
      const temp = copy[i]!;
      copy[i] = copy[j]!;
      copy[j] = temp;
    }
    return copy;
  }
}

export function seededShuffle<T>(items: readonly T[], seed: string): T[] {
  const rng = new SeedRng(seed);
  return rng.shuffle(items);
}
