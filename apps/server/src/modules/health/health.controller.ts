import { Controller, Get } from '@nestjs/common';
import { HealthService } from './health.service.js';

@Controller('health')
export class HealthController {
  constructor(private readonly healthService: HealthService) {}

  @Get()
  public async getHealth() {
    return this.healthService.getHealth();
  }

  @Get('ping')
  public ping() {
    return { status: 'pong', timestamp: new Date().toISOString() };
  }
}
