import {
  Card,
  GameId,
  PlayerId,
  RoundResult,
  SeatIndex,
} from '../../core/types.js';
import { GameModule, IllegalMoveError, NotYourTurnError } from '../../core/interface.js';
import { createMultiDeck } from '../../core/card.js';
import { seededShuffle } from '../../core/prng.js';
import {
  DEFAULT_DHUMBAL_RULES,
  DhumbalMove,
  DhumbalPublicView,
  DhumbalRules,
  DhumbalState,
} from './types.js';

export function calculateDhumbalHandValue(hand: readonly Card[], style: 'app' | 'classic' = 'app'): number {
  let sum = 0;
  for (const c of hand) {
    if (c.suit === 'X') continue;
    if (style === 'app') {
      sum += c.rank; // A=1, 2-10, J=11, Q=12, K=13
    } else {
      if (c.rank === 11) sum += 0;
      else if (c.rank >= 12) sum += 10;
      else sum += c.rank;
    }
  }
  return sum;
}

export class DhumbalGameModule
  implements GameModule<DhumbalState, DhumbalMove, DhumbalRules, DhumbalPublicView>
{
  readonly id: GameId = 'dhumbal';
  readonly defaultRules: DhumbalRules = DEFAULT_DHUMBAL_RULES;

  validateRules(rules: DhumbalRules): DhumbalRules {
    return {
      callThreshold: rules.callThreshold ?? 5,
      failPenalty: rules.failPenalty ?? 25,
      eliminationScore: rules.eliminationScore ?? 100,
      jokersEnabled: Boolean(rules.jokersEnabled),
      cardValuesStyle: rules.cardValuesStyle === 'classic' ? 'classic' : 'app',
    };
  }

  setup(players: readonly PlayerId[], rawRules: DhumbalRules, seed: string): DhumbalState {
    if (players.length < 2 || players.length > 5) {
      throw new Error('Dhumbal requires 2 to 5 players.');
    }
    const rules = this.validateRules(rawRules);
    const deck = createMultiDeck(1, rules.jokersEnabled ? 2 : 0);
    const shuffled = seededShuffle(deck, seed);

    const hands: Card[][] = [];
    for (let i = 0; i < players.length; i++) {
      hands.push(shuffled.slice(i * 5, i * 5 + 5));
    }

    const discardStart = shuffled.slice(players.length * 5, players.length * 5 + 1);
    const stock = shuffled.slice(players.length * 5 + 1);

    return {
      gameId: 'dhumbal',
      rules,
      seed,
      players: [...players],
      hands,
      cumulativeScores: players.map(() => 0),
      stock,
      discardPile: discardStart,
      currentTurnSeat: 0,
      isRoundOver: false,
      isGameOver: false,
      roundWinnerSeat: null,
      callerSeat: null,
      callerSucceeded: null,
    };
  }

  legalMoves(state: DhumbalState, player: PlayerId): DhumbalMove[] {
    const seat = state.players.indexOf(player);
    if (seat === -1 || seat !== state.currentTurnSeat || state.isRoundOver) return [];

    const hand = state.hands[seat]!;
    const handVal = calculateDhumbalHandValue(hand, state.rules.cardValuesStyle);
    const moves: DhumbalMove[] = [];

    // Can call Jhyap if hand total <= threshold
    if (handVal <= state.rules.callThreshold) {
      moves.push({ type: 'callJhyap' });
    }

    // Default play turn: discard first card, draw from stock
    moves.push({
      type: 'playTurn',
      discardCards: [hand[0]!],
      drawSource: 'stock',
    });

    return moves;
  }

  applyMove(state: DhumbalState, player: PlayerId, move: DhumbalMove): DhumbalState {
    const seat = state.players.indexOf(player) as SeatIndex;
    if (seat === -1 || seat !== state.currentTurnSeat) {
      throw new NotYourTurnError(this.currentActor(state), player);
    }

    if (move.type === 'callJhyap') {
      const callerHand = state.hands[seat]!;
      const callerVal = calculateDhumbalHandValue(callerHand, state.rules.cardValuesStyle);

      // Check if strictly lowest
      let callerWins = true;
      let minVal = callerVal;
      let lowestSeat = seat;

      for (let s = 0; s < state.players.length; s++) {
        if (s === seat) continue;
        const val = calculateDhumbalHandValue(state.hands[s]!, state.rules.cardValuesStyle);
        if (val <= callerVal) {
          callerWins = false;
        }
        if (val < minVal) {
          minVal = val;
          lowestSeat = s as SeatIndex;
        }
      }

      const updatedScores = [...state.cumulativeScores];
      if (callerWins) {
        // Caller scores 0, others add hand total
        for (let s = 0; s < state.players.length; s++) {
          if (s !== seat) {
            updatedScores[s] += calculateDhumbalHandValue(state.hands[s]!, state.rules.cardValuesStyle);
          }
        }
      } else {
        // Fail: caller gets 25 penalty + own hand total
        updatedScores[seat] += state.rules.failPenalty + callerVal;
      }

      const isEliminated = updatedScores.some((sc) => sc > state.rules.eliminationScore);

      return {
        ...state,
        cumulativeScores: updatedScores,
        isRoundOver: true,
        isGameOver: isEliminated,
        roundWinnerSeat: callerWins ? seat : lowestSeat,
        callerSeat: seat,
        callerSucceeded: callerWins,
      };
    }

    if (move.type === 'playTurn') {
      const hand = state.hands[seat]!;
      const discardIds = new Set(move.discardCards.map((c) => c.id));
      const remainingHand = hand.filter((c) => !discardIds.has(c.id));

      let drawnCard: Card;
      let newStock = [...state.stock];
      let currentDiscards = [...state.discardPile];

      if (newStock.length === 0 && currentDiscards.length > 1) {
        const top = currentDiscards.pop()!;
        newStock = currentDiscards;
        currentDiscards = [top];
      }

      if (move.drawSource === 'stock' && newStock.length > 0) {
        drawnCard = newStock.pop()!;
      } else {
        drawnCard = currentDiscards.pop() ?? move.discardCards[0]!;
      }

      remainingHand.push(drawnCard);

      const newHands = state.hands.map((h, idx) => (idx === seat ? remainingHand : h));
      const newDiscards = [...currentDiscards, ...move.discardCards];
      const nextSeat = ((seat + 1) % state.players.length) as SeatIndex;

      return {
        ...state,
        hands: newHands,
        stock: newStock,
        discardPile: newDiscards,
        currentTurnSeat: nextSeat,
      };
    }

    throw new IllegalMoveError('Invalid move');
  }

  currentActor(state: DhumbalState): PlayerId | null {
    if (state.isRoundOver || state.isGameOver) return null;
    return state.players[state.currentTurnSeat] ?? null;
  }

  isRoundOver(state: DhumbalState): boolean {
    return state.isRoundOver;
  }

  scoreRound(state: DhumbalState): RoundResult {
    return {
      roundNumber: 1,
      scores: state.players.map((id, s) => ({
        playerId: id,
        seat: s,
        points: state.cumulativeScores[s] ?? 0,
        coinDelta: state.roundWinnerSeat === s ? 400 : -100,
      })),
      settled: false,
    };
  }

  isGameOver(state: DhumbalState): boolean {
    return state.isGameOver;
  }

  viewFor(state: DhumbalState, player: PlayerId | 'spectator'): DhumbalPublicView {
    const seat = player === 'spectator' ? -1 : state.players.indexOf(player);

    return {
      gameId: 'dhumbal',
      rules: state.rules,
      currentTurnSeat: state.currentTurnSeat,
      topDiscard: state.discardPile.length > 0 ? state.discardPile[state.discardPile.length - 1]! : null,
      stockCount: state.stock.length,
      isRoundOver: state.isRoundOver,
      isGameOver: state.isGameOver,
      roundWinnerSeat: state.roundWinnerSeat,
      players: state.players.map((id, s) => ({
        id,
        seat: s as SeatIndex,
        cardCount: state.hands[s]?.length ?? 0,
        cumulativeScore: state.cumulativeScores[s] ?? 0,
      })),
      myHand: seat >= 0 ? state.hands[seat] : undefined,
    };
  }

  autoMove(state: DhumbalState, player: PlayerId): DhumbalMove {
    const seat = state.players.indexOf(player);
    const hand = state.hands[seat]!;
    const handVal = calculateDhumbalHandValue(hand, state.rules.cardValuesStyle);
    if (handVal <= state.rules.callThreshold) {
      return { type: 'callJhyap' };
    }
    const sortedDesc = [...hand].sort((a, b) => b.rank - a.rank);
    return {
      type: 'playTurn',
      discardCards: [sortedDesc[0]!],
      drawSource: 'stock',
    };
  }
}
