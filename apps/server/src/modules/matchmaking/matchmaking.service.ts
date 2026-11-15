import { Injectable } from '@nestjs/common';
import { WalletService } from '../wallet/wallet.service.js';
import { TableService } from '../table/table.service.js';
import { TableEventBroadcaster } from '../table/table-runtime.js';

interface QueuedPlayer {
  readonly userId: string;
  readonly socketId: string;
  readonly gameId: string;
  readonly tier: string;
  readonly joinedAt: number;
}

@Injectable()
export class MatchmakingService {
  private readonly queues = new Map<string, QueuedPlayer[]>();

  constructor(
    private readonly walletService: WalletService,
    private readonly tableService: TableService,
  ) {}

  async joinQueue(
    userId: string,
    socketId: string,
    gameId: string,
    tier: string,
    onMatched: (matchedTableId: string, seat: number) => void,
    broadcaster: TableEventBroadcaster,
  ): Promise<void> {
    const queueKey = `${gameId}:${tier}`;
    const queue = this.queues.get(queueKey) ?? [];

    // Hold 100 coins entry fee
    await this.walletService.holdStake(userId, BigInt(100), `queue_${Date.now()}`);

    const queuedPlayer: QueuedPlayer = {
      userId,
      socketId,
      gameId,
      tier,
      joinedAt: Date.now(),
    };
    queue.push(queuedPlayer);
    this.queues.set(queueKey, queue);

    // If 4 human players present, match immediately
    if (queue.length >= 4) {
      const group = queue.splice(0, 4);
      const tableId = `tbl_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
      const table = this.tableService.createTable(tableId, tier, BigInt(100), broadcaster);

      group.forEach((p, idx) => {
        table.addPlayer(idx, p.userId, false);
        onMatched(tableId, idx);
      });
      return;
    }

    // Schedule bot fill after 8 seconds (PRD 7.1)
    setTimeout(() => {
      const currentQueue = this.queues.get(queueKey) ?? [];
      const idx = currentQueue.findIndex((p) => p.userId === userId);
      if (idx !== -1) {
        // Remove waiting player and fill remaining seats with bots
        currentQueue.splice(idx, 1);
        const tableId = `tbl_${Date.now()}_botfill`;
        const table = this.tableService.createTable(tableId, tier, BigInt(100), broadcaster);

        table.addPlayer(0, userId, false);
        onMatched(tableId, 0);

        // Fill seats 1, 2, 3 with bots
        for (let b = 1; b < 4; b++) {
          table.addPlayer(b, `bot_${b}`, true);
        }
      }
    }, 8000);
  }

  leaveQueue(userId: string, gameId: string, tier: string): void {
    const queueKey = `${gameId}:${tier}`;
    const queue = this.queues.get(queueKey) ?? [];
    const idx = queue.findIndex((p) => p.userId === userId);
    if (idx !== -1) {
      queue.splice(idx, 1);
      this.walletService.releaseHold(userId, BigInt(100), 'queue_cancel').catch(() => {});
    }
  }
}
