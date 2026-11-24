import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { prisma } from '@patii/db';
import { GameId } from '@patii/protocol';

export type PresenceStatus = 'online' | 'in_room' | 'in_table' | 'offline';

export interface UserPresence {
  readonly status: PresenceStatus;
  readonly gameId?: GameId | null;
  readonly updatedAt: number;
}

export interface FriendSummary {
  readonly userId: string;
  readonly displayName: string;
  readonly friendCode: string;
  readonly avatarId: number;
  readonly avatarUrl?: string | null;
  readonly level: number;
  readonly rating: number;
  readonly presence: UserPresence;
}

export interface FriendEventNotification {
  readonly targetUserId: string;
  readonly type: 'request_received' | 'request_accepted' | 'request_declined' | 'friend_removed';
  readonly fromUser: {
    readonly userId: string;
    readonly displayName: string;
    readonly avatarUrl?: string | null;
    readonly friendCode?: string | null;
  };
}

export type FriendEventListener = (event: FriendEventNotification) => void;
export type PresenceEventListener = (userId: string, presence: UserPresence) => void;

@Injectable()
export class SocialService {
  private readonly presenceStore = new Map<string, UserPresence>();
  private readonly friendEventListeners = new Set<FriendEventListener>();
  private readonly presenceListeners = new Set<PresenceEventListener>();

  public onFriendEvent(listener: FriendEventListener): () => void {
    this.friendEventListeners.add(listener);
    return () => this.friendEventListeners.delete(listener);
  }

  public onPresenceChange(listener: PresenceEventListener): () => void {
    this.presenceListeners.add(listener);
    return () => this.presenceListeners.delete(listener);
  }

  private emitFriendEvent(event: FriendEventNotification): void {
    for (const listener of this.friendEventListeners) {
      try {
        listener(event);
      } catch {}
    }
  }

  public setPresence(userId: string, status: PresenceStatus, gameId?: GameId | null): UserPresence {
    const presence: UserPresence = {
      status,
      gameId: gameId ?? null,
      updatedAt: Date.now(),
    };
    this.presenceStore.set(userId, presence);
    for (const listener of this.presenceListeners) {
      try {
        listener(userId, presence);
      } catch {}
    }
    return presence;
  }

  public getPresence(userId: string): UserPresence {
    return this.presenceStore.get(userId) ?? {
      status: 'offline',
      gameId: null,
      updatedAt: Date.now(),
    };
  }

  public async getFriends(userId: string) {
    const friendships = await prisma.friendship.findMany({
      where: {
        OR: [{ userId }, { friendId: userId }],
      },
    });

    const acceptedOtherIds: string[] = [];
    const incomingPendingIds: string[] = [];
    const outgoingPendingIds: string[] = [];

    for (const f of friendships) {
      if (f.status === 'accepted') {
        acceptedOtherIds.push(f.userId === userId ? f.friendId : f.userId);
      } else if (f.status === 'pending') {
        if (f.userId === userId) {
          outgoingPendingIds.push(f.friendId);
        } else {
          incomingPendingIds.push(f.userId);
        }
      }
    }

    const allUserIds = Array.from(new Set([...acceptedOtherIds, ...incomingPendingIds, ...outgoingPendingIds]));
    const users = await prisma.user.findMany({
      where: { id: { in: allUserIds } },
      select: {
        id: true,
        displayName: true,
        friendCode: true,
        avatarId: true,
        avatarUrl: true,
        level: true,
        rating: true,
      },
    });

    const userMap = new Map(users.map((u) => [u.id, u]));

    const friends: FriendSummary[] = acceptedOtherIds
      .map((id) => userMap.get(id))
      .filter((u): u is NonNullable<typeof u> => Boolean(u))
      .map((u) => ({
        userId: u.id,
        displayName: u.displayName,
        friendCode: u.friendCode || '',
        avatarId: u.avatarId,
        avatarUrl: u.avatarUrl,
        level: u.level,
        rating: u.rating,
        presence: this.getPresence(u.id),
      }));

    const incomingRequests: FriendSummary[] = incomingPendingIds
      .map((id) => userMap.get(id))
      .filter((u): u is NonNullable<typeof u> => Boolean(u))
      .map((u) => ({
        userId: u.id,
        displayName: u.displayName,
        friendCode: u.friendCode || '',
        avatarId: u.avatarId,
        avatarUrl: u.avatarUrl,
        level: u.level,
        rating: u.rating,
        presence: this.getPresence(u.id),
      }));

    const outgoingRequests: FriendSummary[] = outgoingPendingIds
      .map((id) => userMap.get(id))
      .filter((u): u is NonNullable<typeof u> => Boolean(u))
      .map((u) => ({
        userId: u.id,
        displayName: u.displayName,
        friendCode: u.friendCode || '',
        avatarId: u.avatarId,
        avatarUrl: u.avatarUrl,
        level: u.level,
        rating: u.rating,
        presence: this.getPresence(u.id),
      }));

    return {
      friends,
      incomingRequests,
      outgoingRequests,
    };
  }

