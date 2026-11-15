/**
 * Information Set Monte Carlo Tree Search (ISMCTS)
 * Handles imperfect information games by sampling a determinized world
 * state consistent with player's information set.
 */

export interface ISMCTSAdapter<S, M> {
  currentActor(state: S): string | null;
  legalMoves(state: S, actor: string): M[];
  applyMove(state: S, actor: string, move: M): S;
  isTerminal(state: S): boolean;
  evaluateTerminal(state: S, player: string): number; // [-1.0, 1.0]
  determinize(state: S, observer: string): S;
  moveKey(move: M): string;
}

export class ISMCTS<S, M extends {}> {
  constructor(
    private readonly adapter: ISMCTSAdapter<S, M>,
    private readonly explorationConstant = 1.414,
  ) {}

  public search(rootState: S, observer: string, iterations = 500, timeBudgetMs = 300): M {
    const legalMoves = this.adapter.legalMoves(rootState, observer);
    if (legalMoves.length === 0) {
      throw new Error('No legal moves available');
    }
    if (legalMoves.length === 1) {
      return legalMoves[0]!;
    }

    const moveScores = new Map<string, { move: M; visits: number; reward: number }>();
    for (const m of legalMoves) {
      moveScores.set(this.adapter.moveKey(m), { move: m, visits: 0, reward: 0 });
    }

    const startTime = Date.now();

    for (let it = 0; it < iterations; it++) {
      if (Date.now() - startTime >= timeBudgetMs) break;

      // 1. Determinization: sample a state consistent with observer's information set
      let state = this.adapter.determinize(rootState, observer);

      // 2. Select / expand root move
      const moves = this.adapter.legalMoves(state, observer);
      if (moves.length === 0) continue;

      // Select move with UCB
      let selectedMove = moves[0]!;
      let bestUCB = -Infinity;
      const totalVisits = Array.from(moveScores.values()).reduce((sum, v) => sum + v.visits, 0);

      for (const m of moves) {
        const key = this.adapter.moveKey(m);
        const stats = moveScores.get(key)!;
        if (stats.visits === 0) {
          selectedMove = m;
          bestUCB = Infinity;
          break;
        }
        const ucb =
          stats.reward / stats.visits +
          this.explorationConstant * Math.sqrt(Math.log(totalVisits + 1) / stats.visits);
        if (ucb > bestUCB) {
          bestUCB = ucb;
          selectedMove = m;
        }
      }

      state = this.adapter.applyMove(state, observer, selectedMove);

      // 3. Rollout / Simulation: fast random rollout until terminal or depth limit
      let depth = 0;
      while (!this.adapter.isTerminal(state) && depth < 20) {
        const actor = this.adapter.currentActor(state);
        if (!actor) break;
        const rolloutMoves = this.adapter.legalMoves(state, actor);
        if (rolloutMoves.length === 0) break;
        const randomMove = rolloutMoves[Math.floor(Math.random() * rolloutMoves.length)]!;
        state = this.adapter.applyMove(state, actor, randomMove);
        depth++;
      }

      // 4. Backpropagation
      const reward = this.adapter.evaluateTerminal(state, observer);
      const key = this.adapter.moveKey(selectedMove);
      const stats = moveScores.get(key);
      if (stats) {
        stats.visits += 1;
        stats.reward += reward;
      }
    }

    // Select move with highest visit count
    let bestMove = legalMoves[0]!;
    let maxVisits = -1;
    for (const stats of moveScores.values()) {
      if (stats.visits > maxVisits) {
        maxVisits = stats.visits;
        bestMove = stats.move;
      }
    }

    return bestMove;
  }
}
