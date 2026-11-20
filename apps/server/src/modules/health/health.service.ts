import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { prisma } from '@patii/db';

@Injectable()
export class HealthService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(HealthService.name);
  private heartbeatTimer: NodeJS.Timeout | null = null;
  private readonly intervalMs = Number(process.env.KEEP_ALIVE_INTERVAL_MS) || 5 * 60 * 1000; // 5 minutes default

  public onModuleInit(): void {
    this.startHeartbeat();
  }

  public onModuleDestroy(): void {
    this.stopHeartbeat();
  }

  public startHeartbeat(): void {
    if (this.heartbeatTimer) return;

    this.logger.log(`[KeepAlive] Heartbeat service started. Pinging database every ${this.intervalMs / 1000}s`);

    // Run first ping after 15 seconds to let server initialize
    setTimeout(() => {
      this.executeHeartbeat().catch((err) => {
        this.logger.warn(`[KeepAlive] Initial heartbeat warning: ${err.message}`);
      });
    }, 15000);

    this.heartbeatTimer = setInterval(async () => {
      await this.executeHeartbeat();
    }, this.intervalMs);

    // Ensure timer doesn't block node process exit in tests
    if (this.heartbeatTimer && typeof this.heartbeatTimer.unref === 'function') {
      this.heartbeatTimer.unref();
    }
  }

  public stopHeartbeat(): void {
    if (this.heartbeatTimer) {
      clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = null;
      this.logger.log('[KeepAlive] Heartbeat service stopped');
    }
  }

  public async executeHeartbeat(): Promise<{ db: boolean; external: boolean; timestamp: string }> {
    let dbSuccess = false;
    let externalSuccess = false;

    // 1. Keep Supabase / Postgres connection active
    try {
      await prisma.$queryRaw`SELECT 1`;
      dbSuccess = true;
      this.logger.debug('[KeepAlive] Database heartbeat ping successful (Supabase active)');
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      this.logger.warn(`[KeepAlive] Database ping failed: ${msg}`);
    }

    // 2. Keep Render service itself awake if public URL is configured
    // Render sets RENDER_EXTERNAL_URL automatically on Web Services
    const externalUrl = process.env.RENDER_EXTERNAL_URL || process.env.SERVER_URL;
    if (externalUrl) {
      try {
        const pingUrl = `${externalUrl.replace(/\/+$/, '')}/health/ping`;
        const res = await fetch(pingUrl, { method: 'GET', signal: AbortSignal.timeout(5000) });
        externalSuccess = res.ok;
        this.logger.debug(`[KeepAlive] Server self-ping to ${pingUrl} status: ${res.status}`);
      } catch (err: unknown) {
        const msg = err instanceof Error ? err.message : String(err);
        this.logger.debug(`[KeepAlive] External self-ping skipped or timed out: ${msg}`);
      }
    }

    return {
      db: dbSuccess,
      external: externalSuccess,
      timestamp: new Date().toISOString(),
    };
  }

  public async getHealth(): Promise<{
    status: 'ok' | 'degraded';
    uptime: number;
    db: 'connected' | 'disconnected';
    timestamp: string;
    version: string;
  }> {
    let dbStatus: 'connected' | 'disconnected' = 'disconnected';
    try {
      await prisma.$queryRaw`SELECT 1`;
      dbStatus = 'connected';
    } catch {
      dbStatus = 'disconnected';
    }

    return {
      status: dbStatus === 'connected' ? 'ok' : 'degraded',
      uptime: Math.floor(process.uptime()),
      db: dbStatus,
      timestamp: new Date().toISOString(),
      version: process.env.npm_package_version || '0.2.0',
    };
  }
}
