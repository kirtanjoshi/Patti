import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { HealthService } from '../src/modules/health/health.service.js';
import { HealthController } from '../src/modules/health/health.controller.js';

describe('Health & KeepAlive Heartbeat', () => {
  let service: HealthService;
  let controller: HealthController;

  beforeEach(() => {
    service = new HealthService();
    controller = new HealthController(service);
  });

  afterEach(() => {
    service.stopHeartbeat();
  });

  it('GET /health/ping returns pong', () => {
    const res = controller.ping();
    expect(res.status).toBe('pong');
    expect(res.timestamp).toBeDefined();
  });

  it('GET /health returns health metrics', async () => {
    const res = await controller.getHealth();
    expect(['ok', 'degraded']).toContain(res.status);
    expect(typeof res.uptime).toBe('number');
    expect(['connected', 'disconnected']).toContain(res.db);
    expect(res.timestamp).toBeDefined();
  });

  it('heartbeat execution handles database query gracefully', async () => {
    const result = await service.executeHeartbeat();
    expect(result).toHaveProperty('db');
    expect(result).toHaveProperty('external');
    expect(result.timestamp).toBeDefined();
  });

  it('starts and stops timer cleanly without leaking', () => {
    service.startHeartbeat();
    // Starting again shouldn't duplicate
    service.startHeartbeat();
    service.stopHeartbeat();
    // Stopping again shouldn't throw
    service.stopHeartbeat();
  });
});
