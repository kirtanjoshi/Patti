import { Module } from '@nestjs/common';
import { AuthModule } from './modules/auth/auth.module.js';
import { WalletModule } from './modules/wallet/wallet.module.js';
import { TableModule } from './modules/table/table.module.js';
import { MatchmakingModule } from './modules/matchmaking/matchmaking.module.js';
import { GameGateway } from './gateways/game.gateway.js';

@Module({
  imports: [
    AuthModule,
    WalletModule,
    TableModule,
    MatchmakingModule,
  ],
  controllers: [],
  providers: [GameGateway],
})
export class AppModule {}
