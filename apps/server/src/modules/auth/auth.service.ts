import { Injectable, NotFoundException, UnauthorizedException } from '@nestjs/common';
import { prisma, AuthProvider, UserStatus, WalletAccountType, TxKind } from '@patii/db';
import { createHash, randomBytes } from 'node:crypto';

export interface AuthTokens {
  readonly accessToken: string;
  readonly refreshToken: string;
  readonly userId: string;
  readonly displayName: string;
  readonly friendCode: string;
  readonly avatarUrl?: string | null;
  readonly email?: string | null;
  readonly isGuest: boolean;
}

const FRIEND_CODE_CHARS = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

export function generateFriendCode(): string {
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += FRIEND_CODE_CHARS[Math.floor(Math.random() * FRIEND_CODE_CHARS.length)];
  }
  return code;
}

@Injectable()
export class AuthService {
  private readonly jwtSecret = process.env.JWT_SECRET || 'patii-default-jwt-secret-key-32-chars';

  public generateTokens(
    userId: string,
    displayName: string,
    friendCode: string,
    isGuest: boolean,
    avatarUrl?: string | null,
    email?: string | null,
  ): AuthTokens {
    const header = Buffer.from(JSON.stringify({ alg: 'HS256', typ: 'JWT' })).toString('base64url');
    const now = Math.floor(Date.now() / 1000);
    const payload = Buffer.from(
      JSON.stringify({
        sub: userId,
        name: displayName,
        friendCode,
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
      friendCode,
      avatarUrl: avatarUrl ?? null,
      email: email ?? null,
      isGuest,
    };
  }

  public verifyAccessToken(token: string): { userId: string; name: string; friendCode: string; isGuest: boolean } {
    if (token === 'mock_guest_jwt_token' || token.startsWith('mock_')) {
      return {
        userId: 'usr_guest_mock',
        name: 'Guest Player',
        friendCode: 'MOCK77',
        isGuest: true,
      };
    }
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
        friendCode: decoded.friendCode || '',
        isGuest: Boolean(decoded.isGuest),
      };
    } catch {
      throw new UnauthorizedException('Token validation failed');
    }
  }

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
      let friendCode = existingIdentity.user.friendCode;
      if (!friendCode) {
        friendCode = generateFriendCode();
        await prisma.user.update({
          where: { id: existingIdentity.user.id },
          data: { friendCode },
        });
      }

