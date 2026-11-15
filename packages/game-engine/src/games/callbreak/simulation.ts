import { CallbreakGameModule } from './callbreak.js';
import { DEFAULT_CALLBREAK_RULES } from './types.js';
import { SeedRng } from '../../core/prng.js';

export interface SimulationResult {
  readonly gamesRun: number;
  readonly dealsRun: number;
  readonly totalMoves: number;
  readonly errors: number;
  readonly durationMs: number;
}

export function runCallbreakRandomSimulation(
  gameCount = 100,
  baseSeed = 'sim_callbreak',
): SimulationResult {
  const startTime = Date.now();
  const module = new CallbreakGameModule();
  const players = ['p0', 'p1', 'p2', 'p3'];
  let totalMoves = 0;
  let dealsRun = 0;

  for (let g = 0; g < gameCount; g++) {
    const gameRng = new SeedRng(`${baseSeed}_g${g}`);
    let state = module.setup(players, DEFAULT_CALLBREAK_RULES, `${baseSeed}_g${g}`);

    while (!module.isGameOver(state)) {
      if (module.isRoundOver(state)) {
        dealsRun++;
        // If 5 deals reached, game is over
        if (state.currentRound >= state.rules.numberOfDeals) {
          break;
        }
        // Advance to next deal
        const nextDealer = ((state.dealerSeat + 1) % 4) as 0 | 1 | 2 | 3;
        state = (module as any).setupDeal(
          state.players,
          state.rules,
          `${baseSeed}_g${g}`,
          nextDealer,
          state.currentRound + 1,
          state.scoresHistory,
          state.cumulativeScores,
        );
      }

      const actor = module.currentActor(state);
      if (!actor) break;

      const legal = module.legalMoves(state, actor);
      if (legal.length === 0) {
        throw new Error(`Simulation failed: No legal moves for actor ${actor}`);
      }

      // Pick a random legal move
      const moveIdx = gameRng.nextInt(0, legal.length - 1);
      const chosenMove = legal[moveIdx]!;

      state = module.applyMove(state, actor, chosenMove);
      totalMoves++;
    }
    dealsRun += state.completedTricks.length === 13 ? 1 : 0;
  }

  const durationMs = Date.now() - startTime;
  return {
    gamesRun: gameCount,
    dealsRun,
    totalMoves,
    errors: 0,
    durationMs,
  };
}
