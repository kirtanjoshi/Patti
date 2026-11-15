import {
  Card,
  GameId,
  PlayerId,
  RoundResult,
  SeatIndex,
} from '../../core/types.js';
import { GameModule, IllegalMoveError, NotYourTurnError } from '../../core/interface.js';
import { createStandardDeck } from '../../core/card.js';
import { SeedRng, seededShuffle } from '../../core/prng.js';
import {
  CallbreakMove,
  CallbreakPublicView,
  CallbreakRules,
  CallbreakState,
  DEFAULT_CALLBREAK_RULES,
  PlayDirection,
} from './types.js';
import { calculateRoundScores } from './scoring.js';
import { checkRedeal, getLegalCards, getTrickWinnerCard } from './validation.js';

function nextSeat(current: SeatIndex, direction: PlayDirection): SeatIndex {
  if (direction === 'counterClockwise') {
    return ((current + 1) % 4) as SeatIndex;
  }
  return ((current + 3) % 4) as SeatIndex;
}

export class CallbreakGameModule
  implements GameModule<CallbreakState, CallbreakMove, CallbreakRules, CallbreakPublicView>
{
  readonly id: GameId = 'callbreak';
  readonly defaultRules: CallbreakRules = DEFAULT_CALLBREAK_RULES;

  validateRules(rules: CallbreakRules): CallbreakRules {
    return {
      scoringStyle: rules.scoringStyle === 'pagat' ? 'pagat' : 'nepali',
      maxCall: rules.maxCall === 13 ? 13 : 8,
      mustOvertake: Boolean(rules.mustOvertake),
      noSpadeLeadFirstTrick: Boolean(rules.noSpadeLeadFirstTrick),
      noWastingTrumps: Boolean(rules.noWastingTrumps),
      minTotalCalls: rules.minTotalCalls === 10 ? 10 : 0,
      numberOfDeals: rules.numberOfDeals === 3 ? 3 : rules.numberOfDeals === 10 ? 10 : 5,
      redealNoFaceCard: Boolean(rules.redealNoFaceCard),
      playDirection: rules.playDirection === 'clockwise' ? 'clockwise' : 'counterClockwise',
    };
  }

  setup(players: readonly PlayerId[], rawRules: CallbreakRules, seed: string): CallbreakState {
    if (players.length !== 4) {
      throw new Error('Callbreak requires exactly 4 players.');
    }
    const rules = this.validateRules(rawRules);
    return this.setupDeal(players, rules, seed, 0, 1, [], [0, 0, 0, 0]);
  }

  private setupDeal(
    players: readonly PlayerId[],
    rules: CallbreakRules,
    baseSeed: string,
    dealerSeat: SeatIndex,
    roundNumber: number,
    scoresHistory: readonly (readonly import('./types.js').CallbreakRoundScore[])[],
    cumulativeScores: readonly number[],
  ): CallbreakState {
    let dealSeed = `${baseSeed}_r${roundNumber}`;
    let redealCounter = 0;
    let hands: Card[][] = [];

    // Deal until redeal conditions are satisfied
    while (true) {
      const deck = createStandardDeck(0);
      const shuffled = seededShuffle(deck, `${dealSeed}_deal${redealCounter}`);
      hands = [
        shuffled.slice(0, 13),
        shuffled.slice(13, 26),
        shuffled.slice(26, 39),
        shuffled.slice(39, 52),
      ];

      if (!checkRedeal(hands, rules)) {
        break;
      }
      redealCounter++;
    }

    // First bidder is next player after dealer in play direction
    const firstBidder = nextSeat(dealerSeat, rules.playDirection);

    return {
      gameId: 'callbreak',
      rules,
      seed: baseSeed,
      players: [...players],
      dealerSeat,
      currentRound: roundNumber,
      phase: 'bidding',
      hands,
      bids: [null, null, null, null],
      tricksWon: [0, 0, 0, 0],
      currentTrick: {
        trickNumber: 1,
        leaderSeat: firstBidder,
        cards: [],
      },
      completedTricks: [],
      scoresHistory,
      cumulativeScores,
      currentTurnSeat: firstBidder,
    };
  }

  legalMoves(state: CallbreakState, player: PlayerId): CallbreakMove[] {
    const seat = state.players.indexOf(player);
    if (seat === -1 || seat !== state.currentTurnSeat) {
      return [];
    }

    if (state.phase === 'bidding') {
      const minBid = state.rules.scoringStyle === 'pagat' ? 2 : 1;
      const maxBid = state.rules.maxCall;
      const moves: CallbreakMove[] = [];
      for (let b = minBid; b <= maxBid; b++) {
        moves.push({ type: 'bid', bid: b });
      }
      return moves;
    }

    if (state.phase === 'playing') {
      const hand = state.hands[seat]!;
      const isFirstTrick = state.completedTricks.length === 0;
      const legal = getLegalCards(hand, state.currentTrick, state.rules, isFirstTrick);
      return legal.map((card) => ({ type: 'playCard', cardId: card.id }));
    }

    return [];
  }

  applyMove(state: CallbreakState, player: PlayerId, move: CallbreakMove): CallbreakState {
    const seat = state.players.indexOf(player) as SeatIndex;
    if (seat === -1 || seat !== state.currentTurnSeat) {
      throw new NotYourTurnError(this.currentActor(state), player);
    }

    if (state.phase === 'bidding') {
      if (move.type !== 'bid') {
        throw new IllegalMoveError('Expected a bid move during bidding phase.');
      }
      const minBid = state.rules.scoringStyle === 'pagat' ? 2 : 1;
      if (move.bid < minBid || move.bid > state.rules.maxCall) {
        throw new IllegalMoveError(`Bid must be between ${minBid} and ${state.rules.maxCall}.`);
      }

      const newBids = [...state.bids];
      newBids[seat] = move.bid;

      // Check if all players have bid
      const bidsDone = newBids.every((b) => b !== null);
      if (bidsDone) {
        const totalCalls = (newBids as number[]).reduce((sum, b) => sum + b, 0);
        if (state.rules.minTotalCalls === 10 && totalCalls <= 9) {
          // Redeal round due to minimum total calls
          return this.setupDeal(
            state.players,
            state.rules,
            `${state.seed}_redeal`,
            state.dealerSeat,
            state.currentRound,
            state.scoresHistory,
            state.cumulativeScores,
          );
        }

        // Bidding complete: leader of trick 1 is player after dealer
        const firstLeader = nextSeat(state.dealerSeat, state.rules.playDirection);
        return {
          ...state,
          bids: newBids,
          phase: 'playing',
          currentTurnSeat: firstLeader,
          currentTrick: {
            trickNumber: 1,
            leaderSeat: firstLeader,
            cards: [],
          },
        };
      }

      // Next player's turn to bid
      return {
        ...state,
        bids: newBids,
        currentTurnSeat: nextSeat(seat, state.rules.playDirection),
      };
    }

    if (state.phase === 'playing') {
      if (move.type !== 'playCard') {
        throw new IllegalMoveError('Expected a playCard move during playing phase.');
      }

      const hand = state.hands[seat]!;
      const card = hand.find((c) => c.id === move.cardId);
      if (!card) {
        throw new IllegalMoveError(`Card ${move.cardId} not in player hand.`);
      }

      const isFirstTrick = state.completedTricks.length === 0;
      const legalCards = getLegalCards(hand, state.currentTrick, state.rules, isFirstTrick);
      if (!legalCards.some((c) => c.id === card.id)) {
        throw new IllegalMoveError(`Card ${card.id} is not a legal play.`);
      }

      // Remove card from hand
      const newHand = hand.filter((c) => c.id !== card.id);
      const newHands = state.hands.map((h, i) => (i === seat ? newHand : h));

      const updatedTrickCards = [
        ...state.currentTrick.cards,
        { playerId: player, seat, card },
      ];

      // If trick is not complete (less than 4 cards)
      if (updatedTrickCards.length < 4) {
        return {
          ...state,
          hands: newHands,
          currentTrick: {
            ...state.currentTrick,
            cards: updatedTrickCards,
          },
          currentTurnSeat: nextSeat(seat, state.rules.playDirection),
        };
      }

      // Trick complete: evaluate winner
      const completedTrick = {
        ...state.currentTrick,
        cards: updatedTrickCards,
      };
      const winningCard = getTrickWinnerCard(completedTrick)!;
      const winnerSeat = winningCard.seat;

      const newTricksWon = [...state.tricksWon];
      newTricksWon[winnerSeat] = (newTricksWon[winnerSeat] ?? 0) + 1;

      const completedTricks = [...state.completedTricks, { ...completedTrick, winnerSeat }];

      // Check if round is complete (13 tricks played)
      if (completedTricks.length === 13) {
        const roundScores = calculateRoundScores(
          state.rules,
          state.players,
          state.bids,
          newTricksWon,
          state.cumulativeScores,
        );

        const newCumulative = roundScores.map((s) => s.cumulativeScore);
        const newHistory = [...state.scoresHistory, roundScores];
        const isGameEnd = state.currentRound >= state.rules.numberOfDeals;

        return {
          ...state,
          hands: newHands,
          tricksWon: newTricksWon,
          completedTricks,
          currentTrick: { trickNumber: 13, leaderSeat: winnerSeat, cards: updatedTrickCards, winnerSeat },
          scoresHistory: newHistory,
          cumulativeScores: newCumulative,
          phase: isGameEnd ? 'gameOver' : 'roundOver',
          currentTurnSeat: winnerSeat,
        };
      }

      // Next trick: winner leads
      return {
        ...state,
        hands: newHands,
        tricksWon: newTricksWon,
        completedTricks,
        currentTrick: {
          trickNumber: completedTricks.length + 1,
          leaderSeat: winnerSeat,
          cards: [],
        },
        currentTurnSeat: winnerSeat,
      };
    }

    throw new IllegalMoveError(`Cannot apply move in phase: ${state.phase}`);
  }

  currentActor(state: CallbreakState): PlayerId | null {
    if (state.phase === 'roundOver' || state.phase === 'gameOver') {
      return null;
    }
    return state.players[state.currentTurnSeat] ?? null;
  }

  isRoundOver(state: CallbreakState): boolean {
    return state.phase === 'roundOver' || state.phase === 'gameOver';
  }

  scoreRound(state: CallbreakState): RoundResult {
    const latestRoundScores = state.scoresHistory[state.scoresHistory.length - 1] ?? [];
    return {
      roundNumber: state.currentRound,
      scores: latestRoundScores.map((s) => ({
        playerId: s.playerId,
        seat: s.seat,
        points: s.roundScore,
        coinDelta: 0,
        details: {
          bid: s.bid,
          tricksWon: s.tricksWon,
          cumulativeScore: s.cumulativeScore,
        },
      })),
      settled: false,
    };
  }

  isGameOver(state: CallbreakState): boolean {
    return state.phase === 'gameOver';
  }

  viewFor(state: CallbreakState, player: PlayerId | 'spectator'): CallbreakPublicView {
    const authenticatedSeat = player === 'spectator' ? -1 : state.players.indexOf(player);

    const playersView = state.players.map((id, seat) => ({
      id,
      seat: seat as SeatIndex,
      cardCount: state.hands[seat]?.length ?? 0,
      bid: state.bids[seat] ?? null,
      tricksWon: state.tricksWon[seat] ?? 0,
      cumulativeScore: state.cumulativeScores[seat] ?? 0,
    }));

    return {
      gameId: 'callbreak',
      roundNumber: state.currentRound,
      phase: state.phase,
      dealerSeat: state.dealerSeat,
      currentTurnSeat: state.currentTurnSeat,
      rules: state.rules,
      players: playersView,
      myHand: authenticatedSeat >= 0 ? state.hands[authenticatedSeat] : undefined,
      currentTrick: state.currentTrick.cards.map((pc) => ({
        seat: pc.seat,
        card: pc.card,
      })),
      leadSuit: state.currentTrick.cards[0]?.card.suit as 'S' | 'H' | 'D' | 'C' | null,
      lastCompletedTrick: state.completedTricks[state.completedTricks.length - 1],
      scoresHistory: state.scoresHistory,
    };
  }

  autoMove(state: CallbreakState, player: PlayerId): CallbreakMove {
    const moves = this.legalMoves(state, player);
    if (moves.length === 0) {
      throw new IllegalMoveError(`No legal moves available for ${player}.`);
    }

    if (state.phase === 'bidding') {
      // Lowest safe bid
      return moves[0]!;
    }

    // In play phase: choose lowest rank legal card to minimize risk
    return moves[0]!;
  }
}
