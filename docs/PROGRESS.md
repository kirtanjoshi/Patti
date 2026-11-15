# Patii — Project Progress & Tracking

Last Updated: 2026-11-16
Current Phase: **All Waves 1–6 Completed & Verified**
Current Status: **Production Ready (All 8 Games, Server Runtime, Mobile Table UIs, Admin Console, Offline Dart Engine, Hard ISMCTS Bots, Anti-Cheat, & Load Tests Complete)**

---

## 1. Team Ownership & Responsibilities

| Role | Agent | Ownership Scope | Status |
|---|---|---|---|
| **Coordinator** | `@coordinator` | Plans waves, assigns work, approves contract changes, merges, maintains `docs/PROGRESS.md`. | Complete |
| **Architect** | `@architect` | Shared contracts: `packages/game-engine` core types + `GameModule` interface, `packages/protocol`, Prisma schema in `packages/db`, table shell API contract. | Wave 1 Complete |
| **Server** | `@server` | `apps/server`: Auth, Wallet, Table runtime, Timers, Reconnect, Gateway, Matchmaking, Rooms, Social, Leaderboard, Economy, Admin API. | Wave 2, 4, 6 Complete |
| **Mobile** | `@mobile` | `apps/mobile`: Flutter app shell, shared table shell, lobby, auth, rooms, daily rewards, game screens, localization (`en`/`ne`). | Wave 2, 3, 4, 5, 6 Complete |
| **Game Specialists** | `@game-<name>`<br>(`callbreak`, `teenpatti`, `kitti`, `dhumbal`, `jutpatti`, `rummy`, `jokerrummy`, `marriage`) | Game engine rules modules, game bots, and Flutter game table UIs. | Complete (All 8 Games) |
| **Bots Specialist** | `@bots` | Shared bot utilities (`CardTracker`, `Determinizer`, `HandEvaluator3`, `MeldSolver`), ISMCTS tree search, Teen Patti equity simulation, simulation harness. | Wave 3 & 5 Complete |
| **Dart Port** | `@dart-port` | `packages/dart/patii_engine` + offline `LocalTableEngine`, 100% parity with TS fixtures. | Wave 5 Complete |
| **Admin** | `@admin` | `apps/admin`: Next.js 15 App Router, shadcn/ui, TanStack Table, live tables monitoring, economy RemoteConfig, audit logging. | Wave 4 Complete |
| **Verifier** | `@verifier` | Reviews diffs, runs tests, checks PRD acceptance criteria, reports defects. | Complete |
| **Security Auditor** | `@security-auditor` | Audit for hidden-card leaks, wallet double-spend, auth vulnerabilities, rate limits, anti-cheat (PRD 7.5). | Wave 6 Complete |

---

## 2. Master Wave Roadmap & Gate Status

- [x] **Wave 1 — Foundation (@architect only)**
  - Monorepo setup, configs, Prisma schema (13 models, 6 enums), protocol + Dart codegen, Card model, seeded shuffle, GameModule interface, table shell API contract.
  - Acceptance Gate: `pnpm turbo build test lint` green, `flutter analyze` green, docker compose infra ready, migration schema generated.
- [x] **Wave 2 — First Playable Vertical Slice (Parallel)**
  - Callbreak engine with all toggles + fixtures + simulation harness;
  - Server core (auth, double-entry wallet with holds/settlement, table runtime with optimistic versioning, timers, reconnect, Socket.IO gateway, matchmaking with 8s bot fill);
  - Easy/Medium Callbreak bots;
  - Mobile app shell + landscape Callbreak table UI with English and Nepali localization.
  - Acceptance Gate: Full Callbreak game flow, seat state transitions, wallet hold and settlement, all fixtures passing, `flutter analyze` and `flutter test` green.
- [x] **Wave 3 — Remaining Games (Parallel)**
  - Shared utilities: `HandEvaluator3` (all 3-card combinations) and `MeldSolver` (sequences, sets, tunnelas, dublees).
  - All 8 game engines complete: Callbreak, Marriage, Teen Patti, Kitti, Dhumbal, Jutpatti, Nepali Rummy, Joker Rummy (Paplu).
  - Acceptance Gate: Every PRD scoring example passes as a fixture test; 22 unit tests passing in game engine; all 8 games verified.
- [x] **Wave 4 — Rooms, Social, Economy, Admin (Parallel)**
  - Private rooms with 6-char codes (excluding 0, O, 1, I), host controls, rule toggles UI (`CreateRoomScreen`, `JoinRoomScreen`).
  - Economy service: 7-day streak rewards (500–3,000 coins), 4-hour free chest (200 coins), bankrupt rescue (top up to 2,000), $100 \cdot n^2$ level-up formula.
  - Mobile UI: `DailyRewardDialog`, `RoomScreen`, 100% localized in `en.json` and `ne.json`.
  - Next.js Admin Panel: Dashboard, Users & Wallets, Live Tables monitoring, Economy RemoteConfig, and immutable Audit Log.
  - Acceptance Gate: 21/21 turborepo tasks green, Flutter analyze and test green, admin coin adjustment with mandatory audit reason.
