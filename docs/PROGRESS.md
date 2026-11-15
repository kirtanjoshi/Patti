# Patii — Project Progress & Tracking

Last Updated: 2026-11-16
Current Phase: **Wave 1 — Foundation**
Current Status: **Awaiting User Approval to Start Wave 1 ("go")**

---

## 1. Team Ownership & Responsibilities

| Role | Agent | Ownership Scope | Active Waves |
|---|---|---|---|
| **Coordinator** | `@coordinator` | Plans waves, assigns work, approves contract changes, merges, maintains `docs/PROGRESS.md`. Does not write feature code. | All Waves |
| **Architect** | `@architect` | Shared contracts: `packages/game-engine` core types + `GameModule` interface, `packages/protocol`, Prisma schema in `packages/db`, table shell API contract. | Wave 1 |
| **Server** | `@server` | `apps/server`: Auth, Wallet, Table runtime, Timers, Reconnect, Gateway, Matchmaking, Rooms, Social, Leaderboard, Notifications, Admin API. | Wave 2, 4 |
| **Mobile** | `@mobile` | `apps/mobile`: Flutter app shell, shared table shell, lobby, auth, rooms, social, settings, localization (`en`/`ne`). | Wave 2, 3, 4 |
| **Game Specialists** | `@game-<name>`<br>(`callbreak`, `teenpatti`, `kitti`, `dhumbal`, `jutpatti`, `rummy`, `jokerrummy`, `marriage`) | Game engine rules module (`packages/game-engine/src/games/<name>`), game bots, and Flutter game table UI on the shared shell. | Wave 2 (`callbreak`), Wave 3 (all others) |
| **Bots Specialist** | `@bots` | Shared bot utilities (`CardTracker`, `Determinizer`, `HandEvaluator3`, `MeldSolver`), simulation harness, and Hard ISMCTS bots. | Wave 2, 3, 5 |
| **Dart Port** | `@dart-port` | `packages/dart/patii_engine` + offline `LocalTableEngine`, 100% parity with TS fixtures. | Wave 5 |
| **Admin** | `@admin` | `apps/admin`: Next.js 15 App Router, shadcn/ui, TanStack Table, Admin REST integrations. | Wave 4 |
| **Verifier** | `@verifier` | Reviews diffs, runs tests, checks PRD acceptance criteria, reports defects. Never fixes code directly. | All Waves |
| **Security Auditor** | `@security-auditor` | Audit for hidden-card leaks, wallet double-spend, auth vulnerabilities, rate limits, anti-cheat (PRD 7.5). | Wave 3, 6 |

---

## 2. Master Wave Roadmap & Gate Status

- [ ] **Wave 1 — Foundation (@architect only)**
  - Scope: Monorepo setup, configs, Prisma schema + migration + house account seed, protocol + Dart codegen, docker-compose, CI skeleton, Card model, seeded shuffle with commit-reveal, GameModule interface, table shell API contract.
  - Acceptance Gate: `pnpm turbo build test lint` green, `flutter analyze` green, docker compose up works, migration succeeds.
- [ ] **Wave 2 — First Playable Vertical Slice (Parallel)**
  - Scope: Callbreak engine with all toggles + fixtures + 100k-game simulation; Server core (auth, wallet, table runtime, timers, reconnect, Redis persistence + owner lock, gateway, matchmaking with bot fill after 8 s); Easy/Medium Callbreak bots + simulation harness; Mobile app shell + Callbreak table UI (en/ne).
  - Acceptance Gate: Full online Callbreak game with 2 humans + 2 bots and correct coin settlement; reconnect after network loss restores hand; server instance kill mid-game resumes table; wallet sum-to-zero passes.
- [ ] **Wave 3 — Remaining Games (Parallel)**
  - Scope: `HandEvaluator3` and `MeldSolver` utilities; Teen Patti, Kitti, Dhumbal, Jutpatti, Nepali Rummy, Joker Rummy, Marriage (both seeing routes, Alter/Man toggles, maal points, tunnela bonus, settlement formula, Classic/Murder/Kidnap modes).
  - Acceptance Gate: Every PRD scoring example passes as a test; 0 illegal moves in 100,000 bot games per title; all 8 games playable online and vs bots.
