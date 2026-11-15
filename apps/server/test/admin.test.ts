import { describe, expect, it } from 'vitest';
import { AdminService } from '../src/modules/admin/admin.service.js';

describe('AdminService Validation & Guardrails', () => {
  const adminService = new AdminService();

  it('rejects coin adjustments without a mandatory reason', async () => {
    await expect(
      adminService.adjustCoins('admin_1', {
        targetUserId: 'user_target',
        amount: 1000,
        reason: '',
      }),
    ).rejects.toThrow('A reason is strictly required for coin adjustments.');

    await expect(
      adminService.adjustCoins('admin_1', {
        targetUserId: 'user_target',
        amount: 1000,
        reason: '   ',
      }),
    ).rejects.toThrow('A reason is strictly required for coin adjustments.');
  });
});
