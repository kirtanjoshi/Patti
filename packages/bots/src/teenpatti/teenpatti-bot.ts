import { Card, createStandardDeck } from '@patii/game-engine';
import { HandEvaluator3 } from '../common/hand-evaluator-3.js';

export interface TeenPattiBotDecision {
  action: 'chaal' | 'pack' | 'show' | 'side_show';
  equity: number;
}

export class TeenPattiBotStrategy {
  /**
   * Monte Carlo estimation of hand equity against N active opponents
   */
  public static calculateEquity(
    myCards: readonly Card[],
    activeOpponentsCount: number,
    simulations = 500,
  ): number {
    const fullDeck = createStandardDeck();
    // Remaining cards excluding myCards
    const myCardIds = new Set(myCards.map((c: Card) => c.id));
    const remainingDeck = fullDeck.filter((c: Card) => !myCardIds.has(c.id));

    const myEvaluation = HandEvaluator3.evaluate(myCards);
    let wins = 0;

    for (let sim = 0; sim < simulations; sim++) {
      // Shuffle a copy of remaining cards for this simulation
      const deckCopy = [...remainingDeck];
      let oppWinsOrTies = false;

      for (let opp = 0; opp < activeOpponentsCount; opp++) {
        const oppCards: Card[] = [];
        for (let i = 0; i < 3; i++) {
          const randIdx = Math.floor(Math.random() * (deckCopy.length - i));
          oppCards.push(deckCopy[randIdx]!);
          // Swap drawn card to end
          const temp = deckCopy[randIdx]!;
          deckCopy[randIdx] = deckCopy[deckCopy.length - 1 - i]!;
          deckCopy[deckCopy.length - 1 - i] = temp;
        }
        const oppEvaluation = HandEvaluator3.evaluate(oppCards);
        if (oppEvaluation.score >= myEvaluation.score) {
          oppWinsOrTies = true;
          break;
        }
      }

      if (!oppWinsOrTies) {
        wins++;
      }
    }

    return wins / simulations;
  }

  /**
   * Evaluates action for medium/hard bot based on calculated equity
   */
  public static decideAction(
    myCards: readonly Card[],
    activeOpponentsCount: number,
    canShow: boolean,
  ): TeenPattiBotDecision {
    const equity = this.calculateEquity(myCards, activeOpponentsCount, 300);

    if (canShow && equity > 0.6) {
      return { action: 'show', equity };
    }

    // Equity threshold: if hand is better than expected random share (1 / (opponents + 1))
    const breakeven = 1 / (activeOpponentsCount + 1);

    if (equity >= breakeven * 1.1) {
      return { action: 'chaal', equity };
    } else {
      return { action: 'pack', equity };
    }
  }
}
