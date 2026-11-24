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
  DEFAULT_MARRIAGE_RULES,
  MarriageMove,
  MarriagePlayerState,
  MarriagePublicView,
  MarriageRules,
  MarriageState,
} from './types.js';
import { calculateHandMaalPoints } from './cards.js';
import { calculateMarriageSettlement } from './scoring.js';

export class MarriageGameModule
  implements GameModule<MarriageState, MarriageMove, MarriageRules, MarriagePublicView>
{
  readonly id: GameId = 'marriage';
  readonly defaultRules: MarriageRules = DEFAULT_MARRIAGE_RULES;

  validateRules(rules: MarriageRules): MarriageRules {
    return {
      mode: rules.mode ?? 'classic',
      alterEnabled: Boolean(rules.alterEnabled),
      manCardsCount: rules.manCardsCount ?? 0,
      manCardPoints: rules.manCardPoints ?? 0,
      dubleeRouteEnabled: Boolean(rules.dubleeRouteEnabled),
      stockOutRule: rules.stockOutRule ?? 'reshuffle',
      unseenPenalty: rules.unseenPenalty ?? 10,
      seenPenalty: rules.seenPenalty ?? 3,
      pointRate: rules.pointRate ?? 10,
    };
  }

  setup(players: readonly PlayerId[], rawRules: MarriageRules, seed: string): MarriageState {
    if (players.length < 2 || players.length > 5) {
      throw new Error('Marriage requires 2 to 5 players.');
    }
    const rules = this.validateRules(rawRules);
    // 3 standard decks (156 cards) + man cards
    const deck = createMultiDeck(3, rules.manCardsCount);
    const shuffled = seededShuffle(deck, seed);

    const hands: Card[][] = [];
    const playerStates: MarriagePlayerState[] = [];

    for (let i = 0; i < players.length; i++) {
      hands.push(shuffled.slice(i * 21, i * 21 + 21));
      playerStates.push({
        playerId: players[i]!,
        seat: i as SeatIndex,
        hasSeenMaal: false,
        exposedTunnelasAtStart: [],
        maalPoints: 0,
      });
    }

    const discardStart = shuffled.slice(players.length * 21, players.length * 21 + 1);
    // Cut maal card chosen face down from stock
    const maalCard = shuffled[players.length * 21 + 1]!;
    const stock = shuffled.slice(players.length * 21 + 2);

    return {
      gameId: 'marriage',
      rules,
      seed,
      players: [...players],
      hands,
      playerStates,
      stock,
      discardPile: discardStart,
      maalCard,
      currentTurnSeat: 0,
      phase: 'draw',
      isGameOver: false,
      winnerSeat: null,
      settlements: [],
    };
  }

  legalMoves(state: MarriageState, player: PlayerId): MarriageMove[] {
    const seat = state.players.indexOf(player);
    if (seat === -1 || seat !== state.currentTurnSeat || state.isGameOver) return [];

    const pState = state.playerStates[seat]!;
    const hand = state.hands[seat]!;

    if (state.phase === 'draw') {
      const moves: MarriageMove[] = [{ type: 'draw', source: 'stock' }];
      if (state.discardPile.length > 0) {
        moves.push({ type: 'draw', source: 'discard' });
      }
      return moves;
    }

    if (state.phase === 'discard') {
      const moves: MarriageMove[] = hand.map((c) => ({ type: 'discard', cardId: c.id }));

      if (!pState.hasSeenMaal) {
        // Can see maal with 3 pure combinations or 7 dublees
        moves.push({
          type: 'seeMaal',
          pureCombinations: [
            hand.slice(0, 3),
            hand.slice(3, 6),
            hand.slice(6, 9),
          ],
        });
      } else {
        // Can declare/finish
        moves.push({
          type: 'finish',
          combinations: [
            hand.slice(0, 3),
            hand.slice(3, 6),
            hand.slice(6, 9),
            hand.slice(9, 12),
            hand.slice(12, 15),
            hand.slice(15, 18),
            hand.slice(18, 21),
          ],
          discardCardId: hand[hand.length - 1]!.id,
        });
      }
      return moves;
    }

    return [];
  }

  applyMove(state: MarriageState, player: PlayerId, move: MarriageMove): MarriageState {
    const seat = state.players.indexOf(player) as SeatIndex;
    if (seat === -1 || seat !== state.currentTurnSeat) {
      throw new NotYourTurnError(this.currentActor(state), player);
    }
    const pState = state.playerStates[seat]!;

    if (move.type === 'draw') {
      let currentStock = [...state.stock];
      let currentDiscards = [...state.discardPile];
      if (currentStock.length === 0 && currentDiscards.length > 1) {
        const top = currentDiscards.pop()!;
        currentStock = currentDiscards;
        currentDiscards = [top];
      }

      const useStock = move.source === 'stock' && currentStock.length > 0;
      const drawn = useStock
        ? currentStock[currentStock.length - 1]!
        : currentDiscards[currentDiscards.length - 1]!;

      const newStock = useStock ? currentStock.slice(0, -1) : currentStock;
      const newDiscards = !useStock && currentDiscards.length > 1
        ? currentDiscards.slice(0, -1)
        : currentDiscards;

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

    if (move.type === 'seeMaal' || move.type === 'seeMaalDublee') {
      const updatedStates = state.playerStates.map((p, idx) =>
        idx === seat ? { ...p, hasSeenMaal: true } : p,
      );
      return {
        ...state,
        playerStates: updatedStates,
      };
    }

    if (move.type === 'finish') {
      // Calculate maal points for all players
      const settlementPlayers = state.playerStates.map((p, idx) => {
        const hand = state.hands[idx]!;
        const maalPoints = calculateHandMaalPoints(
          hand,
          state.maalCard!,
          state.rules,
          p.exposedTunnelasAtStart.length,
        );
        return {
          seat: idx,
          rawMaalPoints: maalPoints,
          hasSeenMaal: p.hasSeenMaal || idx === seat,
        };
      });

      const settlements = calculateMarriageSettlement(
        settlementPlayers,
        seat,
        false,
        state.rules,
      );

      return {
        ...state,
        isGameOver: true,
        winnerSeat: seat,
        settlements,
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

  currentActor(state: MarriageState): PlayerId | null {
    if (state.isGameOver) return null;
    return state.players[state.currentTurnSeat] ?? null;
  }

  isRoundOver(state: MarriageState): boolean {
    return state.isGameOver;
  }

  scoreRound(state: MarriageState): RoundResult {
    return {
      roundNumber: 1,
      scores: state.players.map((id, s) => {
        const settle = state.settlements.find((st) => st.seat === s);
        return {
          playerId: id,
          seat: s,
          points: settle ? -settle.paymentToWinner : 0,
          coinDelta: settle?.coinDelta ?? 0,
        };
      }),
      settled: false,
    };
  }

  isGameOver(state: MarriageState): boolean {
    return state.isGameOver;
  }

  viewFor(state: MarriageState, player: PlayerId | 'spectator'): MarriagePublicView {
    const seat = player === 'spectator' ? -1 : state.players.indexOf(player);
    const pState = seat >= 0 ? state.playerStates[seat] : null;

    return {
      gameId: 'marriage',
      rules: state.rules,
      currentTurnSeat: state.currentTurnSeat,
      phase: state.phase,
      topDiscard: state.discardPile.length > 0 ? state.discardPile[state.discardPile.length - 1]! : null,
      stockCount: state.stock.length,
      // Maal card visible only after player has seen maal
      maalCard: pState && pState.hasSeenMaal ? state.maalCard : null,
      isGameOver: state.isGameOver,
      winnerSeat: state.winnerSeat,
      players: state.playerStates.map((p) => ({
        id: p.playerId,
        seat: p.seat,
        cardCount: state.hands[p.seat]?.length ?? 0,
        hasSeenMaal: p.hasSeenMaal,
      })),
      myHand: seat >= 0 ? state.hands[seat] : undefined,
    };
  }

  autoMove(state: MarriageState, player: PlayerId): MarriageMove {
    const moves = this.legalMoves(state, player);
    return moves[0]!;
  }
}
