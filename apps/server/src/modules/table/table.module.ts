import { Module } from '@nestjs/common';
import { TableService } from './table.service.js';
import { WalletModule } from '../wallet/wallet.module.js';

@Module({
  imports: [WalletModule],
  providers: [TableService],
  exports: [TableService],
})
export class TableModule {}