  public async sendFriendRequest(userId: string, targetCodeOrId: string) {
    const targetUser = await prisma.user.findFirst({
      where: {
        OR: [
          { friendCode: { equals: targetCodeOrId, mode: 'insensitive' } },
          { id: targetCodeOrId },
        ],
      },
    });

    if (!targetUser) {
      throw new NotFoundException(`User with code/id '${targetCodeOrId}' not found.`);
    }

    if (targetUser.id === userId) {
      throw new BadRequestException('You cannot add yourself as a friend.');
    }

    const existing = await prisma.friendship.findFirst({
      where: {
        OR: [
          { userId, friendId: targetUser.id },
          { userId: targetUser.id, friendId: userId },
        ],
      },
    });

    if (existing) {
      if (existing.status === 'accepted') {
        throw new BadRequestException('Already friends.');
      }
      return { success: true, status: existing.status, targetUser };
    }

    const created = await prisma.friendship.create({
      data: {
        userId,
        friendId: targetUser.id,
        status: 'pending',
      },
    });

    const sender = await prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, displayName: true, avatarUrl: true, friendCode: true },
    });

    if (sender) {
      this.emitFriendEvent({
        targetUserId: targetUser.id,
        type: 'request_received',
        fromUser: {
          userId: sender.id,
          displayName: sender.displayName,
          avatarUrl: sender.avatarUrl,
          friendCode: sender.friendCode,
        },
      });
    }

    return {
      success: true,
      status: created.status,
      targetUser: {
        userId: targetUser.id,
        displayName: targetUser.displayName,
        friendCode: targetUser.friendCode,
        avatarUrl: targetUser.avatarUrl,
      },
    };
  }

  public async connectByInviteLink(userId: string, friendCode: string) {
    const inviter = await prisma.user.findFirst({
      where: {
        friendCode: { equals: friendCode.trim().toUpperCase() },
      },
    });

    if (!inviter) {
      throw new NotFoundException(`Invalid friend invite code '${friendCode}'.`);
    }

    if (inviter.id === userId) {
      throw new BadRequestException('You cannot use your own invite link.');
    }

    const existing = await prisma.friendship.findFirst({
      where: {
        OR: [
          { userId, friendId: inviter.id },
          { userId: inviter.id, friendId: userId },
        ],
      },
    });

    if (existing) {
      if (existing.status !== 'accepted') {
        await prisma.friendship.update({
          where: { userId_friendId: { userId: existing.userId, friendId: existing.friendId } },
          data: { status: 'accepted' },
        });
      }
    } else {
      await prisma.friendship.create({
        data: {
          userId: inviter.id,
          friendId: userId,
          status: 'accepted',
        },
      });
    }

    return {
      success: true,
      friend: {
        userId: inviter.id,
        displayName: inviter.displayName,
        friendCode: inviter.friendCode,
        avatarUrl: inviter.avatarUrl,
        presence: this.getPresence(inviter.id),
      },
    };
  }

  public async respondFriendRequest(userId: string, requesterUserId: string, action: 'accept' | 'decline') {
    const existing = await prisma.friendship.findFirst({
      where: {
        userId: requesterUserId,
        friendId: userId,
      },
    });

    if (!existing) {
      throw new NotFoundException('Friend request not found.');
    }

    const responder = await prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, displayName: true, avatarUrl: true, friendCode: true },
    });

    if (action === 'accept') {
      await prisma.friendship.update({
        where: { userId_friendId: { userId: requesterUserId, friendId: userId } },
        data: { status: 'accepted' },
      });
      if (responder) {
        this.emitFriendEvent({
          targetUserId: requesterUserId,
          type: 'request_accepted',
          fromUser: {
            userId: responder.id,
            displayName: responder.displayName,
            avatarUrl: responder.avatarUrl,
            friendCode: responder.friendCode,
          },
        });
      }
      return { success: true, status: 'accepted' };
    } else {
      await prisma.friendship.delete({
        where: { userId_friendId: { userId: requesterUserId, friendId: userId } },
      });
      if (responder) {
        this.emitFriendEvent({
          targetUserId: requesterUserId,
          type: 'request_declined',
          fromUser: {
            userId: responder.id,
            displayName: responder.displayName,
            avatarUrl: responder.avatarUrl,
            friendCode: responder.friendCode,
          },
        });
      }
      return { success: true, status: 'declined' };
    }
  }

  public async removeFriend(userId: string, targetUserId: string) {
    await prisma.friendship.deleteMany({
      where: {
        OR: [
          { userId, friendId: targetUserId },
          { userId: targetUserId, friendId: userId },
        ],
      },
    });
    const remover = await prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, displayName: true, avatarUrl: true, friendCode: true },
    });
    if (remover) {
      this.emitFriendEvent({
        targetUserId,
        type: 'friend_removed',
        fromUser: {
          userId: remover.id,
          displayName: remover.displayName,
          avatarUrl: remover.avatarUrl,
          friendCode: remover.friendCode,
        },
      });
    }
    return { success: true };
  }
}