- [ ] **Wave 4 — Rooms, Social, Economy, Admin (Parallel)**
  - Scope: Private rooms with 6-char codes & deep links, host controls, rule toggles UI, friends, quick-chat, emoji, leaderboards, daily rewards, chest, rescue coins, XP/levels, FCM; Next.js Admin Panel with roles, TOTP, audit log, RemoteConfig.
  - Acceptance Gate: 2 friends play custom-rules Marriage room joined via link; reward amounts match PRD 8.1; admin coin adjustment and ban appear in audit log; `/baseline-ui` and `/fixing-accessibility` applied to `apps/admin`.
- [ ] **Wave 5 — Offline Mode & Hard Bots (Parallel)**
  - Scope: `packages/dart/patii_engine` offline engine + Dart bots in an isolate; 100% parity with TS fixtures; ISMCTS bots for Callbreak, Marriage, and both Rummies; Monte Carlo equity for Teen Patti; Kitti search.
  - Acceptance Gate: 100% parity fixtures pass; every game playable in airplane mode; win-rate targets in PRD 6.6 met.
- [ ] **Wave 6 — Hardening & Launch Readiness (Parallel & Final Review)**
  - Scope: k6 load test at 5,000 concurrent clients; NFR validation; Fastlane lanes; account deletion; 18+ age gate; bilingual privacy policy & terms; 4-colour deck; reduce motion; security audit; final verification.
  - Acceptance Gate: All PRD 12 NFR targets met with documented evidence; zero critical security defects.

---

## 3. Wave 1 Detailed Execution Plan (Foundation)

Wave 1 is executed sequentially by `@architect` to lay the immutable architectural foundation and establish the contracts before parallel feature development begins.

### Step 1.1: Git & Workspace Root Setup
- Initialize Git repository (`git init`).
- Configure `.gitignore` (ignoring `node_modules`, `.turbo`, `dist`, `.dart_tool`, Flutter build outputs, `.env`, etc.).
- Setup `.env.example` defining environment variables:
  - Database: `DATABASE_URL` (PostgreSQL 16)
  - Redis: `REDIS_URL` (Redis 7)
  - Auth: `JWT_SECRET`, `JWT_EXPIRES_IN`, `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`
  - Admin: `ADMIN_JWT_SECRET`, `ADMIN_TOTP_ISSUER`
- Create root `package.json` with pnpm workspace scripts.
- Configure `pnpm-workspace.yaml`:
  ```yaml
  packages:
    - 'apps/*'
    - 'packages/*'
    - 'packages/dart/*'
  ```
- Configure `turbo.json` with pipeline definitions (`build`, `test`, `lint`, `typecheck`, `db:generate`, `codegen`).
- Configure `melos.yaml` for Dart/Flutter packages:
  - `packages/dart/patii_engine`
  - `packages/dart/patii_protocol`
  - `apps/mobile`

### Step 1.2: Shared Configurations (`packages/config`)
- Create `packages/config` containing:
  - Base TypeScript configurations (`tsconfig.base.json`, `tsconfig.node.json`)
  - ESLint configurations (`eslint-config-patii`)
  - Shared Prettier configuration (`prettier-config-patii`)

