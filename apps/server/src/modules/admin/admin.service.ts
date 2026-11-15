import { BadRequestException, Injectable } from '@nestjs/common';
import { prisma, TxKind, UserStatus } from '@patii/db';

export class AdminAdjustCoinsDto {
  readonly targetUserId!: string;
  readonly amount!: number; // positive or negative
  readonly reason!: string;
}

export class AdminBanUserDto {
  readonly targetUserId!: string;
  readonly durationDays!: number;
  readonly reason!: string;
}

@Injectable()
export class AdminService {
  async adjustCoins(adminId: string, dto: AdminAdjustCoinsDto): Promise<{ newBalance: bigint }> {
    if (!dto.reason || dto.reason.trim().length === 0) {
      throw new BadRequestException('A reason is strictly required for coin adjustments.');
    }

    return await prisma.$transaction(async (tx) => {
      const wallet = await tx.walletAccount.findUnique({
        where: { userId: dto.targetUserId },
      });
      if (!wallet) throw new BadRequestException('Target user wallet not found');

      const delta = BigInt(dto.amount);
      const newBalance = wallet.balance + delta;
      if (newBalance < BigInt(0)) {
        throw new BadRequestException('Resulting balance cannot be negative.');
      }

      await tx.walletAccount.update({
        where: { id: wallet.id },
        data: { balance: newBalance },
      });

      await tx.walletTx.create({
        data: {
          kind: TxKind.ADMIN_ADJUST,
          debitAccount: delta < 0 ? wallet.id : 'HOUSE_REWARDS',
          creditAccount: delta >= 0 ? wallet.id : 'HOUSE_REWARDS',
          amount: delta >= 0 ? delta : -delta,
          idempotencyKey: `admin_adj:${Date.now()}_${Math.random()}`,
          meta: { adminId, reason: dto.reason },
        },
      });

      await tx.auditLog.create({
        data: {
          adminId,
          action: 'ADJUST_COINS',
          target: dto.targetUserId,
          meta: { amount: dto.amount, reason: dto.reason, newBalance: newBalance.toString() },
        },
      });

      return { newBalance };
    });
  }

  async banUser(adminId: string, dto: AdminBanUserDto): Promise<void> {
    await prisma.$transaction(async (tx) => {
      await tx.user.update({
        where: { id: dto.targetUserId },
        data: { status: UserStatus.BANNED },
      });

      await tx.auditLog.create({
        data: {
          adminId,
          action: 'BAN_USER',
          target: dto.targetUserId,
          meta: { durationDays: dto.durationDays, reason: dto.reason },
        },
      });
    });
  }

  async getAuditLogs(limit = 50) {
    return prisma.auditLog.findMany({
      take: limit,
      orderBy: { createdAt: 'desc' },
    });
  }
}
