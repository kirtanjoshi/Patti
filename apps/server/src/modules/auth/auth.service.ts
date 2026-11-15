import { Injectable, UnauthorizedException } from '@nestjs/common';
import { prisma, AuthProvider, UserStatus, WalletAccountType, TxKind } from '@patii/db';
import { createHash, randomBytes } from 'node:crypto';

export interface AuthTokens {
  readonly accessToken: string;
  readonly refreshToken: string;
  readonly userId: string;
  readonly displayName: string;
  readonly isGuest: boolean;
}

@Injectable()
export class AuthService {
  private readonly jwtSecret = process.env.JWT_SECRET || 'patii-default-jwt-secret-key-32-chars';

  /**
   * Simple signed JWT token generator for authenticated players
   */
  public generateTokens(userId: string, displayName: string, isGuest: boolean): AuthTokens {
    const header = Buffer.from(JSON.stringify({ alg: 'HS256', typ: 'JWT' })).toString('base64url');
    const now = Math.floor(Date.now() / 1000);
    const payload = Buffer.from(
      JSON.stringify({
        sub: userId,
        name: displayName,
        isGuest,
        iat: now,
        exp: now + 15 * 60, // 15 mins
      }),
    ).toString('base64url');

    const signature = createHash('sha256')
      .update(`${header}.${payload}.${this.jwtSecret}`)
      .digest('base64url');

    const accessToken = `${header}.${payload}.${signature}`;
    const refreshToken = randomBytes(32).toString('hex');

    return {
      accessToken,
      refreshToken,
      userId,
      displayName,
      isGuest,
    };
  }

  public verifyAccessToken(token: string): { userId: string; name: string; isGuest: boolean } {
    try {
      const parts = token.split('.');
      if (parts.length !== 3) {
        throw new UnauthorizedException('Malformed token');
      }
      const [header, payload, signature] = parts;
      const expectedSig = createHash('sha256')
        .update(`${header}.${payload}.${this.jwtSecret}`)
        .digest('base64url');

      if (signature !== expectedSig) {
        throw new UnauthorizedException('Invalid token signature');
      }

      const decoded = JSON.parse(Buffer.from(payload!, 'base64url').toString('utf8'));
      if (decoded.exp && decoded.exp < Math.floor(Date.now() / 1000)) {
        throw new UnauthorizedException('Token expired');
      }

      return {
        userId: decoded.sub,
        name: decoded.name,
        isGuest: Boolean(decoded.isGuest),
      };
    } catch {
      throw new UnauthorizedException('Token validation failed');
    }
  }

  /**
   * Guest login: creates or retrieves a device-bound guest account.
   * If new user, grants signup bonus (10,000 coins) via WalletTx.
   */
  public async loginGuest(deviceId: string, displayName = 'Guest Player'): Promise<AuthTokens> {
    const existingIdentity = await prisma.authIdentity.findUnique({
      where: {
        provider_providerId: {
          provider: AuthProvider.GUEST,
          providerId: deviceId,
        },
      },
      include: { user: true },
    });

    if (existingIdentity && existingIdentity.user) {
      return this.generateTokens(
        existingIdentity.user.id,
        existingIdentity.user.displayName,
        true,
      );
    }

    // Create new guest user and wallet in a transaction
    const newUser = await prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          displayName,
          status: UserStatus.ACTIVE,
          language: 'en',
          level: 1,
          rating: 1200,
        },
      });

      await tx.authIdentity.create({
        data: {
          userId: user.id,
          provider: AuthProvider.GUEST,
          providerId: deviceId,
        },
      });

      // User wallet account with 10,000 signup bonus
      const wallet = await tx.walletAccount.create({
        data: {
          userId: user.id,
          type: WalletAccountType.USER,
          balance: BigInt(10000),
          held: BigInt(0),
        },
      });

      // Record signup double-entry transaction
      await tx.walletTx.create({
        data: {
          kind: TxKind.SIGNUP,
          debitAccount: 'HOUSE_REWARDS',
          creditAccount: wallet.id,
          amount: BigInt(10000),
          idempotencyKey: `signup:${user.id}`,
        },
      });

      return user;
    });

    return this.generateTokens(newUser.id, newUser.displayName, true);
  }
}
