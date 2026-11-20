import { Injectable } from '@nestjs/common';
import { prisma } from '@patii/db';
import { SocialService, UserPresence } from './social.service.js';

export interface NearbyLocationEntry {
  readonly latitude: number;
  readonly longitude: number;
  readonly isVisible: boolean;
  readonly updatedAt: number;
}

export interface NearbyPlayerSummary {
  readonly userId: string;
  readonly displayName: string;
  readonly friendCode: string;
  readonly avatarId: number;
  readonly avatarUrl?: string | null;
  readonly level: number;
  readonly rating: number;
  readonly distanceMeters: number;
  readonly distanceText: string;
  readonly presence: UserPresence;
  readonly isFriend: boolean;
  readonly hasPendingRequest: boolean;
}

const LOCATION_TTL_MS = 15 * 60 * 1000; // 15 minutes TTL for privacy

@Injectable()
export class NearbyService {
  private readonly locationStore = new Map<string, NearbyLocationEntry>();

  constructor(private readonly socialService: SocialService) {}

  /**
   * Calculates Haversine distance in meters between two lat/lon coordinates
   */
  public calculateDistanceMeters(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371e3; // Earth radius in meters
    const phi1 = (lat1 * Math.PI) / 180;
    const phi2 = (lat2 * Math.PI) / 180;
    const deltaPhi = ((lat2 - lat1) * Math.PI) / 180;
    const deltaLambda = ((lon2 - lon1) * Math.PI) / 180;

    const a =
      Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
      Math.cos(phi1) * Math.cos(phi2) * Math.sin(deltaLambda / 2) * Math.sin(deltaLambda / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return Math.round(R * c);
  }

  public formatDistance(meters: number): string {
    if (meters < 1000) {
      const rounded = Math.max(50, Math.round(meters / 50) * 50);
      return `~${rounded}m away`;
    }
    const km = (meters / 1000).toFixed(1);
    return `~${km} km away`;
  }

  public updateLocation(userId: string, latitude: number, longitude: number, isVisible = true): void {
    // Round to 3 decimal places for coarse privacy protection (~110m resolution)
    const coarseLat = Math.round(latitude * 1000) / 1000;
    const coarseLon = Math.round(longitude * 1000) / 1000;

    this.locationStore.set(userId, {
      latitude: coarseLat,
      longitude: coarseLon,
      isVisible,
      updatedAt: Date.now(),
    });
  }

  public setVisibility(userId: string, isVisible: boolean): void {
    const existing = this.locationStore.get(userId);
    if (existing) {
      if (!isVisible) {
        this.locationStore.delete(userId);
      } else {
        this.locationStore.set(userId, {
          ...existing,
          isVisible: true,
          updatedAt: Date.now(),
        });
      }
    }
  }

  public async getNearbyPlayers(
    userId: string,
    latitude?: number,
    longitude?: number,
    radiusKm = 10,
  ): Promise<NearbyPlayerSummary[]> {
    const now = Date.now();
    const myLocation =
      latitude !== undefined && longitude !== undefined
        ? { latitude, longitude }
        : this.locationStore.get(userId);

    if (!myLocation) {
      return [];
    }

    // Keep my location updated if passed
    if (latitude !== undefined && longitude !== undefined) {
      this.updateLocation(userId, latitude, longitude, true);
    }

    const candidateEntries: { otherUserId: string; distance: number }[] = [];
    const maxDistanceMeters = radiusKm * 1000;

    for (const [otherUserId, loc] of this.locationStore.entries()) {
      if (otherUserId === userId) continue;
      if (!loc.isVisible) continue;
      if (now - loc.updatedAt > LOCATION_TTL_MS) continue;

      const dist = this.calculateDistanceMeters(
        myLocation.latitude,
        myLocation.longitude,
        loc.latitude,
        loc.longitude,
      );

      if (dist <= maxDistanceMeters) {
        candidateEntries.push({ otherUserId, distance: dist });
      }
    }

    if (candidateEntries.length === 0) {
      return [];
    }

    // Sort closest first
    candidateEntries.sort((a, b) => a.distance - b.distance);

    const otherUserIds = candidateEntries.map((c) => c.otherUserId);

    // Fetch user details
    const users = await prisma.user.findMany({
      where: { id: { in: otherUserIds } },
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

    // Fetch friendship relations
    const friendships = await prisma.friendship.findMany({
      where: {
        OR: [
          { userId, friendId: { in: otherUserIds } },
          { userId: { in: otherUserIds }, friendId: userId },
        ],
      },
    });

    const friendStatusMap = new Map<string, { isFriend: boolean; hasPendingRequest: boolean }>();
    for (const f of friendships) {
      const otherId = f.userId === userId ? f.friendId : f.userId;
      if (f.status === 'accepted') {
        friendStatusMap.set(otherId, { isFriend: true, hasPendingRequest: false });
      } else if (f.status === 'pending') {
        friendStatusMap.set(otherId, { isFriend: false, hasPendingRequest: true });
      }
    }

    const results: NearbyPlayerSummary[] = [];
    for (const candidate of candidateEntries) {
      const u = userMap.get(candidate.otherUserId);
      const rel = friendStatusMap.get(candidate.otherUserId) ?? { isFriend: false, hasPendingRequest: false };

      results.push({
        userId: candidate.otherUserId,
        displayName: u?.displayName ?? 'Nearby Player',
        friendCode: u?.friendCode || 'PT-NEARBY',
        avatarId: u?.avatarId ?? 1,
        avatarUrl: u?.avatarUrl,
        level: u?.level ?? 1,
        rating: u?.rating ?? 1200,
        distanceMeters: candidate.distance,
        distanceText: this.formatDistance(candidate.distance),
        presence: this.socialService.getPresence(candidate.otherUserId),
        isFriend: rel.isFriend,
        hasPendingRequest: rel.hasPendingRequest,
      });
    }

    return results;
  }
}
