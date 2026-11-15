export const BOTS_VERSION = '0.1.0';

export interface BotStrategy<S, M> {
  chooseMove(state: S, seat: number): M;
}

export * from './callbreak/callbreak-bot.js';
export * from './common/hand-evaluator-3.js';
export * from './common/meld-solver.js';
export * from './common/ismcts.js';
export * from './teenpatti/teenpatti-bot.js';
