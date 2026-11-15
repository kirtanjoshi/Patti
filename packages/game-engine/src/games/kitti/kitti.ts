import {
  Card,
  GameId,
  PlayerId,
  RoundResult,
  SeatIndex,
} from '../../core/types.js';
import { GameModule, IllegalMoveError } from '../../core/interface.js';
import { createStandardDeck } from '../../core/card.js';
import { seededShuffle } from '../../core/prng.js';
import {
  DEFAULT_KITTI_RULES,
  KittiMove,
  KittiPublicView,
  KittiRules,
  KittiState,
} from './types.js';

export class KittiGameModule
  implements GameModule<KittiState, KittiMove, KittiRules, KittiPublicView>
{
  readonly id: GameId = 'kitti';
  readonly defaultRules: KittiRules = DEFAULT_KITTI_RULES;

  validateRules(rules: KittiRules): KittiRules {
    return {
      winRule: rules.winRule === 'two_consecutive' ? 'two_consecutive' : 'any_two',
      salamiBonus: Boolean(rules.salamiBonus),
      twoThreeFiveRule: Boolean(rules.twoThreeFiveRule),
      maxKittiCarryOvers: rules.maxKittiCarryOvers ?? 3,
    };
  }

  setup(players: readonly PlayerId[], rawRules: KittiRules, seed: string): KittiState {
    if (players.length < 2 || players.length > 5) {
      throw new Error('Kitti requires 2 to 5 players.');
    }
    const rules = this.validateRules(rawRules);
    const deck = createStandardDeck(0);
    const shuffled = seededShuffle(deck, seed);

    const rawHands: Card[][] = [];
    const arrangedHands: (null)[] = [];
    const showWins: number[] = [];

    for (let i = 0; i < players.length; i++) {
      rawHands.push(shuffled.slice(i * 9, i * 9 + 9));
      arrangedHands.push(null);
      showWins.push(0);
    }

    return {
      gameId: 'kitti',
      rules,
      seed,
      players: [...players],
      rawHands,
      arrangedHands,
      showWins,
      currentShow: 1,
      pot: players.length * 100,
      isRoundOver: false,
      isGameOver: false,
      winnerSeat: null,
      isKittiCarryOver: false,
    };
  }

  legalMoves(state: KittiState, player: PlayerId): KittiMove[] {
    const seat = state.players.indexOf(player);
    if (seat === -1 || state.isGameOver || state.arrangedHands[seat] !== null) {
      return [];
    }

    const cards = state.rawHands[seat]!;
    // Default auto-arrangement (split into 3 hands of 3)
    const h1 = cards.slice(0, 3);
    const h2 = cards.slice(3, 6);
    const h3 = cards.slice(6, 9);

    return [
      { type: 'arrange', hands: [h1, h2, h3] },
      { type: 'fold' },
    ];
  }

  applyMove(state: KittiState, player: PlayerId, move: KittiMove): KittiState {
    const seat = state.players.indexOf(player) as SeatIndex;
    if (seat === -1) {
      throw new IllegalMoveError(`Player ${player} is not part of this table.`);
    }

    if (move.type === 'fold') {
      const newArranged = [...state.arrangedHands];
      newArranged[seat] = null;
      return { ...state };
    }

    if (move.type === 'arrange') {
      const newArranged = [...state.arrangedHands];
      newArranged[seat] = move.hands;

      // Check if all players have finished arrangement
      const allDone = newArranged.every((h) => h !== null);
      if (!allDone) {
        return { ...state, arrangedHands: newArranged };
      }

      // Evaluate 3 shows
      const showWins = [0, 0, 0, 0, 0].slice(0, state.players.length);
      for (let s = 0; s < 3; s++) {
        let bestSeat = 0;
        let bestTotal = -1;
        for (let p = 0; p < state.players.length; p++) {
          const hand = newArranged[p]![s]!;
          const sum = hand.reduce((acc, c) => acc + c.rank, 0);
          if (sum > bestTotal) {
            bestTotal = sum;
            bestSeat = p;
          }
        }
        showWins[bestSeat]++;
      }

      // Check for winner (first to win 2 shows or all 3)
      let winnerSeat: SeatIndex | null = null;
      for (let i = 0; i < showWins.length; i++) {
        if (showWins[i]! >= 2) {
          winnerSeat = i as SeatIndex;
          break;
        }
      }

      const isKitti = winnerSeat === null;

      return {
        ...state,
        arrangedHands: newArranged,
        showWins,
        isRoundOver: true,
        isGameOver: true,
        winnerSeat,
        isKittiCarryOver: isKitti,
      };
    }

    throw new IllegalMoveError('Invalid move type.');
  }

  currentActor(state: KittiState): PlayerId | null {
    if (state.isGameOver) return null;
    const pendingIdx = state.arrangedHands.findIndex((h) => h === null);
    return pendingIdx !== -1 ? state.players[pendingIdx]! : null;
  }

  isRoundOver(state: KittiState): boolean {
    return state.isRoundOver;
  }

  scoreRound(state: KittiState): RoundResult {
    return {
      roundNumber: 1,
      scores: state.players.map((id, seat) => ({
        playerId: id,
        seat,
        points: state.showWins[seat] ?? 0,
        coinDelta: state.winnerSeat === seat ? state.pot : -100,
      })),
      pot: state.pot,
      settled: false,
    };
  }

  isGameOver(state: KittiState): boolean {
    return state.isGameOver;
  }

  viewFor(state: KittiState, player: PlayerId | 'spectator'): KittiPublicView {
    const seat = player === 'spectator' ? -1 : state.players.indexOf(player);

    return {
      gameId: 'kitti',
      rules: state.rules,
      currentShow: state.currentShow,
      pot: state.pot,
      isRoundOver: state.isRoundOver,
      isGameOver: state.isGameOver,
      winnerSeat: state.winnerSeat,
      isKittiCarryOver: state.isKittiCarryOver,
      players: state.players.map((id, s) => ({
        id,
        seat: s as SeatIndex,
        isArranged: state.arrangedHands[s] !== null,
        showWins: state.showWins[s] ?? 0,
      })),
      myCards: seat >= 0 ? state.rawHands[seat] : undefined,
    };
  }

  autoMove(state: KittiState, player: PlayerId): KittiMove {
    const seat = state.players.indexOf(player);
    const cards = state.rawHands[seat]!;
    return {
      type: 'arrange',
      hands: [cards.slice(0, 3), cards.slice(3, 6), cards.slice(6, 9)],
    };
  }
}
