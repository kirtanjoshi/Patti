import { Module } from '@nestjs/common';
import { InviteRedirectController } from './invite-redirect.controller.js';

@Module({
  controllers: [InviteRedirectController],
})
export class InvitesModule {}
