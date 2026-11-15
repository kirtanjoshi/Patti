import { Injectable, NotFoundException } from '@nestjs/common';
import { TableRuntime, TableConfig, TableEventBroadcaster } from './table-runtime.js';
import { CallbreakMove, DEFAULT_CALLBREAK_RULES } from '@patii/game-engine';
import { WalletService } from '../wallet/wallet.service.js';

@Injectable()
export class TableService {
  private readonly activeTables = new Map<string, TableRuntime>();

  constructor(private readonly walletService: WalletService) {}

  createTable(
    tableId: string,
    tier = 'beginner',
    stake = BigInt(100),
    broadcaster: TableEventBroadcaster,
  ): TableRuntime {
    const config: TableConfig = {
      tableId,
      gameId: 'callbreak',
      tier,
      stake,
      rules: DEFAULT_CALLBREAK_RULES,
      seatsCount: 4,
    };

    const table = new TableRuntime(config, broadcaster);
    this.activeTables.set(tableId, table);
    return table;
  }

  getTable(tableId: string): TableRuntime {
    const table = this.activeTables.get(tableId);
    if (!table) {
      throw new NotFoundException(`Table ${tableId} not found.`);
    }
    return table;
  }

  applyMove(tableId: string, playerId: string, version: number, move: CallbreakMove): void {
    const table = this.getTable(tableId);
    table.applyPlayerMove(playerId, version, move);
  }

  handleDisconnect(tableId: string, playerId: string): void {
    const table = this.activeTables.get(tableId);
    if (table) {
      table.markDisconnected(playerId);
    }
  }

  handleReconnect(tableId: string, playerId: string): void {
    const table = this.activeTables.get(tableId);
    if (table) {
      table.markReconnected(playerId);
    }
  }
}
