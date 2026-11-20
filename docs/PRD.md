Patii — Product Requirements Document (v1)

Nov 15, 2026 · @kakasi

1. Overview

Patii is a free, multiplayer Nepali card game app with eight classic games in one place, played for virtual coins against friends, strangers or bots. It runs on Android and iOS from one Flutter codebase, backed by an authoritative NestJS game server.

Problem. Nepali players juggle several apps (Callbreak in one, Marriage in another, Teen Patti in a third). Existing all-in-one apps are mostly offline-only, have weak bots, or lack private tables with house rules.

Vision. The one app a Nepali family or friend group opens during Dashain and Tihar: every popular game, the rules they actually play at home, private rooms with a code, and bots that fill empty seats so a table never waits.

Goals (v1)

Ship 8 games with complete, configurable rules: Callbreak, Marriage, Teen Patti, Kitti, Dhumbal, Jutpatti, Nepali Rummy, Joker Rummy.

Real-time multiplayer with quick match, private rooms and offline-vs-bots.

Bots at three difficulty levels that play legal, human-like moves in under 1 second.

A virtual coin economy that keeps players returning daily, with ad placements reserved for later.

Nepali and English interface.

Non-goals (v1)

Real-money play, cash-out, or any coin-to-cash conversion.

Voice chat, tournaments, clubs (planned for v2).

Web or desktop clients.

LLM-driven bot moves.

Target users



| Segment | Need | Key feature |

| --- | --- | --- |

| Nepali adults 18–45 in Nepal | Quick games on a phone between work | Quick match, short games (Kitti, Dhumbal) |

| Families during festivals | Play together across cities | Private rooms with a code, house rules |

| Nepali diaspora (Gulf, Malaysia, US, UK, Australia) | Play with family back home | Online private rooms, low-bandwidth mode |

| Solo players | Practise or pass time | Offline vs bots |



Success metrics (first 6 months after launch)



| Metric | Target |

| --- | --- |

| Installs | 100,000 |

| Day-1 / Day-7 / Day-30 retention | 40% / 20% / 10% |

| Average session length | 20 minutes |

| Matchmaking wait (p95) | under 10 seconds, bots fill after 8 s |

| Crash-free sessions | 99.5% |

| Server move latency (p95, in Nepal) | under 250 ms |



2. Scope and product decisions

All decisions below are confirmed by the product owner and are fixed for v1.



| Area | Decision |

| --- | --- |

| App name | Patii (package ID com.patii.app) |

| Platforms | Android + iOS, one Flutter codebase |

| Languages | English (default) and Nepali (नेपाली), switchable in Settings |

| Currency | Virtual coins only. Never purchasable for cash-out, never convertible to money |

| Monetisation | v1: none. v1.x: rewarded video + interstitial ads, optional coin packs (IAP) |

| Game modes | Quick match (public), Private room (6-character code), Offline vs bots |

| Bots | Fill empty seats after 8 s in quick match; host adds bots in private rooms; all seats in offline |

| Disconnects | 30 s grace, then a bot plays the seat; the player can rejoin and take it back |

| Social | Friends list, invite to room, quick-chat phrases, emoji reactions. No voice, no free-text chat in v1 |

| Progression | XP + levels, per-game stats, weekly and all-time leaderboards |

| Login | Google, phone OTP, guest (guest upgrades to a full account without losing coins) |

| Rules | Every researched variant is implemented as a toggle. Quick match uses one fixed standard ruleset per game; private rooms expose all toggles |

| Admin | Next.js web admin panel in the same monorepo |

| Out of v1 | Tournaments, clubs, voice chat, free-text chat, web client, real money |



The 8 games



| # | Game | Players | Deck | Family (engine) | Typical length |

| --- | --- | --- | --- | --- | --- |

| 1 | Callbreak | 4 | 52 | Trick-taking | 5 deals, ~10 min |

| 2 | Marriage | 2–5 | 3 × 52 = 156 | Rummy (draw/discard, melds) | ~5 min per deal |

| 3 | Teen Patti (Flush) | 2–7 | 52 (+ variants) | 3-card hand / betting | ~1–2 min per hand |

| 4 | Kitti | 2–5 | 52 | 3-card hand / arrangement | ~2 min per deal |

| 5 | Dhumbal (Jhyap) | 2–5 | 52 (+2 jokers optional) | Draw/discard, lowest total | ~3 min per round |

| 6 | Jutpatti | 2–5 | 52 (+ joker rank) | Draw/discard, pairs | ~2 min per round |

| 7 | Nepali Rummy | 2–5 | 52 or 2 × 52 | Rummy (draw/discard, melds) | ~4 min per round |

| 8 | Joker Rummy (Paplu) | 2–6 | 2 × 52 + printed jokers | Rummy (draw/discard, melds) | ~5 min per round |



3. System architecture

The server is authoritative: clients send intents ("play 7♠", "bid 4"), the server validates them against the shared rules engine, and broadcasts each player only the state they are allowed to see.

system architecture · 2 clients, 1 server, 3 stores

One TypeScript rules package runs on the server; the Flutter app also gets a Dart port of the rules for offline play (see 3.3).

3.1 Tech stack



| Layer | Choice |

| --- | --- |

| Monorepo | Turborepo + pnpm workspaces; Melos for Dart packages |

| Mobile | Flutter 3.x (stable), Dart 3, Riverpod 2 (code-gen), go_router, socket_io_client, freezed + json_serializable, flame or custom widgets for card animation, easy_localization |

| Server | NestJS 10, Socket.IO gateway with Redis adapter, class-validator, Prisma ORM |

| Rules engine | TypeScript package @patii/game-engine, pure functions, zero I/O, 100% unit-tested |

| Bots | @patii/bots package, run in Node worker threads inside the server (separate process when scaled) |

| Database | PostgreSQL 16 |

| Cache / realtime state | Redis 7 (table state, matchmaking queues, Socket.IO adapter, rate limits) |

| Auth | Firebase Auth (phone OTP, Google) → server-issued JWT; guest = device-bound account |

| Push | Firebase Cloud Messaging |

| Admin | Next.js 15 (App Router), shadcn/ui, TanStack Table |

| Shared contracts | @patii/protocol: Zod schemas for every socket event, generated to Dart with a codegen script |

| Hosting | Docker Compose on a VPS (v1), Nginx + Let's Encrypt; GitHub Actions CI |

| Monitoring | Sentry (server + app), Firebase Crashlytics, Prometheus + Grafana |



3.2 Monorepo layout

patii/├─ apps/│  ├─ mobile/            # Flutter app (package.json wrapper exposes build/test/lint to Turbo)│  ├─ server/            # NestJS game + API server│  └─ admin/             # Next.js admin panel├─ packages/│  ├─ game-engine/       # TS rules for all 8 games (pure, deterministic)│  ├─ bots/              # TS bot strategies (heuristic + ISMCTS)│  ├─ protocol/          # Zod event schemas + generated Dart models│  ├─ db/                # Prisma schema, migrations, seed│  ├─ config/            # shared eslint, tsconfig, prettier│  └─ dart/│     ├─ patii_engine/   # Dart port of game-engine (offline mode)│     └─ patii_protocol/ # generated Dart event models├─ infra/                # docker-compose, nginx, grafana├─ turbo.json├─ pnpm-workspace.yaml└─ melos.yaml

3.3 Rules engine parity (online vs offline)

The TypeScript engine is the single source of truth. The Dart port exists only for offline play.

