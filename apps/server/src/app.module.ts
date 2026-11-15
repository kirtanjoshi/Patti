import { Module } from '@nestjs/common';
import { AuthModule } from './modules/auth/auth.module.js';
import { WalletModule } from './modules/wallet/wallet.module.js';
import { TableModule } from './modules/table/table.module.js';
import { MatchmakingModule } from './modules/matchmaking/matchmaking.module.js';
import { RoomsModule } from './modules/rooms/rooms.module.js';
import { EconomyModule } from './modules/economy/economy.module.js';
import { AdminModule } from './modules/admin/admin.module.js';
import { GameGateway } from './gateways/game.gateway.js';

@Module({
  imports: [
    AuthModule,
    WalletModule,
    TableModule,
    MatchmakingModule,
    RoomsModule,
    EconomyModule,
    AdminModule,
  ],
  controllers: [],
  providers: [GameGateway],
})
export class AppModule {}
