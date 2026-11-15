import { SeedRng } from '@patii/game-engine';

export interface BotStrategy<V, M> {
  decide(view: V, rng: SeedRng, budgetMs?: number): M;
}

export const BOTS_VERSION = '0.1.0';

export * from './callbreak/callbreak-bot.js';
