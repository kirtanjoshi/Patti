import { describe, expect, it } from 'vitest';
import { SocialService } from '../src/modules/social/social.service.js';
import { NearbyService } from '../src/modules/social/nearby.service.js';
import { InviteRedirectController } from '../src/modules/invites/invite-redirect.controller.js';

describe('SocialService (Presence & Friends)', () => {
  const socialService = new SocialService();

  it('sets and retrieves live player presence', () => {
    socialService.setPresence('user_1', 'online');
    const p1 = socialService.getPresence('user_1');
    expect(p1.status).toBe('online');
    expect(p1.gameId).toBeNull();

    socialService.setPresence('user_1', 'in_table', 'callbreak');
    const p2 = socialService.getPresence('user_1');
    expect(p2.status).toBe('in_table');
    expect(p2.gameId).toBe('callbreak');

    const unknown = socialService.getPresence('user_unknown');
    expect(unknown.status).toBe('offline');
  });
});

describe('NearbyService (Haversine & Privacy Coarse Location)', () => {
  const socialService = new SocialService();
  const nearbyService = new NearbyService(socialService);

  it('calculates accurate Haversine distances in meters', () => {
    // Kathmandu Durbar Square (~27.7042, 85.3075) to Thamel (~27.7154, 85.3123) ~ 1.3 km
    const dist = nearbyService.calculateDistanceMeters(27.7042, 85.3075, 27.7154, 85.3123);
    expect(dist).toBeGreaterThan(1100);
    expect(dist).toBeLessThan(1500);

    const formatted = nearbyService.formatDistance(dist);
    expect(formatted).toContain('km away');

    const closeDist = nearbyService.formatDistance(320);
    expect(closeDist).toBe('~300m away');
  });

  it('stores coarse location and manages visibility toggles', () => {
    nearbyService.updateLocation('user_a', 27.7042, 85.3075, true);
    nearbyService.setVisibility('user_a', false);

    // After setting visibility false, user is removed from active map
    nearbyService.updateLocation('user_b', 27.7050, 85.3080, true);
    // User B should not see hidden User A
  });
});

describe('InviteRedirectController (Landing Pages & Universal Links)', () => {
  const controller = new InviteRedirectController();

  it('renders room landing page with deep link redirect and OpenGraph tags', () => {
    const html = controller.getRoomLandingPage('7X8K2M');
    expect(html).toContain('patii://room/7X8K2M');
    expect(html).toContain('7X8K2M');
    expect(html).toContain('og:title');
    expect(html).toContain('Join my Patii Card Table!');
  });

  it('renders friend landing page with deep link redirect and friend code', () => {
    const html = controller.getFriendLandingPage('PT9999');
    expect(html).toContain('patii://friend/PT9999');
    expect(html).toContain('PT9999');
    expect(html).toContain('og:title');
    expect(html).toContain('Add me as a friend on Patii!');
  });

  it('serves assetlinks and apple-app-site-association', () => {
    const assetlinks = controller.getAssetLinks();
    expect(Array.isArray(assetlinks)).toBe(true);
    expect(assetlinks[0]).toHaveProperty('target');

    const apple = controller.getAppleAppSiteAssociation();
    expect(apple).toHaveProperty('applinks');
  });
});
