import { BadRequestException, Injectable } from '@nestjs/common';
import { prisma, TxKind, WalletAccountType } from '@patii/db';

export interface MatchPlacementResult {
  readonly userId: string | null; // null for bots
  readonly isBot: boolean;
  readonly placement: number; // 1, 2, 3, 4
  readonly entryFee: bigint;
}

@Injectable()
export class WalletService {
  /**
   * Reserves table stake entry coins (hold)
   */
  async holdStake(userId: string, amount: bigint, tableId: string): Promise<void> {
    await prisma.$transaction(async (tx) => {
      const wallet = await tx.walletAccount.findUnique({
        where: { userId },
      });

      if (!wallet) {
        throw new BadRequestException(`Wallet not found for user: ${userId}`);
      }

      const available = wallet.balance - wallet.held;
      if (available < amount) {
        throw new BadRequestException('Insufficient coins to join table.');
      }

      await tx.walletAccount.update({
        where: { id: wallet.id },
        data: {
          held: wallet.held + amount,
        },
      });

      await tx.walletTx.create({
        data: {
          kind: TxKind.HOLD,
          debitAccount: wallet.id,
          creditAccount: 'HOUSE_HOLD',
          amount,
          idempotencyKey: `hold:${tableId}:${userId}`,
        },
      });
    });
  }

  /**
   * Releases reserved hold if matchmaking was cancelled or table was abandoned
   */
  async releaseHold(userId: string, amount: bigint, tableId: string): Promise<void> {
    await prisma.$transaction(async (tx) => {
      const wallet = await tx.walletAccount.findUnique({
        where: { userId },
      });
      if (!wallet) return;

      const newHeld = wallet.held >= amount ? wallet.held - amount : BigInt(0);
      await tx.walletAccount.update({
        where: { id: wallet.id },
        data: { held: newHeld },
      });

      await tx.walletTx.create({
        data: {
          kind: TxKind.RELEASE,
          debitAccount: 'HOUSE_HOLD',
          creditAccount: wallet.id,
          amount,
          idempotencyKey: `release:${tableId}:${userId}`,
        },
      });
    });
  }

  /**
   * PRD 8.5 & 5.1:
   * Settles match in one atomic DB transaction with idempotency keys.
   * Rake: 5% of total pot -> HOUSE_RAKE.
   * Remainder distributed to winners (1st 50%, 2nd 30%, 3rd 20%).
   */
  async settleMatch(
    matchId: string,
    players: readonly MatchPlacementResult[],
    rakePercent = 5,
  ): Promise<Record<string, bigint>> {
    const payouts: Record<string, bigint> = {};

    await prisma.$transaction(async (tx) => {
      // Release holds first
      for (const p of players) {
        if (p.userId && !p.isBot) {
          const w = await tx.walletAccount.findUnique({ where: { userId: p.userId } });
          if (w) {
            await tx.walletAccount.update({
              where: { id: w.id },
              data: { held: w.held >= p.entryFee ? w.held - p.entryFee : BigInt(0) },
            });
          }
        }
      }

      const totalPot = players.reduce((sum, p) => sum + p.entryFee, BigInt(0));
      const rakeAmount = (totalPot * BigInt(rakePercent)) / BigInt(100);
      const distributablePot = totalPot - rakeAmount;

      // Transfer rake to HOUSE_RAKE
      const houseRake = await tx.walletAccount.findFirst({
        where: { type: WalletAccountType.HOUSE_RAKE },
      });
      if (houseRake) {
        await tx.walletAccount.update({
          where: { id: houseRake.id },
          data: { balance: houseRake.balance + rakeAmount },
        });

        await tx.walletTx.create({
          data: {
            kind: TxKind.RAKE,
            debitAccount: 'TABLE_POT',
            creditAccount: houseRake.id,
            amount: rakeAmount,
            matchId,
            idempotencyKey: `rake:${matchId}`,
          },
        });
      }

      // Payouts for Callbreak: 1st 50%, 2nd 30%, 3rd 20%, 4th 0
      const payoutShares: Record<number, number> = { 1: 50, 2: 30, 3: 20 };

      for (const p of players) {
        const share = payoutShares[p.placement] ?? 0;
        const winAmount = (distributablePot * BigInt(share)) / BigInt(100);
        const netDelta = winAmount - p.entryFee;
        const targetId = p.userId ?? `bot_${p.placement}`;
        payouts[targetId] = netDelta;

        if (p.isBot) {
          // Bot wins/losses go to HOUSE_BOT account
          const houseBot = await tx.walletAccount.findFirst({
            where: { type: WalletAccountType.HOUSE_BOT },
          });
          if (houseBot) {
            await tx.walletAccount.update({
              where: { id: houseBot.id },
              data: { balance: houseBot.balance + netDelta },
            });
          }
        } else if (p.userId) {
          // Player settlement
          const wallet = await tx.walletAccount.findUnique({ where: { userId: p.userId } });
          if (wallet) {
            await tx.walletAccount.update({
              where: { id: wallet.id },
              data: { balance: wallet.balance + netDelta },
            });

            await tx.walletTx.create({
              data: {
                kind: TxKind.SETTLE,
                debitAccount: netDelta < 0 ? wallet.id : 'TABLE_POT',
                creditAccount: netDelta >= 0 ? wallet.id : 'TABLE_POT',
                amount: netDelta >= 0 ? netDelta : -netDelta,
                matchId,
                idempotencyKey: `settle:${matchId}:${p.userId}`,
              },
            });
          }
        }
      }
    });

    return payouts;
  }
}
