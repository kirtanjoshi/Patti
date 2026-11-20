import { Body, Controller, Delete, Get, Headers, Post, UnauthorizedException } from '@nestjs/common';
import { AuthService, AuthTokens } from './auth.service.js';

class GuestLoginDto {
  deviceId!: string;
  displayName?: string;
}

class GoogleLoginDto {
  idToken!: string;
  guestToken?: string;
  deviceId?: string;
}

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('guest')
  async guestLogin(@Body() body: GuestLoginDto): Promise<AuthTokens> {
    const deviceId = body.deviceId || `dev_${Math.random().toString(36).substring(2, 10)}`;
    return this.authService.loginGuest(deviceId, body.displayName);
  }

  @Post('google')
  async googleLogin(@Body() body: GoogleLoginDto): Promise<AuthTokens> {
    if (!body.idToken) {
      throw new UnauthorizedException('idToken is required');
    }
    return this.authService.loginGoogle(body.idToken, body.guestToken, body.deviceId);
  }

  @Get('me')
  async getMe(@Headers('authorization') authHeader?: string) {
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedException('Authorization header required');
    }
    const token = authHeader.substring(7);
    const verified = this.authService.verifyAccessToken(token);
    return this.authService.getMe(verified.userId);
  }

  @Delete('account')
  async deleteAccount(@Headers('authorization') authHeader?: string): Promise<{ success: boolean }> {
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedException('Authorization header required');
    }
    const token = authHeader.substring(7);
    const verified = this.authService.verifyAccessToken(token);
    await this.authService.deleteAccount(verified.userId);
    return { success: true };
  }
}
