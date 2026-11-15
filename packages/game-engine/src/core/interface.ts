import { GameId, PlayerId, RoundResult } from './types.js';

export class IllegalMoveError extends Error {
  constructor(message: string, public readonly details?: Record<string, unknown>) {
    super(message);
    this.name = 'IllegalMoveError';
  }
}

export class NotYourTurnError extends Error {
  constructor(public readonly actor: PlayerId | null, public readonly attemptedBy: PlayerId) {
    super(`Not player's turn. Expected actor: ${actor}, attempted by: ${attemptedBy}`);
    this.name = 'NotYourTurnError';
  }
}

export class InvalidStateError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'InvalidStateError';
  }
}

/**
 * GameModule interface as defined in PRD Section 4.2.
 * Pure and deterministic from seed: no I/O, no Date.now(), no Math.random().
 * Shared Contract between server table runtime and bot modules.
 */
export interface GameModule<S, M, R, V = unknown> {
  /**
   * Unique game identifier ('callbreak' | 'marriage' | ...)
   */
  readonly id: GameId;

  /**
   * Default ruleset used in quick match
   */
  readonly defaultRules: R;

  /**
   * Clamps toggles to legal combos
   */
  validateRules(rules: R): R;

  /**
   * Initializes round/game state from player IDs, validated rules, and seed
   */
  setup(players: readonly PlayerId[], rules: R, seed: string): S;

  /**
   * Returns list of legal moves for the given player in state s
   */
  legalMoves(state: S, player: PlayerId): M[];

  /**
   * Applies move m for player p, returning a new immutable state.
   * Throws IllegalMoveError or NotYourTurnError if invalid.
   */
  applyMove(state: S, player: PlayerId, move: M): S;

  /**
   * Returns the PlayerId whose turn it is to act, or null if waiting for timer/round end.
   */
  currentActor(state: S): PlayerId | null;

  /**
   * True if current round has concluded.
   */
  isRoundOver(state: S): boolean;

  /**
   * Calculates scores and coin deltas for the concluded round.
   */
  scoreRound(state: S): RoundResult;

  /**
   * True if entire match/game has reached its completion criteria.
   */
  isGameOver(state: S): boolean;

  /**
   * The ONLY path from state to client.
   * Generates public projection with hidden cards masked for all other seats.
   */
  viewFor(state: S, player: PlayerId | 'spectator'): V;

  /**
   * Safe, deterministic fallback move when a turn timer expires.
   */
  autoMove(state: S, player: PlayerId): M;
}
