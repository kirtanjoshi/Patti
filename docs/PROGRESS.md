# Patii — Project Progress & Tracking

Last Updated: 2026-11-16
Current Phase: **Wave 2 Completed / Wave 3 Ready**
Current Status: **Wave 2 Sign-off Complete (All 21 Turbo Tasks Green & Flutter Tests Green)**

---

## 1. Team Ownership & Responsibilities

| Role | Agent | Ownership Scope | Status |
|---|---|---|---|
| **Coordinator** | `@coordinator` | Plans waves, assigns work, approves contract changes, merges, maintains `docs/PROGRESS.md`. Does not write feature code. | Active |
| **Architect** | `@architect` | Shared contracts: `packages/game-engine` core types + `GameModule` interface, `packages/protocol`, Prisma schema in `packages/db`, table shell API contract. | Wave 1 Complete |
| **Server** | `@server` | `apps/server`: Auth, Wallet, Table runtime, Timers, Reconnect, Gateway, Matchmaking, Rooms, Social, Leaderboard, Notifications, Admin API. | Wave 2 Complete |
| **Mobile** | `@mobile` | `apps/mobile`: Flutter app shell, shared table shell, lobby, auth, rooms, social, settings, localization (`en`/`ne`). | Wave 2 Complete |
| **Game Specialists** | `@game-callbreak` | Callbreak game engine (`packages/game-engine/src/games/callbreak`), fixtures, and Flutter table UI. | Wave 2 Complete |
| **Game Specialists** | `@game-<name>`<br>(`teenpatti`, `kitti`, `dhumbal`, `jutpatti`, `rummy`, `jokerrummy`, `marriage`) | Game engine rules modules, game bots, and Flutter game table UIs. | Wave 3 (Next) |
| **Bots Specialist** | `@bots` | Shared bot utilities (`CardTracker`, `Determinizer`, `HandEvaluator3`, `MeldSolver`), simulation harness, and Hard ISMCTS bots. | Wave 2 Complete (`callbreak`), Wave 3 (HandEvaluator3, MeldSolver) |
| **Dart Port** | `@dart-port` | `packages/dart/patii_engine` + offline `LocalTableEngine`, 100% parity with TS fixtures. | Wave 5 |
| **Admin** | `@admin` | `apps/admin`: Next.js 15 App Router, shadcn/ui, TanStack Table, Admin REST integrations. | Wave 1 Baseline, Wave 4 Full UI |
| **Verifier** | `@verifier` | Reviews diffs, runs tests, checks PRD acceptance criteria, reports defects. | Active |
| **Security Auditor** | `@security-auditor` | Audit for hidden-card leaks, wallet double-spend, auth vulnerabilities, rate limits, anti-cheat (PRD 7.5). | Wave 3, 6 |

---

## 2. Master Wave Roadmap & Gate Status

- [x] **Wave 1 — Foundation (@architect only)**
  - Monorepo setup, configs, Prisma schema, protocol + Dart codegen, Card model, seeded shuffle, GameModule interface, table shell API contract.
  - Acceptance Gate: `pnpm turbo build test lint` green, `flutter analyze` green, docker compose infra ready, migration schema generated.
- [x] **Wave 2 — First Playable Vertical Slice (Parallel)**
  - Callbreak engine with all toggles + fixtures + 100k-game simulation harness;
  - Server core (auth, double-entry wallet with holds/settlement, table runtime with optimistic versioning, timers, reconnect, Socket.IO gateway, matchmaking with 8s bot fill);
  - Easy/Medium Callbreak bots;
  - Mobile app shell + landscape Callbreak table UI with English and Nepali localization.
  - Acceptance Gate: Full Callbreak game flow, seat state transitions, wallet hold and settlement, all fixtures passing, `flutter analyze` and `flutter test` green.
- [ ] **Wave 3 — Remaining Games (Parallel)**
  - Scope: `HandEvaluator3` (all 22,100 Teen Patti hands) and `MeldSolver`; Teen Patti, Kitti, Dhumbal, Jutpatti, Nepali Rummy, Joker Rummy, Marriage (both seeing routes, Alter/Man toggles, maal points, tunnela bonus, settlement formula, Classic/Murder/Kidnap modes).
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

## 3. Wave 2 Completion Summary

| Module | Location | Details | Verification |
|---|---|---|---|
| **Callbreak Engine** | `packages/game-engine/src/games/callbreak` | `CallbreakGameModule` implementing `GameModule`, all 9 PRD toggles, scoring styles (Nepali & Pagat), must-follow, must-overtake, trumping rules, redeals. | `test/callbreak.test.ts` (15/15 passing) |
| **Fixtures** | `packages/game-engine/fixtures/callbreak-fixtures.json` | PRD Section 5.1 worked examples verified as fixture tests. | Passed |
| **Simulation** | `packages/game-engine/src/games/callbreak/simulation.ts` | Headless random simulation runner testing state machine invariants. | Passed |
| **Callbreak Bots** | `packages/bots/src/callbreak` | Heuristic bot (`Easy` and `Medium`) calculating sure tricks, spade lengths, voids, cheap trick wins, and low card dumps. | `test/callbreak-bot.test.ts` (3/3 passing) |
| **Auth & Wallet** | `apps/server/src/modules/auth`, `wallet` | Device-bound guest accounts, signed JWT tokens, double-entry wallet holds, settlement with idempotency keys, 5% rake to `HOUSE_RAKE`. | `test/auth.test.ts` (passing) |
| **Table Runtime & Gateway** | `apps/server/src/modules/table`, `gateways` | State machine, turn timers, disconnect grace / bot takeover, autoMove fallback, Socket.IO `/game` gateway with Zod schema validation. | `test/table-runtime.test.ts` (passing) |
| **Mobile Callbreak Table** | `apps/mobile/lib/features/games/callbreak` | Landscape table UI, 4 seat widgets, center trick arena, hand card fan, bidding dialog, leave confirmation dialog. | `flutter analyze` & `flutter test` (passing) |
| **Bilingual Localization** | `apps/mobile/assets/translations/{en,ne}.json` | Complete string keys in English and Nepali. | Verified |

---

## 4. Wave Execution Log

| Wave | Owner | Status | Completed At | Notes / Blockers |
|---|---|---|---|---|
| Wave 1: Foundation | `@architect` | Completed | 2026-11-16 | Monorepo, shared contracts, prisma, engine core, protocol, app skeletons. |
| Wave 2: First Slice | `@game-callbreak`, `@server`, `@bots`, `@mobile` | Completed | 2026-11-16 | Full Callbreak vertical slice, bots, table runtime, wallet hold/settle, mobile table UI. |
| Wave 3: Remaining Games | `@game-*`, `@bots` | Ready to start | — | 7 games: Marriage, Teen Patti, Kitti, Dhumbal, Jutpatti, Rummy, Joker Rummy. |
| Wave 4: Rooms/Social/Admin | `@server`, `@mobile`, `@admin` | Pending | — | Depends on Wave 3. |
| Wave 5: Offline/Hard Bots | `@dart-port`, `@bots` | Pending | — | Depends on Wave 4. |
| Wave 6: Hardening | `@security-auditor`, `@verifier` | Pending | — | Final phase. |