- [x] **Wave 5 — Offline Mode & Hard Bots (Parallel)**
  - Pure Dart Engine port (`packages/dart/patii_engine`) with `SeedRng` Mulberry32, Callbreak scoring, Marriage settlement formula $P_i = T + w_i - n \cdot S_i$, and `LocalTableEngine` for offline airplane mode play vs bots.
  - 100% parity tests passing in Dart (`dart test`).
  - Hard Bots: Information Set Monte Carlo Tree Search (`ISMCTS`) with determinization and UCB selection; Monte Carlo equity calculator for Teen Patti.
  - Acceptance Gate: 100% parity fixtures pass; all offline and bot tests green.
- [x] **Wave 6 — Hardening, Security, Load Testing, & Final Verification**
  - Anti-Cheat & Security Audit: `viewFor()` strictly masks unrevealed opponent cards; double-entry ledger sum-to-zero ($\sum \Delta = 0$) verified.
  - Auth Security: Tampered JWT token rejection, guest device separation, GDPR/Store compliant account deletion endpoint (`DELETE /auth/account`).
  - k6 load test script (`apps/server/loadtest/k6-load.js`) simulating 5,000 concurrent socket connections to `/game` with p95 < 150ms connection latency.
  - Verification: 21 turborepo tasks green, 14 server tests passing, 8 bots tests passing, 11 Flutter tests passing, 3 Dart parity fixture tests passing.

---

## 3. Game Engines Registry

| # | Game | Engine Module | Decks | Hand Size | Toggles & Rules Verified | Status |
|---|---|---|---|---|---|---|
| 1 | **Callbreak** | `CallbreakGameModule` | 1 (52) | 13 | Must overtake, trump lead, min total calls, 3/5/10 deals, Pagat/Nepali scoring | Complete |
| 2 | **Marriage** | `MarriageGameModule` | 3 (156) | 21 | Classic/Murder/Kidnap, Alter, Man cards, dublee route, tunnela bonus, $P_i = T + w_i - n \cdot S_i$ | Complete |
| 3 | **Teen Patti** | `TeenPattiGameModule` | 1 (52) | 3 | Blind/chaal limits, Trail > Pure Seq > Seq > Color > Pair > High, pot limit | Complete |
| 4 | **Kitti** | `KittiGameModule` | 1 (52) | 9 | 3 shows of 3, 2 wins to win, Salami bonus, 2-3-5 kill, carryover | Complete |
| 5 | **Dhumbal** | `DhumbalGameModule` | 1 (+ jokers) | 5 | Jhyap call <= 5, 25 penalty on fail, 100 elimination, app/classic card values | Complete |
| 6 | **Jutpatti** | `JutpattiGameModule` | 1 (52) | 5/7/9/11 | Cut joker rank, even-count declare, all pairs validation | Complete |
| 7 | **Nepali Rummy** | `RummyGameModule(false)` | 1 or 2 | 10 | Cut joker wild, pure sequence + set, 80 max penalty, pool/points modes | Complete |
| 8 | **Joker Rummy** | `RummyGameModule(true)` | 2 + 4 jokers | 13 | Tiplu, Paplu, Nichlu, Marriage 50 bonus, 2 sequences (1 pure) declare | Complete |

---

## 4. Verification Evidence & Test Summary

- **Node / TypeScript Workspace (`turbo run build lint test`)**:
  - `Tasks: 21 successful, 21 total (100% green)`
  - Packages: `@patii/admin`, `@patii/bots`, `@patii/config`, `@patii/db`, `@patii/game-engine`, `@patii/mobile`, `@patii/protocol`, `@patii/server`.
- **Server Test Suite (`apps/server`)**:
  - 14/14 tests passing (`test/security-audit.test.ts`, `test/table-runtime.test.ts`, `test/rooms.test.ts`, `test/admin.test.ts`, `test/auth.test.ts`, `test/economy.test.ts`, `test/server.test.ts`).
- **Bots Test Suite (`packages/bots`)**:
  - 8/8 tests passing (`test/ismcts.test.ts`, `test/teenpatti-bot.test.ts`, `test/common-utils.test.ts`, `test/callbreak-bot.test.ts`, `test/bots.test.ts`).
- **Dart Engine Parity (`packages/dart/patii_engine`)**:
  - 3/3 tests passing against PRD JSON test fixtures (`dart test`).
- **Flutter Mobile App (`apps/mobile`)**:
  - `flutter analyze .`: No issues found!
  - `flutter test`: 11/11 tests passing (`widget_test.dart`, `callbreak_ui_test.dart`, `kitti_ui_test.dart`, `marriage_ui_test.dart`).
- **Admin App (`apps/admin`)**:
  - Next.js 15 build & typecheck successful; static routes pre-rendered (`/`, `/users`, `/tables`, `/economy`, `/audit`).
