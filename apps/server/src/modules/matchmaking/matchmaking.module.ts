import { Module } from '@nestjs/common';
import { MatchmakingService } from './matchmaking.service.js';
import { WalletModule } from '../wallet/wallet.module.js';
import { TableModule } from '../table/table.module.js';

@Module({
  imports: [WalletModule, TableModule],
  providers: [MatchmakingService],
  exports: [MatchmakingService],
})
export class MatchmakingModule {}
