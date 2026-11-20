import { describe, expect, it } from 'vitest';
import { AuthService, generateFriendCode } from '../src/modules/auth/auth.service.js';

describe('AuthService Token Management', () => {
  const authService = new AuthService();

  it('generates valid JWT tokens and verifies payload', () => {
    const friendCode = generateFriendCode();
    const tokens = authService.generateTokens('user_123', 'Bikash', friendCode, false);
    expect(tokens.accessToken).toBeDefined();
    expect(tokens.refreshToken).toBeDefined();
    expect(tokens.friendCode).toBe(friendCode);

    const verified = authService.verifyAccessToken(tokens.accessToken);
    expect(verified.userId).toBe('user_123');
    expect(verified.name).toBe('Bikash');
    expect(verified.friendCode).toBe(friendCode);
    expect(verified.isGuest).toBe(false);
  });

  it('generates 6-character friend code excluding ambiguous characters (0, O, 1, I)', () => {
    for (let i = 0; i < 20; i++) {
      const code = generateFriendCode();
      expect(code).toHaveLength(6);
      expect(code).toMatch(/^[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{6}$/);
      expect(code).not.toMatch(/[0O1I]/);
    }
  });

  it('rejects tampered tokens', () => {
    const tokens = authService.generateTokens('user_123', 'Bikash', 'TESTFC', false);
    const parts = tokens.accessToken.split('.');
    const tampered = `${parts[0]}.${parts[1]}.invalid_signature_xyz`;
    expect(() => authService.verifyAccessToken(tampered)).toThrow();
  });

  it('rejects expired or malformed tokens', () => {
    expect(() => authService.verifyAccessToken('invalid.token')).toThrow();
    expect(() => authService.verifyAccessToken('')).toThrow();
  });
});
