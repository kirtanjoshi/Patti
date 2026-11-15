import { Module } from '@nestjs/common';
import { RoomsService } from './rooms.service.js';
import { TableModule } from '../table/table.module.js';

@Module({
  imports: [TableModule],
  providers: [RoomsService],
  exports: [RoomsService],
})
export class RoomsModule {}
