import {
  Body,
  Controller,
  Delete,
  Get,
  Headers,
  Param,
  Post,
  Query,
  Req,
  UnauthorizedException,
} from '@nestjs/common';
import type { Request } from 'express';
import { SocialService } from './social.service.js';
import { NearbyService } from './nearby.service.js';
import { AuthService } from '../auth/auth.service.js';

class FriendRequestDto {
  targetCodeOrId!: string;
}

class ConnectLinkDto {
  friendCode!: string;
}

class RespondRequestDto {
  requesterUserId!: string;
  action!: 'accept' | 'decline';
}

class UpdateNearbyLocationDto {
  latitude!: number;
  longitude!: number;
  isVisible?: boolean;
  localIp?: string;
  localSubnet?: string;
}

class ToggleNearbyVisibilityDto {
  isVisible!: boolean;
}

@Controller('social')
export class SocialController {
  constructor(
    private readonly socialService: SocialService,
    private readonly nearbyService: NearbyService,
    private readonly authService: AuthService,
  ) {}

  private extractUserId(authHeader?: string): string {
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedException('Authorization header required');
    }
    const token = authHeader.substring(7);
    const verified = this.authService.verifyAccessToken(token);
    return verified.userId;
  }

  @Get('friends')
  async getFriends(@Headers('authorization') authHeader?: string) {
    const userId = this.extractUserId(authHeader);
    return this.socialService.getFriends(userId);
  }

  @Post('friends/request')
  async sendFriendRequest(
    @Headers('authorization') authHeader: string | undefined,
    @Body() body: FriendRequestDto,
  ) {
    const userId = this.extractUserId(authHeader);
    return this.socialService.sendFriendRequest(userId, body.targetCodeOrId);
  }

  @Post('friends/connect-link')
  async connectByInviteLink(
    @Headers('authorization') authHeader: string | undefined,
    @Body() body: ConnectLinkDto,
  ) {
    const userId = this.extractUserId(authHeader);
    return this.socialService.connectByInviteLink(userId, body.friendCode);
  }

  @Post('friends/respond')
  async respondFriendRequest(
    @Headers('authorization') authHeader: string | undefined,
    @Body() body: RespondRequestDto,
  ) {
    const userId = this.extractUserId(authHeader);
    return this.socialService.respondFriendRequest(userId, body.requesterUserId, body.action);
  }

  @Delete('friends/:friendId')
  async removeFriend(
    @Headers('authorization') authHeader: string | undefined,
    @Param('friendId') friendId: string,
  ) {
    const userId = this.extractUserId(authHeader);
    return this.socialService.removeFriend(userId, friendId);
  }

  // --- Location-Based Nearby Players ---

  @Post('nearby/location')
  async updateNearbyLocation(
    @Req() req: Request,
    @Headers('authorization') authHeader: string | undefined,
    @Body() body: UpdateNearbyLocationDto,
  ) {
    const userId = this.extractUserId(authHeader);
    const rawIp =
      req.headers['x-forwarded-for']?.toString().split(',')[0]?.trim() || req.socket.remoteAddress || '';
    const clientIp = NearbyService.normalizeIp(rawIp);
    const localSubnet = body.localSubnet || NearbyService.extractSubnet(body.localIp);
    this.nearbyService.updateLocation(
      userId,
      body.latitude,
      body.longitude,
      body.isVisible ?? true,
      clientIp,
      localSubnet,
    );
    return { success: true };
  }

  @Get('nearby')
  async getNearbyPlayers(
    @Req() req: Request,
    @Headers('authorization') authHeader: string | undefined,
    @Query('lat') lat?: string,
    @Query('lon') lon?: string,
    @Query('radiusKm') radiusKm?: string,
    @Query('localIp') localIp?: string,
    @Query('localSubnet') localSubnet?: string,
  ) {
    const userId = this.extractUserId(authHeader);
    const parsedLat = lat ? parseFloat(lat) : undefined;
    const parsedLon = lon ? parseFloat(lon) : undefined;
    const parsedRadius = radiusKm ? Math.min(50, Math.max(0.5, parseFloat(radiusKm))) : 10;
    const rawIp =
      req.headers['x-forwarded-for']?.toString().split(',')[0]?.trim() || req.socket.remoteAddress || '';
    const clientIp = NearbyService.normalizeIp(rawIp);
    const resolvedSubnet = localSubnet || NearbyService.extractSubnet(localIp);

    return this.nearbyService.getNearbyPlayers(
      userId,
      parsedLat,
      parsedLon,
      parsedRadius,
      clientIp,
      resolvedSubnet,
    );
  }

  @Post('nearby/visibility')
  async setNearbyVisibility(
    @Headers('authorization') authHeader: string | undefined,
    @Body() body: ToggleNearbyVisibilityDto,
  ) {
    const userId = this.extractUserId(authHeader);
    this.nearbyService.setVisibility(userId, body.isVisible);
    return { success: true, isVisible: body.isVisible };
  }
}
