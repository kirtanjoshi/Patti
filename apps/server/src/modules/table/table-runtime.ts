import {
  CallbreakGameModule,
  CallbreakState,
  DEFAULT_CALLBREAK_RULES,
  DhumbalGameModule,
  GameId,
  GameModule,
  JutpattiGameModule,
  KittiGameModule,
  MarriageGameModule,
  RummyGameModule,
  SeedRng,
  TableSeat,
  TableState,
  SeatStatus,
  TeenPattiGameModule,
} from '@patii/game-engine';
import { CallbreakBotStrategy } from '@patii/bots';

export type TableEventBroadcaster = (event: string, payload: Record<string, unknown>) => void;

export interface TableConfig {
  readonly tableId: string;
  readonly gameId: GameId;
  readonly tier: string;
  readonly stake: bigint;
  readonly rules?: Record<string, unknown>;
  readonly seatsCount: number;
}

export function createGameModule(gameId: GameId): GameModule<any, any, any, any> {
  switch (gameId) {
    case 'callbreak':
      return new CallbreakGameModule();
    case 'marriage':
      return new MarriageGameModule();
    case 'teenpatti':
      return new TeenPattiGameModule();
    case 'kitti':
      return new KittiGameModule();
    case 'dhumbal':
      return new DhumbalGameModule();
    case 'jutpatti':
      return new JutpattiGameModule();
    case 'rummy':
      return new RummyGameModule(false);
    case 'jokerrummy':
      return new RummyGameModule(true);
    default:
      return new CallbreakGameModule();
  }
}

export class TableRuntime {
  public state: TableState = TableState.WAITING;
  public version = 1;
  public seats: TableSeat[] = [];
  public engineState: any = null;
  public turnDeadlineEpochMs: number | null = null;
  public readonly module: GameModule<any, any, any, any>;
  private readonly callbreakBot = new CallbreakBotStrategy('medium');
  private botRng: SeedRng;

  constructor(
    public readonly config: TableConfig,
    private readonly broadcast: TableEventBroadcaster,
  ) {
    this.module = createGameModule(config.gameId);
    this.botRng = new SeedRng(`table_${config.tableId}_bots`);
    for (let s = 0; s < config.seatsCount; s++) {
      this.seats.push({
        seat: s,
        playerId: null,
        status: SeatStatus.EMPTY,
        isBot: false,
        extraBankRemainingSeconds: 20,
        missedTurnsCount: 0,
      });
    }
  }

  public addPlayer(seat: number, playerId: string, isBot = false): void {
    if (seat < 0 || seat >= this.config.seatsCount) {
      throw new Error(`Invalid seat: ${seat}`);
    }
    this.seats[seat] = {
      seat,
      playerId,
      status: SeatStatus.OCCUPIED,
      isBot,
      botDifficulty: isBot ? 'medium' : undefined,
      extraBankRemainingSeconds: 20,
      missedTurnsCount: 0,
    };

    // Check if table is full -> transition to READY
    const full = this.seats.every((s) => s.status === SeatStatus.OCCUPIED);
    if (full && this.state === TableState.WAITING) {
      this.state = TableState.READY;
      this.startDealCountdown();
    }
  }

  public markDisconnected(playerId: string): void {
    const seatIdx = this.seats.findIndex((s) => s.playerId === playerId);
    if (seatIdx !== -1) {
      this.seats[seatIdx] = {
        ...this.seats[seatIdx]!,
        status: SeatStatus.DISCONNECTED,
      };
      this.broadcastEvent('seat:status', { seat: seatIdx, status: 'DISCONNECTED' });
    }
  }

  public markReconnected(playerId: string): void {
    const seatIdx = this.seats.findIndex((s) => s.playerId === playerId);
    if (seatIdx !== -1) {
      this.seats[seatIdx] = {
        ...this.seats[seatIdx]!,
        status: SeatStatus.OCCUPIED,
      };
      this.broadcastEvent('seat:status', { seat: seatIdx, status: 'OCCUPIED' });
    }
  }

  private startDealCountdown(): void {
    this.state = TableState.DEALING;
    const playerIds = this.seats.map((s) => s.playerId!);
    const seed = `match_${this.config.tableId}_${Date.now()}`;
    const initialRules = this.config.rules ?? this.module.defaultRules;
    this.engineState = this.module.setup(playerIds, initialRules, seed);

    this.state = TableState.PLAYING;
    this.version++;
    this.broadcast('table:sync_request', { tableId: this.config.tableId, version: this.version });
    this.promptCurrentTurn();
  }

  private promptCurrentTurn(): void {
    if (!this.engineState || this.module.isGameOver(this.engineState)) {
      return;
    }

    const currentActor = this.module.currentActor(this.engineState);
    if (!currentActor) return;

    const currentSeat = this.seats.findIndex((s) => s.playerId === currentActor);
    const turnDurationSeconds = 15;
    this.turnDeadlineEpochMs = Date.now() + turnDurationSeconds * 1000;

    this.broadcast('table:turn', {
      tableId: this.config.tableId,
      seat: currentSeat,
      deadlineEpochMs: this.turnDeadlineEpochMs,
      version: this.version,
    });

    const seat = this.seats[currentSeat];
    if (seat?.isBot) {
      this.scheduleBotMove(currentActor, currentSeat);
    }
  }

  private scheduleBotMove(playerId: string, seatIndex: number): void {
    if (!this.engineState) return;

    setTimeout(() => {
      try {
        if (!this.engineState || this.module.currentActor(this.engineState) !== playerId) return;
        const view = this.module.viewFor(this.engineState, playerId);
        let move: any;

        if (this.config.gameId === 'callbreak') {
          move = this.callbreakBot.decide(view, this.botRng);
        } else {
          move = this.module.autoMove(this.engineState, playerId);
        }

        this.applyPlayerMove(playerId, this.version, move);
      } catch {
        if (this.engineState) {
          const fallback = this.module.autoMove(this.engineState, playerId);
          this.applyPlayerMove(playerId, this.version, fallback);
        }
      }
    }, 800);
  }

  public applyPlayerMove(playerId: string, clientVersion: number, move: any): void {
    if (!this.engineState) {
      throw new Error('Game not started.');
    }
    if (clientVersion < this.version) {
      throw new Error('STALE_VERSION');
    }

    this.engineState = this.module.applyMove(this.engineState, playerId, move);
    this.version++;

    this.broadcastEvent('table:moved', {
      playerId,
      move,
      phase: this.engineState.phase ?? 'playing',
    });
    this.broadcast('table:sync_request', { tableId: this.config.tableId, version: this.version });

    if (this.module.isGameOver(this.engineState)) {
      this.state = TableState.GAME_END;
      const result = this.module.scoreRound(this.engineState);
      this.broadcast('table:result', {
        tableId: this.config.tableId,
        gameId: this.config.gameId,
        roundNumber: this.engineState.currentRound ?? 1,
        isGameOver: true,
        scores: result.scores,
      });
      return;
    }

    this.promptCurrentTurn();
  }

  public getViewFor(playerId: string | 'spectator'): any {
    if (!this.engineState) return null;
    return this.module.viewFor(this.engineState, playerId);
  }

  private broadcastEvent(event: string, payload: Record<string, unknown>): void {
    this.broadcast('table:event', {
      tableId: this.config.tableId,
      version: this.version,
      event,
      payload,
    });
  }
}
