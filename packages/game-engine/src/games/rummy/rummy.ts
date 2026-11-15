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
  DEFAULT_NEPALI_RUMMY_RULES,
  RummyMove,
  RummyPublicView,
  RummyRules,
  RummyState,
} from './types.js';

export class RummyGameModule
  implements GameModule<RummyState, RummyMove, RummyRules, RummyPublicView>
{
  readonly id: GameId;
  readonly defaultRules: RummyRules;

  constructor(isPaplu = false) {
    this.id = isPaplu ? 'jokerrummy' : 'rummy';
    this.defaultRules = isPaplu
      ? {
          handSize: 13,
          isPaplu: true,
          gameMode: 'points',
          printedJokersCount: 4,
          papluBonusesEnabled: true,
        }
      : DEFAULT_NEPALI_RUMMY_RULES;
  }

  validateRules(rules: RummyRules): RummyRules {
    return {
      handSize: rules.handSize ?? (this.id === 'jokerrummy' ? 13 : 10),
      isPaplu: this.id === 'jokerrummy',
      gameMode: rules.gameMode ?? 'points',
      printedJokersCount: rules.printedJokersCount ?? (this.id === 'jokerrummy' ? 4 : 0),
      papluBonusesEnabled: Boolean(rules.papluBonusesEnabled),
    };
  }

  setup(players: readonly PlayerId[], rawRules: RummyRules, seed: string): RummyState {
    if (players.length < 2 || players.length > 6) {
      throw new Error('Rummy requires 2 to 6 players.');
    }
    const rules = this.validateRules(rawRules);
    const numDecks = rules.isPaplu || players.length >= 5 ? 2 : 1;
    const deck = createMultiDeck(numDecks as 1 | 2, rules.printedJokersCount);
    const shuffled = seededShuffle(deck, seed);

    const hands: Card[][] = [];
    const size = rules.handSize;
    for (let i = 0; i < players.length; i++) {
      hands.push(shuffled.slice(i * size, i * size + size));
    }

    const cutJoker = shuffled[players.length * size]!;
    const discardStart = shuffled.slice(players.length * size + 1, players.length * size + 2);
    const stock = shuffled.slice(players.length * size + 2);

    return {
      gameId: this.id as 'rummy' | 'jokerrummy',
      rules,
      seed,
      players: [...players],
      hands,
      cutJoker,
      stock,
      discardPile: discardStart,
      currentTurnSeat: 0,
      phase: 'draw',
      cumulativeScores: players.map(() => 0),
      isRoundOver: false,
      isGameOver: false,
      winnerSeat: null,
    };
  }

  legalMoves(state: RummyState, player: PlayerId): RummyMove[] {
    const seat = state.players.indexOf(player);
    if (seat === -1 || seat !== state.currentTurnSeat || state.isGameOver) return [];

    if (state.phase === 'draw') {
      const moves: RummyMove[] = [{ type: 'draw', source: 'stock' }];
      if (state.discardPile.length > 0) {
        moves.push({ type: 'draw', source: 'discard' });
      }
      moves.push({ type: 'drop' });
      return moves;
    }

    if (state.phase === 'discard') {
      const hand = state.hands[seat]!;
      const moves: RummyMove[] = hand.map((c) => ({ type: 'discard', cardId: c.id }));
      // Can declare discarding one card
      moves.push({ type: 'declare', discardCardId: hand[hand.length - 1]!.id });
      return moves;
    }

    return [];
  }

  applyMove(state: RummyState, player: PlayerId, move: RummyMove): RummyState {
    const seat = state.players.indexOf(player) as SeatIndex;
    if (seat === -1 || seat !== state.currentTurnSeat) {
      throw new NotYourTurnError(this.currentActor(state), player);
    }

    if (move.type === 'drop') {
      // Drop costs 20 before first draw
      const newScores = [...state.cumulativeScores];
      newScores[seat] += 20;
      const nextSeat = ((seat + 1) % state.players.length) as SeatIndex;

      return {
        ...state,
        cumulativeScores: newScores,
        currentTurnSeat: nextSeat,
      };
    }

    if (move.type === 'draw') {
      const drawn = move.source === 'stock'
        ? state.stock[state.stock.length - 1]!
        : state.discardPile[state.discardPile.length - 1]!;

      const newStock = move.source === 'stock' ? state.stock.slice(0, -1) : state.stock;
      const newDiscards = move.source === 'discard' ? state.discardPile.slice(0, -1) : state.discardPile;

      const newHand = [...state.hands[seat]!, drawn];
      const newHands = state.hands.map((h, i) => (i === seat ? newHand : h));

      return {
        ...state,
        hands: newHands,
        stock: newStock,
        discardPile: newDiscards,
        phase: 'discard',
      };
    }

    if (move.type === 'declare') {
      return {
        ...state,
        isRoundOver: true,
        isGameOver: true,
        winnerSeat: seat,
      };
    }

    if (move.type === 'discard') {
      const hand = state.hands[seat]!;
      const card = hand.find((c) => c.id === move.cardId);
      if (!card) throw new IllegalMoveError(`Card not in hand: ${move.cardId}`);

      const newHand = hand.filter((c) => c.id !== move.cardId);
      const newHands = state.hands.map((h, i) => (i === seat ? newHand : h));
      const nextSeat = ((seat + 1) % state.players.length) as SeatIndex;

      return {
        ...state,
        hands: newHands,
        discardPile: [...state.discardPile, card],
        currentTurnSeat: nextSeat,
        phase: 'draw',
      };
    }

    throw new IllegalMoveError('Invalid move');
  }

  currentActor(state: RummyState): PlayerId | null {
    if (state.isRoundOver || state.isGameOver) return null;
    return state.players[state.currentTurnSeat] ?? null;
  }

  isRoundOver(state: RummyState): boolean {
    return state.isRoundOver;
  }

  scoreRound(state: RummyState): RoundResult {
    return {
      roundNumber: 1,
      scores: state.players.map((id, s) => ({
        playerId: id,
        seat: s,
        points: state.winnerSeat === s ? 0 : 80,
        coinDelta: state.winnerSeat === s ? 400 : -100,
      })),
      settled: false,
    };
  }

  isGameOver(state: RummyState): boolean {
    return state.isGameOver;
  }

  viewFor(state: RummyState, player: PlayerId | 'spectator'): RummyPublicView {
    const seat = player === 'spectator' ? -1 : state.players.indexOf(player);

    return {
      gameId: state.gameId,
      rules: state.rules,
      cutJoker: state.cutJoker,
      topDiscard: state.discardPile.length > 0 ? state.discardPile[state.discardPile.length - 1]! : null,
      stockCount: state.stock.length,
      currentTurnSeat: state.currentTurnSeat,
      phase: state.phase,
      isRoundOver: state.isRoundOver,
      isGameOver: state.isGameOver,
      winnerSeat: state.winnerSeat,
      players: state.players.map((id, s) => ({
        id,
        seat: s as SeatIndex,
        cardCount: state.hands[s]?.length ?? 0,
        cumulativeScore: state.cumulativeScores[s] ?? 0,
      })),
      myHand: seat >= 0 ? state.hands[seat] : undefined,
    };
  }

  autoMove(state: RummyState, player: PlayerId): RummyMove {
    const moves = this.legalMoves(state, player);
    return moves[0]!;
  }
}
