import {
  Card,
  GameId,
  PlayerId,
  RoundResult,
  SeatIndex,
} from '../../core/types.js';
import { GameModule, IllegalMoveError, NotYourTurnError } from '../../core/interface.js';
import { createStandardDeck } from '../../core/card.js';
import { seededShuffle } from '../../core/prng.js';
import {
  DEFAULT_JUTPATTI_RULES,
  JutpattiMove,
  JutpattiPublicView,
  JutpattiRules,
  JutpattiState,
} from './types.js';

export function isAllPairs(hand: readonly Card[], jokerRank?: number): boolean {
  if (hand.length % 2 !== 0) return false;

  const ranks: number[] = [];
  let jokers = 0;

  for (const c of hand) {
    if (jokerRank !== undefined && c.rank === jokerRank) {
      jokers++;
    } else {
      ranks.push(c.rank);
    }
  }

  // Count frequencies of normal ranks
  const freq = new Map<number, number>();
  for (const r of ranks) {
    freq.set(r, (freq.get(r) ?? 0) + 1);
  }

  let unpairedCount = 0;
  for (const count of freq.values()) {
    if (count % 2 !== 0) {
      unpairedCount++;
    }
  }

  return jokers >= unpairedCount;
}

export class JutpattiGameModule
  implements GameModule<JutpattiState, JutpattiMove, JutpattiRules, JutpattiPublicView>
{
  readonly id: GameId = 'jutpatti';
  readonly defaultRules: JutpattiRules = DEFAULT_JUTPATTI_RULES;

  validateRules(rules: JutpattiRules): JutpattiRules {
    return {
      handSize: rules.handSize ?? 9,
      jokerCardEnabled: Boolean(rules.jokerCardEnabled),
      pointsMode: Boolean(rules.pointsMode),
    };
  }

  setup(players: readonly PlayerId[], rawRules: JutpattiRules, seed: string): JutpattiState {
    if (players.length < 2 || players.length > 5) {
      throw new Error('Jutpatti requires 2 to 5 players.');
    }
    const rules = this.validateRules(rawRules);
    const deck = createStandardDeck(0);
    const shuffled = seededShuffle(deck, seed);

    const hands: Card[][] = [];
    const size = rules.handSize;
    for (let i = 0; i < players.length; i++) {
      hands.push(shuffled.slice(i * size, i * size + size));
    }

    const jokerCard = rules.jokerCardEnabled
      ? shuffled[players.length * size]!
      : null;

    const discardStart = shuffled.slice(players.length * size + 1, players.length * size + 2);
    const stock = shuffled.slice(players.length * size + 2);

    return {
      gameId: 'jutpatti',
      rules,
      seed,
      players: [...players],
      hands,
      jokerCard,
      stock,
      discardPile: discardStart,
      currentTurnSeat: 0,
      phase: 'draw',
      isGameOver: false,
      winnerSeat: null,
    };
  }

  legalMoves(state: JutpattiState, player: PlayerId): JutpattiMove[] {
    const seat = state.players.indexOf(player);
    if (seat === -1 || seat !== state.currentTurnSeat || state.isGameOver) return [];

    if (state.phase === 'draw') {
      const moves: JutpattiMove[] = [{ type: 'draw', source: 'stock' }];
      if (state.discardPile.length > 0) {
        moves.push({ type: 'draw', source: 'discard' });
      }
      return moves;
    }

    if (state.phase === 'discard') {
      const hand = state.hands[seat]!;
      const moves: JutpattiMove[] = hand.map((c) => ({ type: 'discard', cardId: c.id }));

      if (isAllPairs(hand, state.jokerCard?.rank)) {
        moves.push({ type: 'declare' });
      }
      return moves;
    }

    return [];
  }

  applyMove(state: JutpattiState, player: PlayerId, move: JutpattiMove): JutpattiState {
    const seat = state.players.indexOf(player) as SeatIndex;
    if (seat === -1 || seat !== state.currentTurnSeat) {
      throw new NotYourTurnError(this.currentActor(state), player);
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
      const hand = state.hands[seat]!;
      if (!isAllPairs(hand, state.jokerCard?.rank)) {
        throw new IllegalMoveError('Hand does not consist of all valid pairs.');
      }
      return {
        ...state,
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

  currentActor(state: JutpattiState): PlayerId | null {
    if (state.isGameOver) return null;
    return state.players[state.currentTurnSeat] ?? null;
  }

  isRoundOver(state: JutpattiState): boolean {
    return state.isGameOver;
  }

  scoreRound(state: JutpattiState): RoundResult {
    return {
      roundNumber: 1,
      scores: state.players.map((id, s) => ({
        playerId: id,
        seat: s,
        points: state.winnerSeat === s ? 1 : 0,
        coinDelta: state.winnerSeat === s ? 400 : -100,
      })),
      settled: false,
    };
  }

  isGameOver(state: JutpattiState): boolean {
    return state.isGameOver;
  }

  viewFor(state: JutpattiState, player: PlayerId | 'spectator'): JutpattiPublicView {
    const seat = player === 'spectator' ? -1 : state.players.indexOf(player);

    return {
      gameId: 'jutpatti',
      rules: state.rules,
      jokerCard: state.jokerCard,
      topDiscard: state.discardPile.length > 0 ? state.discardPile[state.discardPile.length - 1]! : null,
      stockCount: state.stock.length,
      currentTurnSeat: state.currentTurnSeat,
      phase: state.phase,
      isGameOver: state.isGameOver,
      winnerSeat: state.winnerSeat,
      players: state.players.map((id, s) => ({
        id,
        seat: s as SeatIndex,
        cardCount: state.hands[s]?.length ?? 0,
      })),
      myHand: seat >= 0 ? state.hands[seat] : undefined,
    };
  }

  autoMove(state: JutpattiState, player: PlayerId): JutpattiMove {
    const moves = this.legalMoves(state, player);
    return moves[0]!;
  }
}
