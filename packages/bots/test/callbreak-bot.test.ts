import { describe, expect, it } from 'vitest';
import {
  CallbreakGameModule,
  DEFAULT_CALLBREAK_RULES,
  SeedRng,
} from '@patii/game-engine';
import { CallbreakBotStrategy } from '../src/callbreak/callbreak-bot.js';

describe('Callbreak Bot Strategy (Easy / Medium)', () => {
  it('calculates heuristic bid based on sure tricks and spades length', () => {
    const bot = new CallbreakBotStrategy('medium');
    const module = new CallbreakGameModule();
    const state = module.setup(['b1', 'b2', 'b3', 'b4'], DEFAULT_CALLBREAK_RULES, 'test-bot-bid');

    const hand = state.hands[0]!;
    const bid = bot.calculateHeuristicBid(hand);

    expect(bid).toBeGreaterThanOrEqual(1);
    expect(bid).toBeLessThanOrEqual(8);
  });

  it('bot decides valid bid and play moves using only PublicView', () => {
    const bot = new CallbreakBotStrategy('medium');
    const module = new CallbreakGameModule();
    const rng = new SeedRng('bot-decision-seed');
    const state = module.setup(['b1', 'b2', 'b3', 'b4'], DEFAULT_CALLBREAK_RULES, 'test-bot-moves');

    const view = module.viewFor(state, 'b1');
    const move = bot.decide(view, rng);

    expect(move.type).toBe('bid');
    expect((move as any).bid).toBeGreaterThanOrEqual(1);
  });
});
