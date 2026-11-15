import { Body, Controller, Delete, Headers, Post, UnauthorizedException } from '@nestjs/common';
import { AuthService, AuthTokens } from './auth.service.js';

class GuestLoginDto {
  deviceId!: string;
  displayName?: string;
}

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('guest')
  async guestLogin(@Body() body: GuestLoginDto): Promise<AuthTokens> {
    const deviceId = body.deviceId || `dev_${Math.random().toString(36).substring(2, 10)}`;
    return this.authService.loginGuest(deviceId, body.displayName);
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
