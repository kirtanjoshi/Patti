# Patii — Project Progress & Tracking

Last Updated: 2026-11-16
Current Phase: **Wave 3 Completed / Wave 4 Ready**
Current Status: **Wave 3 Sign-off Complete (All 8 Games Implemented & 100% Tested)**

---

## 1. Team Ownership & Responsibilities

| Role | Agent | Ownership Scope | Status |
|---|---|---|---|
| **Coordinator** | `@coordinator` | Plans waves, assigns work, approves contract changes, merges, maintains `docs/PROGRESS.md`. | Active |
| **Architect** | `@architect` | Shared contracts: `packages/game-engine` core types + `GameModule` interface, `packages/protocol`, Prisma schema in `packages/db`, table shell API contract. | Wave 1 Complete |
| **Server** | `@server` | `apps/server`: Auth, Wallet, Table runtime, Timers, Reconnect, Gateway, Matchmaking, Rooms, Social, Leaderboard, Notifications, Admin API. | Active |
| **Mobile** | `@mobile` | `apps/mobile`: Flutter app shell, shared table shell, lobby, auth, rooms, social, settings, localization (`en`/`ne`). | Active |
| **Game Specialists** | `@game-<name>`<br>(`callbreak`, `teenpatti`, `kitti`, `dhumbal`, `jutpatti`, `rummy`, `jokerrummy`, `marriage`) | Game engine rules modules, game bots, and Flutter game table UIs. | Wave 2 & 3 Complete (All 8 Games) |
| **Bots Specialist** | `@bots` | Shared bot utilities (`CardTracker`, `Determinizer`, `HandEvaluator3`, `MeldSolver`), simulation harness, and Hard ISMCTS bots. | Wave 3 Complete (`HandEvaluator3`, `MeldSolver`, Callbreak bots) |
| **Dart Port** | `@dart-port` | `packages/dart/patii_engine` + offline `LocalTableEngine`, 100% parity with TS fixtures. | Wave 5 |
| **Admin** | `@admin` | `apps/admin`: Next.js 15 App Router, shadcn/ui, TanStack Table, Admin REST integrations. | Wave 4 (Next) |
| **Verifier** | `@verifier` | Reviews diffs, runs tests, checks PRD acceptance criteria, reports defects. | Active |
| **Security Auditor** | `@security-auditor` | Audit for hidden-card leaks, wallet double-spend, auth vulnerabilities, rate limits, anti-cheat (PRD 7.5). | Active |

---

## 2. Master Wave Roadmap & Gate Status

- [x] **Wave 1 — Foundation (@architect only)**
  - Monorepo setup, configs, Prisma schema, protocol + Dart codegen, Card model, seeded shuffle, GameModule interface, table shell API contract.
  - Acceptance Gate: `pnpm turbo build test lint` green, `flutter analyze` green, docker compose infra ready, migration schema generated.
- [x] **Wave 2 — First Playable Vertical Slice (Parallel)**
  - Callbreak engine with all toggles + fixtures + simulation harness;
  - Server core (auth, double-entry wallet with holds/settlement, table runtime with optimistic versioning, timers, reconnect, Socket.IO gateway, matchmaking with 8s bot fill);
  - Easy/Medium Callbreak bots;
  - Mobile app shell + landscape Callbreak table UI with English and Nepali localization.
  - Acceptance Gate: Full Callbreak game flow, seat state transitions, wallet hold and settlement, all fixtures passing, `flutter analyze` and `flutter test` green.
- [x] **Wave 3 — Remaining Games (Parallel)**
  - Shared utilities: `HandEvaluator3` (all 3-card combinations) and `MeldSolver` (sequences, sets, tunnelas, dublees).
  - All remaining 7 game engines:
    1. **Teen Patti**: Blind / chaal betting, fold/pack, side show, show, variants.
    2. **Kitti**: 9 cards split into 3 hands, 3 shows evaluation, Salami bonus, Kitti carryover.
    3. **Dhumbal**: Draw/discard sets and runs, Jhyap call validation (sum <= 5), failure penalty 25, 100-point elimination.
    4. **Jutpatti**: Pair matching with cut jokers, even-count declare validation.
    5. **Nepali Rummy**: 10-card rummy, pure sequences, sets, deadwood counting.
    6. **Joker Rummy (Paplu)**: 13-card 2-deck rummy with Tiplu, Paplu, Nichlu, and Marriage sequence bonuses (50 pts).
    7. **Marriage**: 21 cards, 3 decks, seeing maal phase, finishing phase, maal points, tunnela bonus, settlement formula $P_i = T + w_i - n \cdot S_i$ for Classic, Murder, and Kidnap modes.
  - Acceptance Gate: Every PRD scoring example passes as a fixture test; 22 unit tests passing in game engine; all 8 games verified.
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