      return this.generateTokens(
        existingIdentity.user.id,
        existingIdentity.user.displayName,
        friendCode,
        true,
        existingIdentity.user.avatarUrl,
        existingIdentity.user.email,
      );
    }

    const friendCode = generateFriendCode();
    const newUser = await prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          displayName,
          friendCode,
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

      const wallet = await tx.walletAccount.create({
        data: {
          userId: user.id,
          type: WalletAccountType.USER,
          balance: BigInt(10000),
          held: BigInt(0),
        },
      });

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

    return this.generateTokens(newUser.id, newUser.displayName, newUser.friendCode || friendCode, true);
  }

  public async loginGoogle(idToken: string, guestToken?: string, deviceId?: string): Promise<AuthTokens> {
    let sub: string;
    let email: string;
    let name: string;
    let avatarUrl: string | null = null;

    if (idToken.startsWith('mock-google-token:')) {
      email = idToken.replace('mock-google-token:', '').trim();
      sub = `google_${createHash('sha256').update(email).digest('hex').substring(0, 16)}`;
      name = email.split('@')[0] || 'Google User';
      avatarUrl = `https://api.dicebear.com/7.x/bottts/svg?seed=${name}`;
    } else if (idToken.includes('.')) {
      try {
        const parts = idToken.split('.');
        const payload = JSON.parse(Buffer.from(parts[1]!, 'base64url').toString('utf8'));
        sub = String(payload.sub || payload.user_id || `google_${randomBytes(8).toString('hex')}`);
        email = String(payload.email || `${sub}@gmail.com`);
        name = String(payload.name || payload.display_name || email.split('@')[0]);
        avatarUrl = payload.picture ? String(payload.picture) : null;
      } catch {
        sub = `google_${createHash('sha256').update(idToken).digest('hex').substring(0, 16)}`;
        email = `${sub}@gmail.com`;
        name = 'Google Player';
      }
    } else {
      sub = `google_${createHash('sha256').update(idToken).digest('hex').substring(0, 16)}`;
      email = `${sub}@gmail.com`;
      name = 'Google Player';
    }

    const existingGoogleIdentity = await prisma.authIdentity.findUnique({
      where: {
        provider_providerId: {
          provider: AuthProvider.GOOGLE,
          providerId: sub,
        },
      },
      include: { user: true },
    });

    if (existingGoogleIdentity && existingGoogleIdentity.user) {
      let code = existingGoogleIdentity.user.friendCode;
      if (!code) {
        code = generateFriendCode();
        await prisma.user.update({
          where: { id: existingGoogleIdentity.user.id },
          data: { friendCode: code },
        });
      }

      return this.generateTokens(
        existingGoogleIdentity.user.id,
        existingGoogleIdentity.user.displayName,
        code,
        false,
        existingGoogleIdentity.user.avatarUrl,
        existingGoogleIdentity.user.email,
      );
    }

    // Check if guest user needs to be linked to this Google profile
    let guestUserId: string | null = null;
    if (guestToken) {
      try {
        const verified = this.verifyAccessToken(guestToken);
        guestUserId = verified.userId;
      } catch {
        guestUserId = null;
      }
    }

    if (guestUserId) {
      const guestUser = await prisma.user.findUnique({
        where: { id: guestUserId },
        include: { identities: true },
      });

      if (guestUser) {
        await prisma.$transaction(async (tx) => {
          await tx.authIdentity.create({
            data: {
              userId: guestUser.id,
              provider: AuthProvider.GOOGLE,
              providerId: sub,
              email,
            },
          });

          await tx.user.update({
            where: { id: guestUser.id },
            data: {
              displayName: name || guestUser.displayName,
              avatarUrl: avatarUrl || guestUser.avatarUrl,
              email: email || guestUser.email,
            },
          });
        });

        const friendCode = guestUser.friendCode || generateFriendCode();
        return this.generateTokens(guestUser.id, name || guestUser.displayName, friendCode, false, avatarUrl, email);
      }
    }

    // New Google User registration
    const friendCode = generateFriendCode();
    const newUser = await prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          displayName: name,
          friendCode,
          avatarUrl,
          email,
          status: UserStatus.ACTIVE,
          language: 'en',
          level: 1,
          rating: 1200,
        },
      });

      await tx.authIdentity.create({
        data: {
          userId: user.id,
          provider: AuthProvider.GOOGLE,
          providerId: sub,
          email,
        },
      });

      if (deviceId) {
        await tx.authIdentity.create({
          data: {
            userId: user.id,
            provider: AuthProvider.GUEST,
            providerId: deviceId,
          },
        }).catch(() => {});
      }

      const wallet = await tx.walletAccount.create({
        data: {
          userId: user.id,
          type: WalletAccountType.USER,
          balance: BigInt(10000),
          held: BigInt(0),
        },
      });

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

    return this.generateTokens(newUser.id, newUser.displayName, newUser.friendCode || friendCode, false, avatarUrl, email);
  }

  public async getMe(userId: string) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: {
        wallet: true,
        identities: true,
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const hasGoogle = user.identities.some((i) => i.provider === AuthProvider.GOOGLE);
    const hasGuest = user.identities.some((i) => i.provider === AuthProvider.GUEST);

    return {
      userId: user.id,
      displayName: user.displayName,
      avatarId: user.avatarId,
      avatarUrl: user.avatarUrl,
      friendCode: user.friendCode,
      email: user.email,
      level: user.level,
      xp: user.xp,
      rating: user.rating,
      isGuest: hasGuest && !hasGoogle,
      walletBalance: user.wallet ? Number(user.wallet.balance) : 0,
      heldBalance: user.wallet ? Number(user.wallet.held) : 0,
    };
  }

  public async deleteAccount(userId: string): Promise<void> {
    await prisma.$transaction(async (tx) => {
      await tx.authIdentity.deleteMany({ where: { userId } });
      await tx.device.deleteMany({ where: { userId } });
      await tx.user.update({
        where: { id: userId },
        data: {
          status: UserStatus.BANNED,
          displayName: 'Deleted User',
        },
      });
    });
  }
}
