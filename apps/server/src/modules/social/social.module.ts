import { Module } from '@nestjs/common';
import { SocialService } from './social.service.js';
import { NearbyService } from './nearby.service.js';
import { SocialController } from './social.controller.js';
import { AuthModule } from '../auth/auth.module.js';

@Module({
  imports: [AuthModule],
  controllers: [SocialController],
  providers: [SocialService, NearbyService],
  exports: [SocialService, NearbyService],
})
export class SocialModule {}
