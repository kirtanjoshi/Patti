import { describe, expect, it } from 'vitest';
import { BOTS_VERSION } from '../src/index.js';

describe('Bots Package Skeleton', () => {
  it('exports BOTS_VERSION', () => {
    expect(BOTS_VERSION).toBe('0.1.0');
  });
});