A shared fixture suite (packages/game-engine/fixtures/*.json: seed, moves, expected state and scores) runs in both the TS and Dart test suites in CI. Any mismatch fails the build.

Online games never trust client rule checks; the client only uses them to grey out illegal cards.

3.4 Server modules (NestJS)



| Module | Responsibility |

| --- | --- |

| AuthModule | Verify Firebase ID token, issue JWT + refresh token, guest accounts, account linking |

| UsersModule | Profile, avatar, language, stats, XP/level |

| WalletModule | Coin balance, ledger (double-entry), daily bonus, rewards |

| MatchmakingModule | Per game+stake queues in Redis, bot fill after 8 s |

| RoomsModule | Private rooms, codes, host controls, rule toggles |

| TableModule | Table runtime: state machine, turn timers, move validation via game-engine, persistence of results |

| BotsModule | Bot seat controller, difficulty, worker pool |

| SocialModule | Friends, invites, quick-chat, emoji |

| LeaderboardModule | Redis sorted sets, weekly reset job |

| AdminModule | Admin REST endpoints, audit log |

| NotificationsModule | FCM push (friend invites, daily bonus ready) |



4. Core game framework

Every game implements one interface, so tables, timers, bots, replays and scoring are written once and reused by all eight games.

4.1 Card model

Card = { suit: 'S'|'H'|'D'|'C'|'X', rank: 1..13 | 0, deck: 0..2, id: string }. X + rank 0 = printed joker. deck distinguishes identical cards in multi-deck games (Marriage tunnela/dublee).

id is unique per physical card ("QS1" = queen of spades, deck 1). The server sends ids, never positions, so a client cannot infer stock order.

Rank order is configurable per game: Ace high (Callbreak, Teen Patti, Kitti), Ace both ends (Marriage, Rummy), Ace low only (Dhumbal).

4.2 Game module interface (@patii/game-engine)

interface GameModule<S, M, R> {  id: GameId;                       // 'callbreak' | 'marriage' | ...  defaultRules: R;                  // standard ruleset (quick match)  validateRules(r: R): R;           // clamp toggles to legal combos  setup(players: PlayerId[], rules: R, seed: string): S;  legalMoves(s: S, p: PlayerId): M[];  applyMove(s: S, p: PlayerId, m: M): S;   // throws IllegalMove  currentActor(s: S): PlayerId | null;  isRoundOver(s: S): boolean;  scoreRound(s: S): RoundResult;  isGameOver(s: S): boolean;  viewFor(s: S, p: PlayerId | 'spectator'): PublicView; // hides hidden info  autoMove(s: S, p: PlayerId): M;   // timeout fallback (safe, legal)}

All functions are pure and deterministic given the seed. This gives free replays, server-side audits and identical results in tests.

viewFor is the only path from state to network. Hidden cards are never serialised to other players.

4.3 Shuffle and randomness

Server shuffles with Fisher–Yates driven by a CSPRNG (crypto.randomBytes). The 256-bit seed is stored with the match for audit.

Commit-reveal fairness: the server sends sha256(seed) at deal; after the match it reveals the seed so anyone can verify the deal.

Offline mode uses a Dart Random.secure() seed.

4.4 Table lifecycle



| State | Enters when | Leaves to |

| --- | --- | --- |

| WAITING | Table created | READY when all seats filled (humans or bots) |

| READY | Seats full | DEALING after a 3 s countdown |

| DEALING | Countdown ends | PLAYING once cards are sent (deal animation ~2 s) |

| PLAYING | Deal done | ROUND_END when isRoundOver |

| ROUND_END | Round over | DEALING (next round) or GAME_END when isGameOver |

| GAME_END | Game over | SETTLED after coins are paid out (atomic DB transaction) |

| SETTLED | Payout done | READY if all agree to rematch within 15 s, else closed |

| ABANDONED | All humans left | Closed; stakes refunded if no round finished |



4.5 Turn timers



| Game | Turn time | Extra time bank (per game) |

| --- | --- | --- |

| Callbreak (bid / play) | 10 s / 10 s | 20 s |

| Marriage | 20 s | 40 s |

| Teen Patti | 15 s | 15 s |

| Kitti (arrange all 9 cards) | 45 s | 15 s |

| Dhumbal | 12 s | 20 s |

| Jutpatti | 10 s | 20 s |

| Nepali Rummy / Joker Rummy | 20 s | 40 s |



On timeout the server plays autoMove (lowest-risk legal move: draw from stock + discard the highest-value deadwood; fold in Teen Patti if a bet is required; auto-arrange in Kitti).

Three consecutive timeouts mark the player away: a bot plays for them until they tap "I'm back".

4.6 Disconnects and reconnects

Socket drops → seat marked DISCONNECTED; the turn timer keeps running.

Within 30 s the client reconnects with its JWT + tableId and receives a full viewFor snapshot.

After 30 s a bot (Medium) takes over the seat; coins and results still belong to the player.

The player can rejoin at any time before GAME_END and resumes control on their next turn.

Leaving deliberately in a staked game forfeits the stake (shown in a confirm dialog).

4.7 Persistence

Live state lives in Redis (table:{id}), written after every move with optimistic versioning (version field) so two moves can never apply at once.

Each move is appended to a Redis stream; at GAME_END the full move log + seed + results is written to Postgres (Match, MatchPlayer) and the Redis keys expire after 1 hour.

A server restart recovers live tables from Redis and resumes timers.

5. Game rules

Each game has a standard ruleset (used in quick match, marked default) and toggles that a private-room host can change. Rules vary between Nepali households, so every toggle below must be a typed field in that game's Rules object, validated by validateRules.

Global defaults for all games: play and dealing go counter-clockwise (Nepali custom; toggle to clockwise), the first dealer is random, and the deal then passes to the next player in play direction.

5.1 Callbreak (Call Bridge)

Setup. 4 players, one 52-card deck, 13 cards each. Rank A high → 2 low. Spades are permanent trumps.

Redeal. Default: redeal if any player holds no spade. Toggle: also redeal if a player holds no face card (J, Q, K, A).

Bidding ("call"). Starting right of the dealer (in play direction), each player calls the tricks they expect to win. Default: call 1–8. Calls are public.

Play.

The player after the dealer leads the first trick; the winner of each trick leads the next.

Must follow the led suit if able.

Default (must overtake): when following suit, must play a card that beats the current winning card if able.

If void in the led suit, must play a spade; if a spade is already in the trick, must play a higher spade if able. If unable to beat it, play any card.

Highest spade wins the trick; if no spade, highest card of the led suit wins.

Scoring (default, Nepali app style). Make the call (tricks ≥ call) → +call, plus 0.1 per extra trick. Miss the call → −call. Example: call 4, take 6 → +4.2; take 3 → −4.

Game length. Default: 5 deals; highest cumulative score wins. Ties are shared.

Toggles.



| Toggle | Options |

| --- | --- |

| Scoring style | Nepali (default) · Pagat classic: success = exactly call or call+1, minimum call 2, any call 8+ that succeeds scores 13 |

| Max call | 8 (default) · 13 |

| Must overtake when following | On (default) · Off |

| No spade lead on first trick | Off (default) · On |

| No wasting trumps (no under-trump when a higher spade is down, unless forced) | Off (default) · On |

| Minimum total calls | Off (default) · 10 (redeal if the four calls sum to 9 or less) |

| Number of deals | 5 (default) · 3 · 10 |

| Redeal if no face card | Off (default) · On |



Coin settlement. Ranked payout from the pot: 1st 50%, 2nd 30%, 3rd 20%, 4th 0 (after rake).

5.2 Marriage

Setup. 2–5 players (quick match: 4). Three 52-card decks (156 cards) plus 0–3 printed jokers ("Man" cards, toggle). 21 cards each. The next card is turned up to start the discard pile; the rest is the stock.

Terms. Assume the maal (cut joker) is J♣:



| Term | Cards | Wild? | Notes |

| --- | --- | --- | --- |

| Tiplu | J♣ (the remaining copies) | Yes | The maal card itself |

| Poplu | Q♣ (one above, same suit) | Yes |  |

| Jhiplu | 10♣ (one below, same suit) | Yes | Ace wraps: below 2 is A, above K is A |

| Alter | J♠ (same rank, same colour, other suit) | Yes | Carries points only if the Alter toggle is on |

| Ordinary jokers | J♦, J♥ (and J♠ when Alter is off) | Yes | No points |

| Man card | Printed joker | Yes, after seeing the maal | Toggle 0–3 in the pack |

| Marriage | Jhiplu + Tiplu + Poplu in sequence (10♣ J♣ Q♣) | — | High-value combination |



Combinations (always exactly 3 cards).

Tunnela: three identical cards (same rank and suit), e.g. 6♥ 6♥ 6♥. Jokers can never make a tunnela.

Pure sequence: three consecutive cards of one suit, no wild. Ace can be low (A-2-3) or high (Q-K-A), never in the middle.

Dirty sequence: a sequence completed with one or two wild cards.

Trial (set): three of one rank in three different suits. Two same-suit copies + a third suit is invalid.

Dirty trial: a trial completed with wild cards.

Dublee: a pair of identical cards (same rank and suit). Wilds can never make a dublee.

Turn. Draw the top stock card or the top discard, then discard one card. You may not discard the card you just took from the discard pile. On the first turn the player may take the turned-up card.

Phase 1 — seeing the maal. A player shows 3 pure combinations (pure sequences and/or tunnelas, any mix) or 7 dublees. The first player to show picks a random card from the middle of the stock face down; that card is the maal (tiplu). Every later player who shows 3 pure combinations or 7 dublees may see it. Tunnelas held in the opening deal may be exposed immediately (they score only if exposed at the start and the player later sees the maal).

Phase 2 — finishing. After seeing, the player may use all wild cards. To finish ("declare"), after drawing they arrange the remaining cards into 4 more valid combinations (any type, wilds allowed), lay everything down and discard the 22nd card. Dublee players finish with 8 dublees (16 cards); the other 5 cards are unrestricted. A player may chain both steps in one turn (draw → show 3 pure → see maal → finish).

Restrictions after seeing. A player who has seen the maal may not take a wild card from the discard pile. A dublee player who has seen may take a discard only if it completes the 8th dublee.

Stock runs out. Default: shuffle the discards (except the top card) into a new stock above the hidden maal. Toggle: the hand is void (no payments).

Maal points (counted for every card in the final hand, each card counted once).



| Item | Single | Double | Triple |

| --- | --- | --- | --- |

| Poplu or Jhiplu | 2 | 5 | 10 |

| Tiplu | 3 | 8 | — (one copy is the hidden maal) |

| Alter (if toggle on) | 5 | 15 | 25 |

| Marriage (jhiplu-tiplu-poplu held together) | 10 | 30 | — |

| Man card (if enabled) | 0 by default; toggle 5 each |  |  |



A marriage scores instead of its three individual cards. Tunnela bonus (only if exposed at the start and the player saw the maal): 5 per ordinary tunnela, 10 for a tunnela of ordinary-joker cards, 15 for a poplu or jhiplu tunnela, 30 for an alter tunnela.

Settlement (standard formula). Let n = players, Sᵢ = player i's maal points, T = ΣS, and wᵢ = 3 if player i saw the maal or 10 if not, +5 if the winner finished with 8 dublees. Each non-winner pays the winner:

P_i = T + w_i - n \cdot S_i

A negative Pᵢ means the winner pays player i. Coins = points × the table's point rate.

Modes (toggle, default Classic).



| Mode | Players who did not see the maal |

| --- | --- |

| Classic | Keep their maal points |

| Murder | Their maal points become 0 |

| Kidnap | Their maal points become 0 and are added to the winner's S |



Other toggles. Number of Man cards (0–3), Alter on/off, dublee route on/off, stock-out reshuffle or void, unseen penalty (10 default, 5–20), seen penalty (3 default), play direction.

5.3 Teen Patti (Flush)

Setup. 2–7 players (quick match: 5), one 52-card deck, 3 cards each face down. Every player posts the boot (= table stake) into the pot.

Hand ranking (high → low).



| Rank | Hand | Example | Tie-break |

| --- | --- | --- | --- |

| 1 | Trail (three of a kind) | A A A | Higher rank |

| 2 | Pure sequence (straight flush) | Q♥ K♥ A♥ | A-K-Q highest, then A-2-3, then K-Q-J … |

| 3 | Sequence (straight) | 4♠ 5♥ 6♣ | Same as above |

| 4 | Color (flush) | 2♦ 7♦ J♦ | Highest card, then next, then next |

| 5 | Pair | 9 9 K | Pair rank, then kicker |

| 6 | High card | A 10 4 | Highest card, then next |



Identical hands split the pot. Suits never break ties.

Betting.

Each player chooses to play blind (cards unseen) or seen (look at cards) at any time.

Current stake starts at the boot. Blind players bet 1× to 2× the current stake; seen players bet 2× to 4× ("chaal"). Raising sets the new stake.

Pack (fold) at any time; the player loses what they put in.

Side show: a seen player may ask the previous seen player to compare privately. That player may accept or deny; on accept, the weaker hand must pack (tie: the requester packs).

Show: when only 2 players remain, either may pay the current bet to force a show. A blind player may only show against a blind player.

Limits (default): blind limit 4 rounds, chaal limit = 128 × boot, pot limit = 1,024 × boot; reaching the pot limit forces a show among remaining players.

Variants (toggle, default Classic).



| Variant | Rule change |

| --- | --- |

| Classic | As above |

| Muflis (lowball) | Rankings invert: lowest hand wins; A-2-4 different suits best |

| AK47 | All Aces, Kings, 4s and 7s are wild |

| Joker | After the deal one card is turned up; all cards of that rank are wild |

| Low joker | Each player's lowest card (both, if a pair) is wild |

| 999 | Cards read as a 3-digit number (10/J/Q/K = 0, A = 1), arranged for the best value; closest to 999 wins (5, 9, A → 951) |

| 2-3-5 kills Trail | 2-3-5 of mixed suits beats a trail (only against a trail) |



Coin settlement. Winner takes the pot minus rake.

5.4 Kitti (9-card)

Setup. 2–5 players (quick match: 4), one 52-card deck, 9 cards each. Every player posts the boot.

Arrange. Each player splits 9 cards into 3 hands of 3 and orders them (1st, 2nd, 3rd show) within the arrange timer. Players may fold before the first show and lose only the boot.

Ranking. Same as Teen Patti (Trail > Pure run > Run > Color > Pair > High card). Toggle: "2-3-5" of different suits (Kitti) ranks above Trail.

Play. Three shows. In each, all active players reveal that hand simultaneously; the best hand wins the show. Equal best hands → the show is void.

Winning. Default: the first player to win 2 shows wins the pot. If nobody wins 2 shows (e.g. three different winners, or void shows), the deal is Kitti: the pot carries over, everyone keeps their seat and a new deal follows (no new boot). Winning all 3 shows is Salami: each opponent pays an extra boot to the winner.

Toggles. Win rule: any 2 shows (default) · 2 consecutive shows; Salami bonus on/off; 2-3-5 rule on/off; maximum Kitti carry-overs before the pot is split (default 3).

5.5 Dhumbal (Jhyap)

Setup. 2–5 players (quick match: 4), one 52-card deck (toggle: + 2 printed jokers worth 0), 5 cards each. The top stock card starts the discard pile.

Card values (default). A = 1, 2–10 = face value, J = 11, Q = 12, K = 13. Toggle: Nepali-classic values (J = 0, Q = K = 10).

Turn (discard first, then draw).

Discard one of: a single card; a set of 2+ same rank; or a run of 3+ consecutive cards of one suit (Ace low only; a joker may fill a gap).

Then take one card: the top of the stock, or any one card the previous player just discarded.

If the stock runs out, shuffle the discards (except the last discard) into a new stock.

Calling Jhyap. At the start of their turn, a player whose hand totals ≤ 5 (default; toggle 5–10) may call Jhyap. All hands are revealed.

Success (caller strictly lowest): caller scores 0; every other player adds their hand total.

Fail (someone equal or lower): caller adds 25 penalty + their hand total; others score 0.

Game end. A player whose cumulative score exceeds 100 is out (exactly 100 stays in). Last player remaining wins the pot. Toggle: Single round quick mode — lowest hand at the call wins the pot outright.

Toggles. Call threshold (5–10), fail penalty (25 default, 20–30), elimination score (100 default, 50–200), jokers on/off, card values classic/app, single-round mode.

5.6 Jutpatti

Setup. 2–5 players (quick match: 4), one 52-card deck. Default 9 cards each (toggle 5 / 7 / 9 / 11). After the deal the top stock card is turned face up beside the stock: every card of that rank is a joker for this round.

Pairs. Two cards of the same rank (any suits), or a joker with any card, or two jokers.

Turn. Take the top stock card or the previous player's discard. If the hand (now an even count) is all pairs, declare and win. Otherwise discard one card. The first player's first turn must draw from the stock.

Scoring. Default: the winner takes the pot. Toggle Points mode: each loser pays the winner 1 point per unpaired card in their best arrangement.

Toggles. Hand size, joker card on/off, points mode, play direction.

5.7 Nepali Rummy (10-card)

Setup. 2–5 players (quick match: 4). One 52-card deck for 2–4 players, two decks for 5. Default 10 cards each. One card from the stock is turned face up under it as the cut joker: every card of that rank is wild. Toggle: add printed jokers (wild).

Melds.

Pure sequence: 3+ consecutive cards of one suit, no wild.

Sequence: 3+ consecutive cards of one suit, wilds allowed.

Set: 3 or 4 cards of one rank in different suits, wilds allowed.

Ace is low (A-2-3) or high (Q-K-A), never wrapping (K-A-2 invalid).

Turn. Draw from the stock or the top discard, then discard one card.

Declare. After drawing, a player whose cards form valid melds with at least one pure sequence, discards the last card face down and declares. The server validates; an invalid declare scores the maximum penalty (80) and the round continues.

Scoring (points rummy). Losers count unmelded cards: 2–10 face value, J/Q/K/A = 10, wilds 0. A loser with no pure sequence counts all cards. Maximum 80 per round. Drop: before first draw costs 20, later costs 40.

Game modes. Default: Pool 101 — cumulative points; a player reaching 101 is out; the last player wins the pot. Toggles: Pool 201; Points (single round, each loser pays points × point rate to the winner); Deals (fixed 2 or 3 deals, lowest total wins).

5.8 Joker Rummy (Paplu)

Setup. 2–6 players (quick match: 4). Two 52-card decks + 4 printed jokers (toggle 2). 13 cards each. A cut joker is turned up from the stock.

Wild cards. All printed jokers, all cards of the cut-joker rank, and the special cards:



| Term | Card (cut joker 7♥) | Bonus when held at round end |

| --- | --- | --- |

| Tiplu | 7♥ | 10 from each opponent |

| Paplu (one above) | 8♥ | 10 from each opponent (25 for two) |

| Nichlu (one below) | 6♥ | 10 from each opponent |

| Marriage (Nichlu + Tiplu + Paplu in sequence) | 6♥ 7♥ 8♥ | 50 from each opponent (instead of the three single bonuses) |



Melds and declare. Same meld types as 5.7. A valid declaration needs at least 2 sequences, one of them pure; all 13 cards melded, 14th discarded.

Scoring. Losers count unmelded cards as in 5.7 (max 80; first drop 20, middle drop 40, wrong declare 80). Paplu bonuses are paid by every player to the holder regardless of who declares, but only by holders who have a pure sequence (toggle). Default mode: Points (single deal), toggles Pool 101/201 and Deals.

Toggles. Printed jokers 2/4, paplu bonuses on/off, bonus values, requirement "pure sequence to claim bonus", game mode.

6. Bot AI

Bots use our own algorithms, not an LLM API: they must answer in under 1 second, always play legal moves, cost nothing per move, and run offline on the phone.

6.1 Principles

No cheating. A bot receives only viewFor(state, botSeat) — the same information a human in that seat has. It never sees hidden cards or the stock order. This is enforced by the API: Bot.decide(view: PublicView): Move.

Human pacing. Bots wait a random 0.8–2.5 s before moving (longer for big decisions) so tables feel natural.

Interface. interface BotStrategy<V, M> { decide(view: V, rng: Rng, budgetMs: number): M }. One strategy per game × difficulty.

Fallback. If a strategy throws or exceeds its time budget, the bot plays autoMove.

Bots in coin games. Bot seats in quick match play with house coins; their wins and losses go to a HOUSE_BOT ledger account so the economy stays auditable.

6.2 Difficulty levels



| Level | Used in | Method |

| --- | --- | --- |

| Easy | Offline "Easy", new players' first 5 games | Heuristic with 25% random legal moves, no card counting |

| Medium | Quick-match seat fill, disconnect takeover, default offline | Full heuristic with card counting |

| Hard | Offline "Hard", private-room option | Heuristic + determinized Monte Carlo search (ISMCTS) where the game has deep decisions |



ISMCTS in one paragraph. The bot samples many possible deals of the unseen cards that are consistent with everything it has seen (cards played, suits players were void in, discards picked up). For each sample it plays the game forward with fast heuristic rollouts and records which of its legal moves won most. It picks the move with the best average result. Budget: 300 ms or 2,000 iterations, whichever comes first, in a worker thread.

6.3 Per-game strategy



| Game | Easy / Medium heuristics | Hard |

| --- | --- | --- |

| Callbreak | Bid: count sure tricks (A, K with 2+ cover, Q with 3+), spade length − 3, voids/singletons with spades; round down. Play: win the trick cheaply when still short of the call; dump high cards once the call is met; track voids and remaining spades | ISMCTS on every card play; bid = heuristic +/− 1 chosen by 200 simulated deals |

| Marriage | Rank discards by "meld potential" (cards that are part of near-sequences or pairs are kept); go for dublees when the opening hand has 5+ dublees; never discard a known wild after seeing; prefer stock unless the discard completes a combination | Same + opponent modelling: avoid discarding cards adjacent to the previous player's pickups; ISMCTS for the discard choice in the final phase |

| Teen Patti | Hand strength score 0–100 from rank tables; bet/raise/fold thresholds by score, players left and pot odds; bluff blind 10% (Medium) | Monte Carlo equity vs remaining players (1,000 random opponent hands), bet sizing by equity and pot odds, side-show when equity > 60% |

| Kitti | Exhaustive search: all 1,680 ways to split 9 cards into 3 ordered hands, scored by expected show wins against random hands | Same search, scored against hands simulated from the unseen 43 cards; fold when win chance < 20% |

| Dhumbal | Discard the highest-value combination; pick up a discard only if it lowers the hand or makes a set/run next turn; call Jhyap when total ≤ threshold and estimated opponent minimum > own total | Estimate opponents' totals from cards taken and hand sizes; call only when P(strictly lowest) > 70% |

| Jutpatti | Keep pairs and jokers; discard the card whose rank has the most copies already seen; take a discard only if it makes a pair | Same + avoid discarding ranks the next player has picked up before |

| Nepali Rummy / Joker Rummy | Greedy meld finder (maximise melded cards, pure sequence first), discard the highest-value deadwood not adjacent to a near-meld; drop when hand value is high and no pure sequence is near | Lookahead on draw choice (top discard vs expected stock value) + opponent danger model for discards |



6.4 Shared bot utilities (@patii/bots/common)

MeldSolver: finds the best arrangement of a hand into sequences/sets/tunnelas/dublees with wilds (used by Marriage, both Rummies, Jutpatti, and by the server's declare validation).

HandEvaluator3: ranks 3-card hands for every Teen Patti variant (lookup table of all 22,100 combinations, precomputed).

CardTracker: remembers played/discarded/picked cards and inferred voids per opponent.

Determinizer: samples hidden hands consistent with CardTracker constraints.

6.5 Optional AI-API features (v2, off by default)

An LLM may be added later for personality only, never for moves: bot chat lines in Nepali/English ("Ramro khel!"), and a "Why did the bot play that?" explainer in offline practice. Behind a feature flag and a per-day call budget.

6.6 Quality bar

Medium bot beats Easy bot in at least 65% of 1,000 simulated Callbreak games.

Hard bot beats Medium in at least 58%.

0 illegal moves across 100,000 simulated games per title (CI job).

7. Multiplayer and networking

All real-time play runs over one Socket.IO connection per client (namespace /game), JSON payloads validated by Zod on the server; REST is used for everything outside a table.

7.1 Matchmaking (quick match)

Player picks a game + stake tier and taps Play. Server checks the balance covers the entry and reserves it (wallet hold).

Player joins Redis queue mm:{game}:{tier}. A matcher runs every 500 ms, grouping players by tier and similar rating (±200 Elo, widening by 100 every 3 s).

If a table is not full after 8 s, Medium bots fill the empty seats.

Table created → table:joined sent to each player → READY countdown.

Leaving the queue releases the hold.

7.2 Private rooms

Host creates a room: game, rules toggles, stake (0 = friendly, no coins), seats, bot difficulty, turn timer.

Server returns a 6-character code (no 0/O/1/I) and a deep link patii://room/ABC123 (also https://patii.app/r/ABC123).

Host can kick, swap seats, add/remove bots, and start when 2+ seats are filled (game minimum).

Rooms expire after 30 min idle.

7.3 Socket events



| Direction | Event | Payload (summary) |

| --- | --- | --- |

| C → S | queue:join / queue:leave | gameId, tier |

| C → S | room:create / room:join / room:leave | rules, stake / code |

| C → S | room:kick, room:addBot, room:start | seat / difficulty |

| C → S | table:move | tableId, version, move (game-specific, Zod-validated) |

| C → S | table:resync | tableId |

| C → S | table:chat | phraseId or emojiId |

| C → S | table:rematch | tableId, accept |

| S → C | queue:matched | tableId |

| S → C | table:state | full PublicView (on join, reconnect, resync) |

| S → C | table:event | version, event (dealt, moved, trickWon, maalSeen, roundScored …), patch for the view |

| S → C | table:turn | seat, deadline (server epoch ms), legal move hints |

| S → C | table:result | per-seat points, coin delta, XP gained |

| S → C | table:chat | seat, phraseId / emojiId |

| S → C | error | code (ILLEGAL_MOVE, NOT_YOUR_TURN, STALE_VERSION, INSUFFICIENT_COINS …) |



Every table:event carries a monotonically increasing version. A client that sees a gap sends table:resync and receives a full table:state.

Moves carry the client's last version; the server rejects stale moves with STALE_VERSION.

Deadlines are sent as absolute server time; the client corrects for clock skew measured at connect.

7.4 Scaling

v1: 1 VPS (8 vCPU, 16 GB) running 2–4 server containers behind Nginx with sticky sessions, Socket.IO Redis adapter for cross-instance broadcasts.

A table is owned by exactly one instance (Redis lock table:{id}:owner with 10 s TTL, renewed every 3 s). If the owner dies, another instance takes the lock and resumes from Redis.

Target: 5,000 concurrent players and 1,500 live tables on that box; horizontal scale by adding instances.

7.5 Anti-cheat and fair play

Server-authoritative state; clients receive only their own hidden cards.

Card ids are opaque and re-randomised per deal so they reveal nothing about deck order.

Rate limit: 10 socket messages/s per client; repeated illegal moves → temporary kick.

Collusion signals logged for review: same device/IP at one table, repeated soft-play between the same accounts, chip dumping (large one-way coin flows). Players from the same IP are not matched together in quick match.

Commit-reveal shuffle seed (section 4.3) lets any player verify a deal after the game.

Root/jailbreak and emulator detection flags the account (not a block).

8. Coin economy

Coins are a closed, virtual currency: earned by playing and daily rewards, spent on table entries, never cashed out. A 5% rake on staked tables is the main coin sink that keeps balances from inflating.

8.1 Coin sources



| Source | Amount | Limit |

| --- | --- | --- |

| Signup bonus | 10,000 | Once per account (guest upgrade does not repeat it) |

| Daily login streak | Day 1: 500 · 2: 750 · 3: 1,000 · 4: 1,250 · 5: 1,500 · 6: 2,000 · 7: 3,000 | Streak resets if a day is missed |

| Hourly free chest | 200 | Every 4 hours |

| Bankrupt rescue | Top up to 2,000 | When balance < 500, max 2 per day |

| Level-up | 500 × new level (cap 10,000) | Per level |

| First win of the day per game | 300 | 8 games → up to 2,400/day |

| Invite a friend who reaches level 3 | 5,000 | Max 10 friends |

| v1.x: rewarded video ad | 500 | 5 per day |

| v1.x: coin packs (IAP) | e.g. 50,000 / 150,000 / 500,000 | Coins only; no cash-out ever |



8.2 Table stakes (quick match tiers)



| Tier | Entry / boot / point rate | Unlocks at | Minimum balance to join |

| --- | --- | --- | --- |

| Beginner | 100 | Level 1 | 1,000 |

| Bronze | 500 | Level 3 | 5,000 |

| Silver | 2,000 | Level 8 | 20,000 |

| Gold | 10,000 | Level 15 | 100,000 |

| Diamond | 50,000 | Level 25 | 500,000 |



How the tier value is used per game:

Callbreak, Kitti, Dhumbal, Jutpatti, Rummy (pool/deals): entry fee into a pot; payout as defined in section 5.

Teen Patti: boot = tier value; the minimum balance protects against running out mid-hand (a player who cannot cover a bet must show or pack).

Marriage, Rummy/Joker Rummy (points modes): point rate = tier value ÷ 10 coins per point; loss per deal capped at 30 × tier value.

8.3 Rake and sinks

5% of every pot or winner payout (0% at Beginner tier).

Cosmetics (v1.x): card backs, table themes (Dashain, Tihar, Himalaya), avatar frames.

Private rooms with stakes > 0 charge the same rake; friendly rooms (stake 0) are free and give XP only.

8.4 XP and levels

XP per game: 20 for finishing, +30 for a win, ×1.5 in tiers Silver and above. No XP for games abandoned.

Level n requires 100 × n² total XP (level 10 ≈ 10,000 XP ≈ 200 games).

8.5 Wallet integrity

Double-entry ledger: every coin movement is a WalletTx row with a debit and credit account (user, HOUSE_RAKE, HOUSE_BOT, HOUSE_REWARDS, HOUSE_IAP).

Table entry = hold (reserved) → settle in one DB transaction at GAME_END; holds older than 2 hours auto-release.

Idempotency key on every settle (matchId:userId) so a retry never pays twice.

Nightly job checks that the sum of all accounts is zero and alerts on mismatch.

8.6 Ads (v1.x, slots reserved now)

Rewarded video: "+500 coins", "double today's daily bonus", "rescue coins".

Interstitial: at most once every 3 completed games, never during a game or within 60 s of app open.

Banner: lobby only. No ads for 24 hours after any IAP.

Use Google AdMob with UMP consent; the code path ships in v1 behind a remote-config flag set to off.

9. Data model

PostgreSQL holds durable data (accounts, wallets, history); Redis holds anything live (tables, queues, presence). The Prisma schema below is the starting point for packages/db.

enum GameId { CALLBREAK MARRIAGE TEEN_PATTI KITTI DHUMBAL JUTPATTI NEPALI_RUMMY JOKER_RUMMY }enum AuthProvider { GUEST GOOGLE PHONE }enum UserStatus { ACTIVE MUTED BANNED }enum MatchMode { QUICK PRIVATE }enum WalletAccountType { USER HOUSE_RAKE HOUSE_BOT HOUSE_REWARDS HOUSE_IAP }enum TxKind { SIGNUP DAILY CHEST RESCUE LEVEL_UP FIRST_WIN REFERRAL HOLD RELEASE SETTLE RAKE AD_REWARD IAP ADMIN_ADJUST }model User {  id          String   @id @default(cuid())  displayName String  avatarId    Int      @default(0)  language    String   @default("en")   // "en" | "ne"  country     String?  xp          Int      @default(0)  level       Int      @default(1)  rating      Int      @default(1200)  status      UserStatus @default(ACTIVE)  createdAt   DateTime @default(now())  lastSeenAt  DateTime?  identities  AuthIdentity[]  wallet      WalletAccount?  devices     Device[]  stats       GameStat[]  matchSeats  MatchPlayer[]}model AuthIdentity {  id         String @id @default(cuid())  userId     String  provider   AuthProvider  providerId String          // firebase uid / device id  phone      String?  email      String?  user       User   @relation(fields: [userId], references: [id])  @@unique([provider, providerId])}model Device {  id        String @id @default(cuid())  userId    String  fcmToken  String?  platform  String          // android | ios  appVersion String  ipHash    String?  user      User   @relation(fields: [userId], references: [id])}model WalletAccount {  id       String @id @default(cuid())  type     WalletAccountType  userId   String? @unique  balance  BigInt  @default(0)  held     BigInt  @default(0)  user     User?   @relation(fields: [userId], references: [id])}model WalletTx {  id             String  @id @default(cuid())  kind           TxKind  debitAccount   String  creditAccount  String  amount         BigInt  matchId        String?  idempotencyKey String  @unique  meta           Json?  createdAt      DateTime @default(now())  @@index([debitAccount, createdAt])  @@index([creditAccount, createdAt])}model Match {  id         String   @id @default(cuid())  game       GameId  mode       MatchMode  tier       String?  rules      Json  seedHash   String  seed       String  moveLog    Json          // compressed array of moves  startedAt  DateTime  endedAt    DateTime  players    MatchPlayer[]  @@index([game, endedAt])}model MatchPlayer {  id        String  @id @default(cuid())  matchId   String  userId    String?        // null for bots  botLevel  String?  seat      Int  points    Float  coinDelta BigInt  placement Int  match     Match   @relation(fields: [matchId], references: [id])  user      User?   @relation(fields: [userId], references: [id])  @@index([userId])}model GameStat {  userId  String  game    GameId  played  Int @default(0)  won     Int @default(0)  bestWin BigInt @default(0)  user    User @relation(fields: [userId], references: [id])  @@id([userId, game])}model Friendship {  userId    String  friendId  String  status    String          // pending | accepted | blocked  createdAt DateTime @default(now())  @@id([userId, friendId])}model DailyReward {  userId      String    @id  streak      Int  lastClaimAt DateTime  chestAt     DateTime?}model Report {  id         String   @id @default(cuid())  reporterId String  reportedId String  matchId    String?  reason     String  status     String   @default("open")  createdAt  DateTime @default(now())}model AdminUser {  id           String  @id @default(cuid())  email        String  @unique  role         String          // owner | moderator | support  passwordHash String  totpSecret   String?}model AuditLog {  id        String   @id @default(cuid())  adminId   String  action    String  target    String  meta      Json?  createdAt DateTime @default(now())}model RemoteConfig {  key       String   @id  value     Json  updatedAt DateTime @updatedAt}

Redis keys



| Key | Type | Content | TTL |

| --- | --- | --- | --- |

| table:{id} | Hash | Serialised state, version, owner | 1 h after end |

| table:{id}:moves | Stream | Move log | 1 h after end |

| table:{id}:owner | String | Instance id (lock) | 10 s, renewed |

| mm:{game}:{tier} | Sorted set | userId by rating | — |

| room:{code} | Hash | Room config, seats | 30 min idle |

| presence:{userId} | String | online / in-table id | 60 s, heartbeat |

| lb:{game}:week:{isoWeek} | Sorted set | userId by coins won | 8 weeks |

| lb:{game}:all | Sorted set | userId by rating | — |

| rl:{userId} | String | Rate-limit counter | 1 s |



10. App screens and UX

The app is portrait for the lobby and landscape for every game table; the look is modern and clean with Nepali touches (dhaka-pattern accents, crimson + deep-blue palette, Devanagari headings in Nepali mode).

10.1 Screen list



| # | Screen | Key contents |

| --- | --- | --- |

| 1 | Splash | Logo, version check (force-update via remote config), silent login |

| 2 | Onboarding | Language choice, 3 swipe cards, "Play as guest" / Google / Phone |

| 3 | Phone OTP | Number with +977 default, 6-digit code, resend after 30 s |

| 4 | Profile setup | Display name, avatar picker (24 preset avatars) |

| 5 | Home / Lobby | Coin balance, daily bonus badge, 8 game tiles (2-column grid), Play with friends, Offline, bottom nav: Home · Friends · Leaderboard · Profile |

| 6 | Game detail | Mode picker (Quick / Private / Offline), stake tiers with lock state, How to play, rules summary |

| 7 | Matchmaking | Seats filling animation, timer, cancel; bots shown with a robot badge |

| 8 | Create room | Game, stake (incl. friendly 0), seats, bot level, turn timer, all rule toggles grouped (Basic / Advanced) |

| 9 | Join room | 6-character code field, paste from clipboard, deep-link entry |

| 10 | Room lobby | Seats, host controls (kick, add bot, swap), share code (WhatsApp, Viber, Messenger, copy), Start |

| 11 | Game table (×8 variants) | Shared shell + per-game layout (10.2) |

| 12 | Round result | Per-player points table, coin delta, XP, Next round / Leave |

| 13 | Game result | Placement, coins won, Rematch (15 s), Share result image |

| 14 | Daily rewards | 7-day streak calendar, chest timer, rescue coins |

| 15 | Friends | List with online status, add by ID/QR, requests, invite to room |

| 16 | Leaderboard | Per game, Weekly / All-time tabs, my rank pinned |

| 17 | Profile & stats | Level, XP bar, per-game played/won/best win, match history (last 50) |

| 18 | Settings | Language, sound, music, vibration, card style, table theme, play direction default, low-data mode, account linking, delete account, privacy policy, terms |

| 19 | How to play | Per-game rules with illustrated examples, interactive tutorial for Callbreak and Marriage |

| 20 | Offline setup | Game, number of bots, difficulty, rules |



10.2 Game table layout (shared shell)

Top bar: back (leave with confirm), pot / round number, rules info, settings, emoji/quick-chat.

Seats: avatar, name, coin balance or score, turn ring timer, connection dot, bot badge; positions arranged so play direction is visually clear.

Centre: trick area (Callbreak), stock + discard pile (Marriage, Dhumbal, Jutpatti, Rummies), pot + chips (Teen Patti), show area (Kitti).

My hand: fan at bottom; tap to select, drag to reorder; legal cards highlighted, illegal dimmed; auto-sort button (by suit / by rank / by melds).

Action bar: context buttons per game (Bid 1–8, Show, See maal, Declare, Chaal / Pack / Side show / Show, Jhyap, Fold).

Per-game extras: Marriage meld tray with grouping slots and a live points estimate after seeing the maal; Kitti arrange board with 3 slots of 3 and a "best arrangement" helper; Rummy meld tray with validity badges; Callbreak tricks-won vs call counter.

Animations: deal, flip, slide to centre, trick sweep, chip toss; 60 fps target; a "reduce motion" setting.

Sound: card snap, shuffle, your-turn chime, win jingle; Nepali festival music loop in lobby (toggle).

10.3 Flutter architecture

Feature-first folders: lib/features/{auth,lobby,matchmaking,room,table,games/<game>,wallet,friends,leaderboard,profile,settings}.

Riverpod providers: socketProvider (single connection, auto-reconnect with backoff), tableControllerProvider(tableId) (AsyncNotifier holding PublicView, applies table:event patches, exposes sendMove), walletProvider, authProvider.

Offline mode uses the same TableController interface backed by a LocalTableEngine (Dart port + Dart bots running in an isolate), so game UI code is identical online and offline.

Card rendering: custom widgets with SVG card faces (one asset set, 2 card back styles at launch).

Low-data mode: no avatars from network, compressed events, reduced animations.

10.4 Localization

easy_localization with en.json and ne.json; every string keyed, no hard-coded text.

Nepali numerals optional (१२३) in Nepali mode for coins and scores.

Game terms keep their common names in both languages (Tiplu, Jhiplu, Poplu, Maal, Chaal, Jhyap), with a glossary in How to play.

Fonts: Mukta (Devanagari + Latin).

11. Admin panel

A Next.js web app (apps/admin) for operating the game, talking to /admin/* REST endpoints on the server; every write is recorded in AuditLog.

Access. Email + password + TOTP 2FA. Roles: Owner (everything), Moderator (users, reports, bans, live tables), Support (read-only + coin adjustments up to 10,000 with a reason).



| Page | Features |

| --- | --- |

| Dashboard | Online now, live tables per game, DAU/MAU, new signups, coins issued vs raked (today, 7 d, 30 d), server health |

| Users | Search by id/name/phone, profile, devices, wallet ledger, match history, linked accounts |

| User actions | Adjust coins (reason required), mute chat, ban (duration + reason), force logout, reset name/avatar |

| Live tables | List with game, tier, seats, age; open a spectator view (all hands visible to admins only), force-end with refund |

| Matches | Search past matches, replay from move log, verify seed hash |

| Reports | Queue of player reports with match link; resolve / ban / dismiss |

| Fraud signals | Same-IP tables, chip-dumping pairs, win-rate outliers; mark reviewed |

| Economy | Edit reward amounts, tier stakes, rake %, daily bonus table (stored in RemoteConfig, effective without deploy) |

| Game config | Enable/disable a game, default rules per game for quick match, turn timers, bot fill delay |

| Announcements | In-app banner + FCM push to all / segment, scheduled |

| App versions | Minimum supported version (force update), maintenance mode toggle |

| Admins | Invite, roles, audit log viewer |



12. Non-functional requirements, testing and deployment

The rules engine carries the most risk, so it gets the strictest tests: every rule in section 5 needs at least one fixture test before its UI is built.

12.1 Non-functional requirements



| Area | Requirement |

| --- | --- |

| Latency | Move → broadcast p95 < 150 ms server-side; < 250 ms end-to-end in Nepal |

| Availability | 99.5% monthly; planned maintenance announced in-app 24 h ahead |

| App size | Android APK < 40 MB (per-ABI split), iOS < 60 MB |

| Performance | 60 fps on a 3 GB RAM Android (Snapdragon 6-series / Helio G85 class); cold start < 3 s |

| Network | Playable on 3G (200 kbps); reconnect within 3 s of network return |

| Min OS | Android 7.0 (API 24), iOS 13 |

| Security | TLS everywhere, JWT 15 min + refresh 30 d (rotated), secrets in env/Vault, OWASP top-10 review before launch |

| Privacy | Phone numbers stored encrypted at rest; account deletion within 7 days (Play/App Store requirement); privacy policy + terms in both languages |

| Age | 17+ / Teen Patti marked "simulated gambling" in store listings; age gate (18+) at onboarding |

| Accessibility | Colour-blind safe suit colours option (4-colour deck), text scale up to 1.3×, reduce motion |

| Observability | Structured logs (pino), traces on move handling, Sentry on server + app, Grafana dashboards: online users, tables, move latency, errors |



12.2 Testing



| Layer | Tooling | Must cover |

| --- | --- | --- |

| Rules engine (TS) | Vitest + fast-check (property tests) | Every rule and toggle; scoring examples from section 5; invariants (card count constant, no duplicate ids, legalMoves always non-empty for the actor) |

| Rules parity (Dart) | dart test on shared fixtures | Same fixture results as TS |

| Bots | Simulation harness (pnpm sim --game callbreak --n 100000) | 0 illegal moves, win-rate targets (6.6), time budget |

| Server | Jest + Supertest + socket.io-client | Matchmaking, reconnect, timeouts, settlement idempotency, wallet sum-to-zero |

| Load | k6 / Artillery with socket scenarios | 5,000 concurrent clients, 1,500 tables, p95 latency targets |

| App | Flutter widget + golden tests; integration_test on 2 Android + 1 iOS device | Each table screen, reconnect banner, localization snapshots |

| Manual | Beta group of 50 Nepali players (Play internal testing / TestFlight) | Rules feel "right" to real players, especially Marriage and Kitti house rules |



12.3 CI/CD and deployment

Turborepo pipelines: lint, typecheck, test, build with remote caching; Flutter tasks via apps/mobile/package.json scripts calling flutter analyze, flutter test, flutter build.

GitHub Actions: on PR → lint + tests + parity fixtures + 10,000-game bot sim; on main → build Docker images (server, admin), push to registry, deploy to staging; manual approval → production.

Mobile release: Fastlane lanes for Play Console (internal → closed → production) and App Store Connect (TestFlight → release). Versioning MAJOR.MINOR.PATCH+build.

Environments: local (docker-compose: postgres, redis, server, admin), staging, production, each with its own Firebase project.

Infra (v1): one VPS (8 vCPU / 16 GB) in Singapore or Mumbai region (lowest latency to Nepal), Docker Compose: nginx, server ×2–4, admin, postgres (daily backups to object storage, point-in-time recovery), redis (AOF on), prometheus, grafana.

Feature flags & remote config: served from RemoteConfig table + Firebase Remote Config on the client (ads, new games, maintenance mode).

13. Build phases for Antigravity

Build in this order, one phase per Antigravity session; each phase ends with its acceptance check passing before the next starts. Give Antigravity this whole PRD plus the phase number as context every time.

Phase 0 — Monorepo foundation. Turborepo + pnpm + Melos, packages/config, packages/db (Prisma schema from section 9), packages/protocol with Zod schemas + Dart codegen, docker-compose (postgres, redis), GitHub Actions skeleton. Accept: pnpm turbo build test green; flutter analyze green.

Phase 1 — Rules engine core + Callbreak. Card model, seeded shuffle, GameModule interface, Callbreak with all toggles, fixtures. Accept: 100% branch coverage on Callbreak; random-move simulation of 100,000 games with no errors.

Phase 2 — Server core. Auth (Firebase verify → JWT, guest), wallet ledger with holds/settle, table runtime + timers + reconnect, Socket.IO gateway, matchmaking with bot fill, Easy/Medium Callbreak bots. Accept: 4 scripted socket clients finish a Callbreak game; killing a server instance mid-game resumes the table.

Phase 3 — Flutter app shell + Callbreak online. Auth screens, lobby, matchmaking, Callbreak table, results, settings, en/ne strings. Accept: full Callbreak game on two phones + 2 bots; reconnect after airplane mode.

Phase 4 — Remaining 3-card and simple games. Teen Patti (all variants), Kitti, Dhumbal, Jutpatti: engine + bots + table UIs. Accept: each game playable online and vs bots; HandEvaluator3 verified against all 22,100 hands.

Phase 5 — Rummy family. MeldSolver, Nepali Rummy, Joker Rummy, then Marriage (all modes, dublee route, Man/Alter toggles, settlement formula). Accept: Marriage scoring fixtures match hand-calculated examples for Classic, Murder and Kidnap.

Phase 6 — Private rooms + social. Room create/join/codes/deep links, host controls, rule toggles UI, friends, quick chat, emoji, leaderboards, daily rewards, XP/levels. Accept: friends can create a Marriage room with custom rules via a WhatsApp-shared link.

Phase 7 — Offline mode. Dart port of the engine for all 8 games, parity fixtures, Dart bots in an isolate. Accept: all parity fixtures pass; every game playable in airplane mode.

Phase 8 — Hard bots. ISMCTS for Callbreak, Marriage, Rummies; Monte Carlo equity for Teen Patti. Accept: win-rate targets in 6.6.

Phase 9 — Admin panel. All pages in section 11 with roles and audit log. Accept: coin adjustment and ban flow end-to-end, visible in audit log.

Phase 10 — Hardening + launch. Load test, security review, store assets (en/ne screenshots), privacy policy, beta with 50 players, fixes. Accept: NFR targets in 12.1 met; Play Store and App Store approval.

14. Social, Deep Linking & Guest/Google Multiplayer Integration (v1.1 / Wave 8)

14.1 Authentication & Guest Support
- Play as Guest: 1-tap device-bound login with 10,000 starting coins, auto-generated unique 6-character `friendCode` (excluding 0, O, 1, I), and full multiplayer capabilities (rooms, tables, friends).
- Continue with Google: Google OAuth / ID token verification (`POST /auth/google`).
- Guest-to-Google Account Linking: 1-tap upgrade from profile modal merges the Google identity into the existing user record, preserving 100% of coins, friends, level, and match history.
- Profile Sheet: View friend code, copy/share pill, account badge (Guest vs Google Verified), and logout.

14.2 Deep Linking & Invite Links
- URI Schemes: `patii://room/<CODE>`, `patii://friend/<FRIEND_CODE>`.
- HTTPS Universal / App Links: `https://patii.app/r/<CODE>` and `https://patii.app/f/<FRIEND_CODE>`.
- Smart Landing Controller (`/r/:code`, `/f/:friendCode`): Serves rich OpenGraph preview cards for WhatsApp/Viber/Messenger, executes `patii://` deep link, provides "Copy Code" fallback.
- Assetlinks & Apple App Site Association served from server root.

14.3 Friends & Presence System
- SocialModule: Track live presence (`online`, `in_room`, `in_table`, `offline`).
- Viral Friend Links: Auto-connect mutual friendship on opening shared invite link (`POST /social/friends/connect-link`).
- Manual Friend Requests: Send request via 6-character friend code or user ID. Accept/decline management.
- In-App Table Invites: 1-tap invite from Friends list or Room Lobby sends instant in-app banner with sound/haptics to online friends.

14.4 Multi-Game Real-Time Table & Room Gateway
- Socket.IO Gateway wired with `room:create`, `room:join`, `room:leave`, `room:addBot`, `room:kick`, `room:start`, `room:invite_friend`.
- Authoritative multi-game TableRuntime supporting all 8 card games dynamically.
- Room lobby UI on mobile with real-time seat sync, bot addition, share link, and auto-transition to landscape game table on start.

14.5 Location-Based Discovery: "Players Around Me" (वरिपरि रहेका खेलाडीहरू)
- Detect & list active card game players in the neighborhood (within 500m to 10km radius).
- Privacy & safety: Opt-in visibility toggle ("Discoverable nearby"), coarse geohashing/approximate distance ("~350m away"), zero exact GPS coordinates exposed or shared with other players, 15-minute TTL on temporary spatial records.
- Actions: 1-tap "Add Friend" and "Invite to Table" directly from nearby radar results.
- Endpoints: `POST /social/nearby/location`, `GET /social/nearby`, `POST /social/nearby/toggle-visibility`.
- Mobile UX: Animated radar pulse scanner in Friends screen with distance pills and status indicators.

Tips for working with Antigravity

Keep the rules engine phase strictly separate from UI; ask it to write tests first from the rule text in section 5.

Paste the exact toggle table for the game being built so every toggle becomes a typed field.

Ask for one game module at a time; review its fixtures against the worked examples before moving on.

Never let generated client code decide outcomes; any rule logic in Flutter outside patii_engine is a bug.

Open questions

☐ Confirm the app name spelling: "Patii" or "Patti"? (affects package ID, store listing, domain)

☐ Marriage tiplu double value: 8 (used here, common in Nepali apps) or 7 (Pagat)? Confirm with beta players.

☐ Dhumbal default card values: J/Q/K = 11/12/13 (app style, used here) or J = 0, Q = K = 10 (Pagat's Nepali variant)?

☐ Callbreak default scoring: Nepali app style (used here) or Pagat classic?

☐ Domain for deep links (patii.app or a .com.np domain).

☐ Store category and age rating strategy for Teen Patti (some regions restrict simulated gambling).

Sources

Rules researched on 2026-11-15 from: Pagat – Card games in Nepal, Pagat – Marriage, Pagat – Call Bridge, Pagat – Yaniv / Jhyap, Gambiter – Marriage variations (Murder, Kidnap, Alter), Bhoos – Marriage guide, Bhoos – Kitti guide, Bhoos – Kitti FAQ, Skich – Kitti rankings, Cats at Cards – Jut Patti, Hamro Patro – Jutpatti, GameRules – Teen Patti variations, Wikipedia – Indian Rummy / Paplu, App Store – Yarsa 12-in-1.