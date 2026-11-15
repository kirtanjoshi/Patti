import { describe, expect, it } from 'vitest';
import { AuthService } from '../src/modules/auth/auth.service.js';

describe('AuthService Token Management', () => {
  const authService = new AuthService();

  it('generates valid JWT tokens and verifies payload', () => {
    const tokens = authService.generateTokens('user_123', 'Bikash', false);
    expect(tokens.accessToken).toBeDefined();
    expect(tokens.refreshToken).toBeDefined();

    const verified = authService.verifyAccessToken(tokens.accessToken);
    expect(verified.userId).toBe('user_123');
    expect(verified.name).toBe('Bikash');
    expect(verified.isGuest).toBe(false);
  });

  it('rejects tampered tokens', () => {
    const tokens = authService.generateTokens('user_123', 'Bikash', false);
    const parts = tokens.accessToken.split('.');
    // Tamper with the signature
    const tampered = `${parts[0]}.${parts[1]}.invalid_signature_xyz`;
    expect(() => authService.verifyAccessToken(tampered)).toThrow();
  });
});