### Step 1.3: Database Package & Prisma Schema (`packages/db`)
- Initialize Prisma with PostgreSQL provider in `packages/db`.
- Implement full schema according to **PRD Section 9**:
  - Enums: `GameId`, `AuthProvider`, `UserStatus`, `MatchMode`, `WalletAccountType`, `TxKind`.
  - Models:
    - `User`: Profile, status, XP, level, rating, language.
    - `AuthIdentity`: Multi-provider credentials (Guest, Google, Phone).
    - `Device`: Push FCM tokens, platform, appVersion, ipHash.
    - `WalletAccount`: Types (`USER`, `HOUSE_RAKE`, `HOUSE_BOT`, `HOUSE_REWARDS`, `HOUSE_IAP`), balance, held.
    - `WalletTx`: Double-entry transaction record with `debitAccount`, `creditAccount`, `amount`, `idempotencyKey` (@unique), `kind`.
    - `Match`: Historical match records, rules JSON, seed, seedHash, moveLog JSON.
    - `MatchPlayer`: Seat, points, coinDelta, placement.
    - `GameStat`: Per-game played, won, bestWin.
    - `Friendship`: Pending, accepted, blocked relations.
    - `DailyReward`: Streak tracking, chest timers.
    - `Report`: Player report queue.
    - `AdminUser`: Email, role (`owner`, `moderator`, `support`), passwordHash, totpSecret.
    - `AuditLog`: Admin audit logging.
    - `RemoteConfig`: Key-value dynamic configuration.
- Implement database seed script (`packages/db/src/seed.ts`):
  - Pre-populate required house wallet accounts: `HOUSE_RAKE`, `HOUSE_BOT`, `HOUSE_REWARDS`, `HOUSE_IAP`.
- Provide migration scripts and generate Prisma Client.

### Step 1.4: Protocol & Dart Codegen (`packages/protocol` & `packages/dart/patii_protocol`)
- In `packages/protocol`:
  - Define Zod schemas for all real-time Socket.IO events (PRD 7.3):
    - Client -> Server: `queue:join`, `queue:leave`, `room:create`, `room:join`, `room:leave`, `room:kick`, `room:addBot`, `room:start`, `table:move`, `table:resync`, `table:chat`, `table:rematch`.
    - Server -> Client: `queue:matched`, `table:state`, `table:event`, `table:turn`, `table:result`, `table:chat`, `error`.
  - Common envelope schemas: versioning, timestamps, error codes (`ILLEGAL_MOVE`, `NOT_YOUR_TURN`, `STALE_VERSION`, `INSUFFICIENT_COINS`, etc.).
  - Implement Dart code generator script (`scripts/generate-dart-protocol.ts` or `packages/protocol/scripts/codegen.ts`) to emit Dart freezed/json_serializable classes into `packages/dart/patii_protocol`.

### Step 1.5: Core Game Engine Contracts (`packages/game-engine`)
- In `packages/game-engine`:
  - Pure, deterministic, zero-I/O architecture (No `Math.random()`, no `Date.now()`).
  - **Card Model (PRD 4.1)**:
    - `Card`: `{ suit: 'S'|'H'|'D'|'C'|'X', rank: 1..13 | 0, deck: 0..2, id: string }`.
    - Card creation, standard 52-card pack generators, multi-deck generators with unique opaque IDs.
    - Rank comparison utilities (Ace-high, Ace-low, Ace-both-ends).
  - **Seeded CSPRNG Shuffle & Commit-Reveal (PRD 4.3)**:
    - Pure Fisher-Yates shuffle driven by a seeded PRNG (e.g. Mulberry32 / ChaCha20 or equivalent deterministic pure PRNG).
    - Commit-reveal utility: `seedHash = sha256(seed)`.
  - **GameModule Interface (PRD 4.2)**:
    ```typescript
    export interface GameModule<S, M, R> {
      id: GameId;
      defaultRules: R;
      validateRules(r: R): R;
      setup(players: PlayerId[], rules: R, seed: string): S;
      legalMoves(s: S, p: PlayerId): M[];
      applyMove(s: S, p: PlayerId, m: M): S;
      currentActor(s: S): PlayerId | null;
      isRoundOver(s: S): boolean;
      scoreRound(s: S): RoundResult;
      isGameOver(s: S): boolean;
      viewFor(s: S, p: PlayerId | 'spectator'): PublicView;
      autoMove(s: S, p: PlayerId): M;
    }
    ```
  - Standard error types: `IllegalMoveError`, `NotYourTurnError`, `InvalidStateError`.
  - Unit tests verifying determinism, pure card generation, and shuffle commitment.

