import { Module } from '@nestjs/common';
import { AuthModule } from './modules/auth/auth.module.js';
import { WalletModule } from './modules/wallet/wallet.module.js';
import { TableModule } from './modules/table/table.module.js';
import { MatchmakingModule } from './modules/matchmaking/matchmaking.module.js';
import { RoomsModule } from './modules/rooms/rooms.module.js';
import { EconomyModule } from './modules/economy/economy.module.js';
import { AdminModule } from './modules/admin/admin.module.js';
import { SocialModule } from './modules/social/social.module.js';
import { InvitesModule } from './modules/invites/invites.module.js';
import { HealthModule } from './modules/health/health.module.js';
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
    SocialModule,
    InvitesModule,
    HealthModule,
  ],
  controllers: [],
  providers: [GameGateway],
})
export class AppModule {}
