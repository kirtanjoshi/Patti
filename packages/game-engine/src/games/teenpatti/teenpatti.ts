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
  DEFAULT_TEEN_PATTI_RULES,
  TeenPattiMove,
  TeenPattiPlayerState,
  TeenPattiPublicView,
  TeenPattiRules,
  TeenPattiState,
} from './types.js';

export class TeenPattiGameModule
  implements GameModule<TeenPattiState, TeenPattiMove, TeenPattiRules, TeenPattiPublicView>
{
  readonly id: GameId = 'teenpatti';
  readonly defaultRules: TeenPattiRules = DEFAULT_TEEN_PATTI_RULES;

  validateRules(rules: TeenPattiRules): TeenPattiRules {
    return {
      variant: rules.variant ?? 'classic',
      boot: Math.max(10, rules.boot ?? 100),
      blindLimitRounds: rules.blindLimitRounds ?? 4,
      chaalLimitMultiplier: rules.chaalLimitMultiplier ?? 128,
      potLimitMultiplier: rules.potLimitMultiplier ?? 1024,
    };
  }

  setup(players: readonly PlayerId[], rawRules: TeenPattiRules, seed: string): TeenPattiState {
    if (players.length < 2 || players.length > 7) {
      throw new Error('Teen Patti requires 2 to 7 players.');
    }
    const rules = this.validateRules(rawRules);
    const deck = createStandardDeck(0);
    const shuffled = seededShuffle(deck, seed);

    const hands: Card[][] = [];
    const playerStates: TeenPattiPlayerState[] = [];
    let pot = 0;

    for (let i = 0; i < players.length; i++) {
      hands.push(shuffled.slice(i * 3, i * 3 + 3));
      playerStates.push({
        playerId: players[i]!,
        seat: i as SeatIndex,
        isSeen: false,
        isPacked: false,
        totalBet: rules.boot,
        blindRoundsPlayed: 0,
      });
      pot += rules.boot;
    }

    return {
      gameId: 'teenpatti',
      rules,
      seed,
      players: [...players],
      dealerSeat: 0,
      currentTurnSeat: 1 % players.length as SeatIndex,
      hands,
      playerStates,
      currentStake: rules.boot,
      pot,
      isGameOver: false,
      winnerSeats: [],
    };
  }

  legalMoves(state: TeenPattiState, player: PlayerId): TeenPattiMove[] {
    if (state.isGameOver) return [];
    const seat = state.players.indexOf(player);
    if (seat === -1 || seat !== state.currentTurnSeat) return [];

    const pState = state.playerStates[seat]!;
    if (pState.isPacked) return [];

    const moves: TeenPattiMove[] = [{ type: 'pack' }];

    if (!pState.isSeen) {
      moves.push({ type: 'seeCards' });
      // Blind bet: 1x to 2x currentStake
      if (pState.blindRoundsPlayed < state.rules.blindLimitRounds) {
        moves.push({ type: 'blind', amount: state.currentStake });
        moves.push({ type: 'blind', amount: state.currentStake * 2 });
      }
    } else {
      // Chaal bet: 2x to 4x currentStake
      moves.push({ type: 'chaal', amount: state.currentStake * 2 });
      moves.push({ type: 'chaal', amount: state.currentStake * 4 });
    }

    // Show is legal when only 2 active players remain
    const activeSeats = state.playerStates.filter((p) => !p.isPacked);
    if (activeSeats.length === 2) {
      moves.push({ type: 'show' });
    }

    return moves;
  }

  applyMove(state: TeenPattiState, player: PlayerId, move: TeenPattiMove): TeenPattiState {
    const seat = state.players.indexOf(player) as SeatIndex;
    if (seat === -1 || seat !== state.currentTurnSeat) {
      throw new NotYourTurnError(this.currentActor(state), player);
    }
    const pState = state.playerStates[seat]!;

    if (move.type === 'seeCards') {
      const updatedStates = state.playerStates.map((p, idx) =>
        idx === seat ? { ...p, isSeen: true } : p,
      );
      return {
        ...state,
        playerStates: updatedStates,
      };
    }

    if (move.type === 'pack') {
      const updatedStates = state.playerStates.map((p, idx) =>
        idx === seat ? { ...p, isPacked: true } : p,
      );
      const remaining = updatedStates.filter((p) => !p.isPacked);

      if (remaining.length === 1) {
        return {
          ...state,
          playerStates: updatedStates,
          isGameOver: true,
          winnerSeats: [remaining[0]!.seat],
        };
      }

      return {
        ...state,
        playerStates: updatedStates,
        currentTurnSeat: this.nextActiveSeat(updatedStates, seat),
      };
    }

    if (move.type === 'blind' || move.type === 'chaal') {
      const betAmount = move.amount;
      const updatedStates = state.playerStates.map((p, idx) =>
        idx === seat
          ? {
              ...p,
              totalBet: p.totalBet + betAmount,
              blindRoundsPlayed: move.type === 'blind' ? p.blindRoundsPlayed + 1 : p.blindRoundsPlayed,
            }
          : p,
      );

      const newStake = move.type === 'blind' ? betAmount : Math.floor(betAmount / 2);

      return {
        ...state,
        playerStates: updatedStates,
        pot: state.pot + betAmount,
        currentStake: newStake,
        currentTurnSeat: this.nextActiveSeat(updatedStates, seat),
      };
    }

    if (move.type === 'show') {
      const active = state.playerStates.filter((p) => !p.isPacked);
      if (active.length !== 2) {
        throw new IllegalMoveError('Show requires exactly 2 active players.');
      }

      // Simplified comparison between remaining 2 players (highest card total for baseline)
      const seat0 = active[0]!.seat;
      const seat1 = active[1]!.seat;
      const score0 = state.hands[seat0]!.reduce((s, c) => s + c.rank, 0);
      const score1 = state.hands[seat1]!.reduce((s, c) => s + c.rank, 0);
      const winnerSeat = score0 >= score1 ? seat0 : seat1;

      return {
        ...state,
        isGameOver: true,
        winnerSeats: [winnerSeat],
      };
    }

    throw new IllegalMoveError(`Unknown move type: ${(move as any).type}`);
  }

  private nextActiveSeat(states: readonly TeenPattiPlayerState[], current: SeatIndex): SeatIndex {
    const total = states.length;
    let next = (current + 1) % total;
    while (states[next]?.isPacked) {
      next = (next + 1) % total;
    }
    return next as SeatIndex;
  }

  currentActor(state: TeenPattiState): PlayerId | null {
    if (state.isGameOver) return null;
    return state.players[state.currentTurnSeat] ?? null;
  }

  isRoundOver(state: TeenPattiState): boolean {
    return state.isGameOver;
  }

  scoreRound(state: TeenPattiState): RoundResult {
    return {
      roundNumber: 1,
      scores: state.playerStates.map((p) => ({
        playerId: p.playerId,
        seat: p.seat,
        points: state.winnerSeats.includes(p.seat) ? 1 : 0,
        coinDelta: state.winnerSeats.includes(p.seat) ? state.pot - p.totalBet : -p.totalBet,
      })),
      pot: state.pot,
      settled: false,
    };
  }

  isGameOver(state: TeenPattiState): boolean {
    return state.isGameOver;
  }

  viewFor(state: TeenPattiState, player: PlayerId | 'spectator'): TeenPattiPublicView {
    const seat = player === 'spectator' ? -1 : state.players.indexOf(player);
    const pState = seat >= 0 ? state.playerStates[seat] : null;

    return {
      gameId: 'teenpatti',
      rules: state.rules,
      currentTurnSeat: state.currentTurnSeat,
      currentStake: state.currentStake,
      pot: state.pot,
      isGameOver: state.isGameOver,
      winnerSeats: state.winnerSeats,
      players: state.playerStates.map((p) => ({
        id: p.playerId,
        seat: p.seat,
        isSeen: p.isSeen,
        isPacked: p.isPacked,
        totalBet: p.totalBet,
      })),
      myHand: pState && pState.isSeen ? state.hands[seat] : undefined,
    };
  }

  autoMove(state: TeenPattiState, player: PlayerId): TeenPattiMove {
    return { type: 'pack' };
  }
}
