# Patii - Real-Time Card Gaming Platform

[![Backend CI & Deploy](https://github.com/kirtanjoshi/Patti/actions/workflows/backend-deploy.yml/badge.svg)](https://github.com/kirtanjoshi/Patti/actions/workflows/backend-deploy.yml)
[![Version](https://img.shields.io/badge/version-1.1.0-gold.svg)](CHANGELOG.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A high-performance, real-time multiplayer card gaming platform featuring Nepali and South Asian card games (Callbreak, Marriage, Teen Patti, Kitti, Dhumbal, Jutpatti, Nepali Rummy, and Joker Rummy).

---

## 🚀 Features

- **8 Authentic Card Games**: Full rules engines, deterministic bots, and live multi-seat tables.
- **"Players Around Me" (Nearby Radar)**: Privacy-preserving coarse geohash discovery (~110m resolution) to find and challenge local card players.
- **Authentication & Guest-to-Google Linking**: 1-tap Guest login with starting coins; seamless upgrade to Google without losing progress, stats, or friends.
- **Viral Social System**: Deep linking (`patii://` & `https://patii.app/r/<code>`), WhatsApp/Viber invite cards, friend presence, and instant table invites.
- **24/7 Keep-Alive Architecture**: Automatic database and server heartbeat pings preventing Supabase / cloud hosts from sleeping.
- **Automated CI/CD**: Dual-pipeline GitHub Actions testing backend (Node 22 / Vitest) and mobile (Flutter 3.29), with automated Render deployment.

---

## 🏗️ Architecture

```
Patti/
├── apps/
│   ├── mobile/         # Flutter 3.29 cross-platform mobile client
│   ├── server/         # NestJS 10 + Socket.IO real-time game server
│   └── admin/          # Next.js 15 back-office management console
├── packages/
│   ├── game-engine/    # Pure TypeScript card game state engines
│   ├── bots/           # Deterministic heuristic bots for all 8 games
│   ├── protocol/       # Shared Zod schemas + generated Dart models
│   ├── db/             # Prisma ORM + PostgreSQL schema & migrations
│   └── dart/           # Auto-generated Dart protocol package
└── .github/workflows/  # CI/CD pipelines & deployment automation
```

---

## 🛠️ Quick Start

### Prerequisites
- Node.js 22+ & pnpm 10.32.1 (`npm install -g pnpm`)
- Flutter 3.29+ & Dart 3.7+
- PostgreSQL 16 (or Supabase)

### 1. Backend Server Setup
```bash
# Install all workspace dependencies
pnpm install

# Generate Prisma client
pnpm db:generate

# Build workspace dependencies and start server in dev mode
pnpm --filter @patii/server dev
```
Health endpoint: `http://localhost:4000/health` (or `http://localhost:4000/health/ping`).

### 2. Mobile App Setup
```bash
cd apps/mobile
flutter pub get
flutter run
```

---

## 🚢 CI/CD & Deployment

- **GitHub Actions**: Tests every pull request and push to `main` across backend and mobile test suites.
- **Render Deployment**: Auto-deploys via `render.yaml` or Render Deploy Hooks.

See [CHANGELOG.md](CHANGELOG.md) for full release history.
