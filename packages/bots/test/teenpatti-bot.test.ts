import { describe, expect, it } from 'vitest';
import { Card } from '@patii/game-engine';
import { TeenPattiBotStrategy } from '../src/teenpatti/teenpatti-bot.js';

describe('TeenPattiBotStrategy (Monte Carlo Equity)', () => {
  it('correctly calculates high equity for a Trail of Aces', () => {
    const aceTrail: [Card, Card, Card] = [
      { suit: 'S', rank: 1, deck: 0, id: 'AS0' },
      { suit: 'H', rank: 1, deck: 0, id: 'AH0' },
      { suit: 'D', rank: 1, deck: 0, id: 'AD0' },
    ];

    // Against 1 opponent, AAA has 100% equity (unbeatable)
    const equity = TeenPattiBotStrategy.calculateEquity(aceTrail, 1, 200);
    expect(equity).toBe(1.0);

    const decision = TeenPattiBotStrategy.decideAction(aceTrail, 1, false);
    expect(decision.action).toBe('chaal');
  });

  it('correctly calculates low equity for weak 7-4-2 unsuited high card', () => {
    const weakHand: [Card, Card, Card] = [
      { suit: 'S', rank: 7, deck: 0, id: '7S0' },
      { suit: 'H', rank: 4, deck: 0, id: '4H0' },
      { suit: 'D', rank: 2, deck: 0, id: '2D0' },
    ];

    const equity = TeenPattiBotStrategy.calculateEquity(weakHand, 2, 200);
    // Against 2 opponents, 7-high equity is typically < 0.15
    expect(equity).toBeLessThan(0.2);

    const decision = TeenPattiBotStrategy.decideAction(weakHand, 2, false);
    expect(decision.action).toBe('pack');
  });
});