### Step 1.6: Infrastructure & Local Docker Compose (`infra/`)
- Setup `infra/docker-compose.yml`:
  - PostgreSQL 16 container with health check.
  - Redis 7 container with health check.
  - Environment variables and data volume configurations.
- Verify container startup and connectivity.

### Step 1.7: Application Skeletons & Dart Packages
- `apps/server`:
  - NestJS 10 application skeleton.
  - Integration with `@patii/db` and `@patii/protocol`.
  - Scripts for build, test, lint.
- `apps/admin`:
  - Next.js 15 App Router skeleton.
  - Tailwind CSS + shadcn/ui base configuration.
- `apps/mobile`:
  - Flutter 3 app skeleton (`com.patii.app`).
  - `package.json` proxy script enabling Turborepo to run `flutter analyze` and `flutter test`.
  - Localization directories with initial `en.json` and `ne.json` skeleton.
  - Conformance to Flutter UI baseline tokens: ThemeData, 8-pt spacing, 48x48 tap targets.
- `packages/dart/patii_engine`:
  - Dart package skeleton with core Card model and GameModule abstractions matching TS engine.

### Step 1.8: CI & Wave 1 Verification
- Create `.github/workflows/ci.yml`:
  - Node & pnpm setup, caching.
  - Flutter & Dart setup.
  - Turborepo lint, build, test.
  - `flutter analyze` verification.
- Run complete Wave 1 verification commands locally:
  - `pnpm turbo build test lint` -> GREEN
  - `flutter analyze` -> GREEN
  - `docker compose -f infra/docker-compose.yml up -d` -> HEALTHY
  - Prisma migrations and seed -> SUCCESS

---

## 4. Shared Contracts Registry (Immutable Boundary)

Per Non-Negotiable Rule 8, these files/modules are **SHARED CONTRACTS**. Only `@architect` may modify them, requiring `@coordinator` review:
1. `packages/game-engine/src/core/types.ts` & `interface.ts` (`GameModule`, `Card`, `PublicView`, `RoundResult`).
2. `packages/protocol/src/**/*.ts` (All Zod schemas & socket events).
3. `packages/db/prisma/schema.prisma` (Database schema & enums).
4. Table shell API contracts between server table runtime and clients.

---

## 5. Open Questions & House Rules Tracking (from PRD)

These items are documented and tracked for product resolution; quick match and defaults adhere strictly to PRD specifications:

1. **App Name Spelling**: PRD uses "Patii" (package ID `com.patii.app`). Confirmed as "Patii".
2. **Marriage Tiplu Double Value**: Defaulted to 8 (common Nepali app style); toggleable to 7.
3. **Dhumbal Default Card Values**: Defaulted to J=11, Q=12, K=13 (app style); toggleable to Pagat classic (J=0, Q=K=10).
4. **Callbreak Default Scoring**: Defaulted to Nepali app style (+call, +0.1 per extra trick, -call if failed); toggleable to Pagat classic.
5. **Teen Patti Store Listing**: Marked 17+ / simulated gambling in metadata; age gate (18+) in onboarding.

---

## 6. Wave Execution Log

| Wave | Owner | Status | Completed At | Notes / Blockers |
|---|---|---|---|---|
| Wave 1: Foundation | `@architect` | Planned (Awaiting "go") | — | Detailed plan written in `docs/PROGRESS.md`. |
| Wave 2: First Slice | `@game-callbreak`, `@server`, `@bots`, `@mobile` | Pending | — | Depends on Wave 1 sign-off. |
| Wave 3: Remaining Games | `@game-*`, `@bots` | Pending | — | Depends on Wave 2 sign-off. |
| Wave 4: Rooms/Social/Admin | `@server`, `@mobile`, `@admin` | Pending | — | Depends on Wave 3 sign-off. |
| Wave 5: Offline/Hard Bots | `@dart-port`, `@bots` | Pending | — | Depends on Wave 4 sign-off. |
| Wave 6: Hardening | `@security-auditor`, `@verifier` | Pending | — | Final phase. |
