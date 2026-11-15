import { BadRequestException, Injectable } from '@nestjs/common';
import { prisma, TxKind, WalletAccountType } from '@patii/db';

export const DAILY_STREAK_REWARDS = [500, 750, 1000, 1250, 1500, 2000, 3000];

@Injectable()
export class EconomyService {
  /**
   * Claims daily streak reward (PRD 8.1)
   */
  async claimDailyReward(userId: string): Promise<{ streak: number; amount: number }> {
    const dailyRecord = await prisma.dailyReward.findUnique({ where: { userId } });
    const now = new Date();
    let currentStreak = 1;

    if (dailyRecord) {
      const msSinceLast = now.getTime() - dailyRecord.lastClaimAt.getTime();
      const hoursSinceLast = msSinceLast / (1000 * 60 * 60);

      if (hoursSinceLast < 20) {
        throw new BadRequestException('Daily reward not ready yet.');
      } else if (hoursSinceLast <= 48) {
        currentStreak = (dailyRecord.streak % 7) + 1;
      } else {
        // Streak reset if missed more than 48 hours
        currentStreak = 1;
      }
    }

    const rewardAmount = DAILY_STREAK_REWARDS[currentStreak - 1]!;

    await prisma.$transaction(async (tx) => {
      await tx.dailyReward.upsert({
        where: { userId },
        create: { userId, streak: currentStreak, lastClaimAt: now },
        update: { streak: currentStreak, lastClaimAt: now },
      });

      const wallet = await tx.walletAccount.findUnique({ where: { userId } });
      if (wallet) {
        await tx.walletAccount.update({
          where: { id: wallet.id },
          data: { balance: wallet.balance + BigInt(rewardAmount) },
        });

        await tx.walletTx.create({
          data: {
            kind: TxKind.DAILY,
            debitAccount: 'HOUSE_REWARDS',
            creditAccount: wallet.id,
            amount: BigInt(rewardAmount),
            idempotencyKey: `daily:${userId}:${now.toISOString().split('T')[0]}`,
          },
        });
      }
    });

    return { streak: currentStreak, amount: rewardAmount };
  }

  /**
   * Claims 4-hour free chest (200 coins)
   */
  async claimChest(userId: string): Promise<{ amount: number }> {
    const dailyRecord = await prisma.dailyReward.findUnique({ where: { userId } });
    const now = new Date();

    if (dailyRecord && dailyRecord.chestAt) {
      const hoursSince = (now.getTime() - dailyRecord.chestAt.getTime()) / (1000 * 60 * 60);
      if (hoursSince < 4) {
        throw new BadRequestException('Free chest is on cooldown.');
      }
    }

    const chestAmount = 200;

    await prisma.$transaction(async (tx) => {
      await tx.dailyReward.upsert({
        where: { userId },
        create: { userId, streak: 1, lastClaimAt: now, chestAt: now },
        update: { chestAt: now },
      });

      const wallet = await tx.walletAccount.findUnique({ where: { userId } });
      if (wallet) {
        await tx.walletAccount.update({
          where: { id: wallet.id },
          data: { balance: wallet.balance + BigInt(chestAmount) },
        });

        await tx.walletTx.create({
          data: {
            kind: TxKind.CHEST,
            debitAccount: 'HOUSE_REWARDS',
            creditAccount: wallet.id,
            amount: BigInt(chestAmount),
            idempotencyKey: `chest:${userId}:${Math.floor(now.getTime() / (4 * 3600 * 1000))}`,
          },
        });
      }
    });

    return { amount: chestAmount };
  }

  /**
   * Rescues bankrupt player (top up to 2,000 if balance < 500)
   */
  async claimBankruptRescue(userId: string): Promise<{ topUpAmount: number }> {
    const wallet = await prisma.walletAccount.findUnique({ where: { userId } });
    if (!wallet) throw new BadRequestException('User wallet not found');

    if (wallet.balance >= BigInt(500)) {
      throw new BadRequestException('Balance is not below bankrupt threshold (500 coins).');
    }

    const topUpAmount = Number(BigInt(2000) - wallet.balance);
    const now = new Date();

    await prisma.$transaction(async (tx) => {
      await tx.walletAccount.update({
        where: { id: wallet.id },
        data: { balance: BigInt(2000) },
      });

      await tx.walletTx.create({
        data: {
          kind: TxKind.RESCUE,
          debitAccount: 'HOUSE_REWARDS',
          creditAccount: wallet.id,
          amount: BigInt(topUpAmount),
          idempotencyKey: `rescue:${userId}:${now.toISOString().split('T')[0]}_${Math.floor(now.getHours() / 12)}`,
        },
      });
    });

    return { topUpAmount };
  }

  /**
   * Calculates XP progression and checks for level up (PRD 8.4)
   * Level n requires 100 * n^2 XP
   */
  calculateLevel(totalXp: number): number {
    return Math.max(1, Math.floor(Math.sqrt(totalXp / 100)));
  }
}
