import { describe, expect, it } from 'vitest';
import { EconomyService, DAILY_STREAK_REWARDS } from '../src/modules/economy/economy.service.js';

describe('EconomyService Calculations & Progression', () => {
  const economyService = new EconomyService();

  it('matches PRD 8.1 7-day daily streak progression', () => {
    expect(DAILY_STREAK_REWARDS).toEqual([500, 750, 1000, 1250, 1500, 2000, 3000]);
  });

  it('calculates player levels according to 100 * n^2 formula (PRD 8.4)', () => {
    // Level 1: 0..399 XP
    expect(economyService.calculateLevel(0)).toBe(1);
    expect(economyService.calculateLevel(99)).toBe(1);
    expect(economyService.calculateLevel(399)).toBe(1);

    // Level 2: 400 XP (100 * 2^2)
    expect(economyService.calculateLevel(400)).toBe(2);
    expect(economyService.calculateLevel(899)).toBe(2);

    // Level 3: 900 XP (100 * 3^2)
    expect(economyService.calculateLevel(900)).toBe(3);

    // Level 10: 10,000 XP (100 * 10^2)
    expect(economyService.calculateLevel(10000)).toBe(10);
  });
});
