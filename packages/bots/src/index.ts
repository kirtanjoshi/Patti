import { SeedRng } from '@patii/game-engine';

export interface BotStrategy<V, M> {
  decide(view: V, rng: SeedRng, budgetMs?: number): M;
}

export const BOTS_VERSION = '0.1.0';

export * from './callbreak/callbreak-bot.js';
export * from './common/hand-evaluator-3.js';
export * from './common/meld-solver.js';
