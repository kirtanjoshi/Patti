import { Body, Controller, Get, Post, Query } from '@nestjs/common';
import { AdminService, AdminAdjustCoinsDto, AdminBanUserDto } from './admin.service.js';

@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Post('coins/adjust')
  async adjustCoins(
    @Body() body: AdminAdjustCoinsDto,
    @Query('adminId') adminId = 'admin_root',
  ) {
    return this.adminService.adjustCoins(adminId, body);
  }

  @Post('users/ban')
  async banUser(
    @Body() body: AdminBanUserDto,
    @Query('adminId') adminId = 'admin_root',
  ) {
    await this.adminService.banUser(adminId, body);
    return { success: true };
  }

  @Get('audit-logs')
  async getAuditLogs(@Query('limit') limit = '50') {
    return this.adminService.getAuditLogs(parseInt(limit, 10));
  }
}
