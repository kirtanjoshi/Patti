import { describe, expect, it } from 'vitest';
import { ISMCTS, ISMCTSAdapter } from '../src/common/ismcts.js';

interface SimpleGameState {
  step: number;
  chosenNumber: number;
}

describe('ISMCTS (Information Set MCTS Search)', () => {
  const dummyAdapter: ISMCTSAdapter<SimpleGameState, number> = {
    currentActor: (s) => (s.step < 1 ? 'bot' : null),
    legalMoves: (s) => (s.step === 0 ? [10, 20, 50] : []),
    applyMove: (s, actor, move) => ({ step: s.step + 1, chosenNumber: move }),
    isTerminal: (s) => s.step >= 1,
    evaluateTerminal: (s, player) => (s.chosenNumber === 50 ? 1.0 : -1.0),
    determinize: (s, observer) => ({ ...s }),
    moveKey: (m) => m.toString(),
  };

  it('converges to the highest-reward action', () => {
    const ismcts = new ISMCTS(dummyAdapter);
    const bestMove = ismcts.search({ step: 0, chosenNumber: 0 }, 'bot', 100, 200);
    expect(bestMove).toBe(50);
  });
});
