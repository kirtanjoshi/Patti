# Changelog

All notable changes to the **Patii** multi-game platform will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.0] - 2026-11-20

### Added
- **"Players Around Me" (Nearby Radar Discovery)**:
  - Geospatial detection of active card game players in the neighborhood (within 500m to 10km radius).
  - Animated radar pulse scanner in the Friends screen (`NearbyRadarView`).
  - Privacy safeguards: coarse coordinates (~110m resolution), approximate distance pills (`~350m away`), opt-in visibility toggle, 15-minute temporary TTL.
  - 1-tap "Add Friend" and "Invite to Table" actions directly from nearby radar results.
  - Server endpoints: `POST /social/nearby/location`, `GET /social/nearby`, `POST /social/nearby/visibility`.
- **"Play as Guest" & "Continue with Google" Authentication**:
  - Dedicated casino-themed `AuthScreen` with 1-tap Guest login and Google Sign-In.
  - Device-bound guest accounts with 10,000 starting coins and unique 6-character `friendCode` (excluding 0, O, 1, I).
  - Seamless 1-tap Guest-to-Google account linking (`linkGoogleAccount`) preserving 100% of coins, friends, XP, and match history.
  - Interactive `GoogleAuthSheet` profile modal with friend code copy pill, verification badge, and sign out.
- **Viral Deep Linking & Invite Links**:
  - Custom URI scheme `patii://room/<CODE>` and `patii://friend/<FRIEND_CODE>`.
  - Universal / App Links: `https://patii.app/r/<CODE>` and `https://patii.app/f/<FRIEND_CODE>`.
  - Smart landing controller (`InviteRedirectController`) serving rich OpenGraph cards for WhatsApp, Messenger, and Viber with auto-redirect to app.
  - Cross-platform `DeepLinkService` using `app_links` to dispatch users directly into room lobbies or auto-connect friends.
- **Real-Time Friends System & Presence**:
  - Live online presence tracking (`online`, `in_room`, `in_table`, `offline`).
  - Friends screen on Bottom Nav Tab 1 with native share sheet (`share_plus`).
  - Auto-connect mutual friendship on opening shared invite links.
  - In-app 1-tap room invite banners sent over Socket.IO with sound and haptics.
- **Multi-Game Real-Time Table & Private Room Gateway**:
  - Upgraded `TableRuntime` and `TableService` with dynamic engine factory supporting all 8 card games.
  - Live private room lobby with 6-character code, seat cards (human/bot), bot addition, and start game controls.
- **24/7 Keep-Alive Heartbeat & Health Monitoring**:
  - Built-in `HealthService` running a periodic heartbeat every 5 minutes (`prisma.$queryRaw\`SELECT 1\``) preventing Supabase and cloud Postgres from pausing/sleeping.
  - Automatic Render web service self-ping (`RENDER_EXTERNAL_URL`) to prevent server spin-down.
  - Endpoints: `GET /health` (metrics: uptime, DB status, version) and `GET /health/ping` (`pong`).
- **CI/CD Pipeline & Render Infrastructure Blueprint**:
  - Added `.github/workflows/ci.yml` running Node 22 backend typecheck, Prisma generation, building, and unit tests, alongside Flutter 3.29 mobile analysis and tests.
  - Added automated Render deployment dispatch via `RENDER_DEPLOY_HOOK_URL`.
  - Added `render.yaml` Infrastructure-as-Code Blueprint with native `autoDeploy: true`, zero-downtime healthcheck `/health/ping`, and automatic monorepo dependency ordering.

### Changed
- Bumped `patii` Flutter mobile app version to `1.1.0+2`.
- Bumped `@patii/server`, `@patii/protocol`, and `@patii/db` versions to `0.2.0`.
- Updated `docs/PRD.md` with Section 14 (Multiplayer, Deep Linking & Auth) and Section 14.5 (Nearby Players Discovery).
- Updated `docs/PROGRESS.md` with Wave 8 milestone status.

---

## [1.0.0] - 2026-11-16

### Added
- **Core 8 Nepali Card Game Engines**:
  - Callbreak, Marriage, Teen Patti, Kitti, Dhumbal, Jutpatti, Nepali Rummy, Joker Rummy (Paplu).
  - Pure deterministic TypeScript rules engine with 100% test coverage and fixtures.
- **Offline Dart Engine Parity**:
  - `packages/dart/patii_engine` with Mulberry32 seeded RNG and `LocalTableEngine` for offline airplane mode play.
- **Bot AI Strategies**:
  - Easy and Medium heuristic bots with card counting.
  - Hard bots with Information Set Monte Carlo Tree Search (`ISMCTS`) and Teen Patti Monte Carlo equity search.
- **Presentation-Layer Casino Visual Redesign**:
  - Custom casino theme: Felt green, gold gradients, wood rails, Cinzel/Poppins/Mukta typography.
  - Custom widgets: `PlayingCard` (Dhaka back), `CardHand` fan, `PlayerSeat`, `ChipStack`, `TableFelt`, `TableShell`.
  - Procedural audio sound effects (`AudioService`) and haptic feedback.
- **Web Admin Console**:
  - Next.js 15 App Router panel with TanStack Table, live table monitoring, economy RemoteConfig, and immutable AuditLog.
- **Security & Integrity**:
  - Double-entry coin ledger with sum-to-zero validation.
  - Anti-cheat masking via `viewFor()` so hidden cards are never sent to opponent clients.
