# Eco Wallet

Eco Wallet is a campus sustainability app for UniFacens (UPX 3): members photograph used cooking-oil bottles, earn coins when submissions are approved, and spend coins on scratch-card rewards; operators use a web admin console to verify photos, run audits, and manage reward campaigns. The monorepo ships a Flutter member app, a Next.js admin site, and an Express API backed by Supabase (Postgres, Auth, Storage, and RPCs).

## Stack

| App | Path | Tech |
| ----- | ----- | ----- |
| Mobile | `apps/mobile` | Flutter |
| Web | `apps/web` | Next.js (App Router, TypeScript, Tailwind) |
| API | `apps/api` | Node.js, Express, TypeScript |
| Database | `supabase/` | Supabase (Postgres, Auth, Storage, migrations) |

## Monorepo tooling

- **[pnpm workspaces](https://pnpm.io/workspaces)** — installs and links the JS/TS packages (`apps/web`, `apps/api`, future `packages/*`).
- **[Turborepo](https://turbo.build)** — runs `dev`, `build`, `lint`, and `typecheck` across those apps with caching.

Flutter lives in the same repo but is **not** part of the pnpm workspace (different toolchain). If you later add multiple Dart packages, consider **[Melos](https://melos.invertase.dev/)** for the Flutter side.

## Prerequisites

- Node.js ≥ 20
- [pnpm](https://pnpm.io) 10+
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (runs the local Supabase stack)
- [Flutter](https://flutter.dev) SDK (see `apps/mobile/.fvmrc` if using FVM)
- Xcode / Android Studio (for mobile builds)

## Getting started

### 1. Install dependencies

```bash
pnpm install
```

### 2. Start Supabase locally

From the repository root (requires Docker running):

```bash
pnpm dlx supabase start
pnpm dlx supabase db reset
pnpm dlx supabase seed buckets
```

- `start` — launches local Postgres, Auth, Storage, and the REST API (default API port **54321**).
- `db reset` — applies migrations in `supabase/migrations/` and loads `supabase/seed.sql`.
- `seed buckets` — creates the `disposal-photos` storage bucket from `supabase/config.toml`.

Optional: load extra demo members and disposal queue data:

```bash
pnpm dlx supabase db execute --file supabase/seed.demo.sql
```

See [`supabase/README.md`](supabase/README.md) for admin setup, demo accounts, cloud deployment, and database tests.

Print local URLs and keys anytime:

```bash
pnpm dlx supabase status
```

Use the **API URL**, **anon** (publishable) key, and **service_role** key from that output in the app env files below. Local API URL is typically `http://127.0.0.1:54321`.

### 3. Configure app environment

Copy each app's example env and fill in values from `supabase status` (local) or the Supabase Dashboard (cloud).

| App | File | Notes |
| ----- | ----- | ----- |
| Web | `apps/web/.env` | Copy from `apps/web/.env.example` |
| API | `apps/api/.env` | Copy from `apps/api/.env.example` |
| Mobile | `apps/mobile/.env` | Copy from `apps/mobile/.env.example` |

**Local development (typical):**

`apps/web/.env`

```env
NEXT_PUBLIC_SUPABASE_URL=http://127.0.0.1:54321
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=<anon-key-from-supabase-status>
NEXT_PUBLIC_API_BASE_URL=http://localhost:3001
SUPABASE_SERVICE_ROLE_KEY=<service-role-key-from-supabase-status>
```

`apps/api/.env`

```env
SUPABASE_URL=http://127.0.0.1:54321
SUPABASE_PUBLISHABLE_KEY=<anon-key-from-supabase-status>
SUPABASE_SERVICE_ROLE_KEY=<service-role-key-from-supabase-status>
PORT=3001
```

`apps/mobile/.env`

```env
SUPABASE_URL=http://127.0.0.1:54321
SUPABASE_PUBLISHABLE_KEY=<anon-key-from-supabase-status>
API_BASE_URL=http://127.0.0.1:3001
```

On the **Android emulator**, use `http://10.0.2.2:3001` for `API_BASE_URL` so the device can reach the host API. Never commit `.env` files or expose `SUPABASE_SERVICE_ROLE_KEY` in Flutter or browser bundles.

**Admin web:** there is no default admin user in seeds. Create a user in Supabase Studio (local: `http://127.0.0.1:54323`) or Dashboard, then set `profiles.role = 'admin'` — steps in [`supabase/README.md`](supabase/README.md).

### 4. Run the apps

```bash
# Web + API (from repo root)
pnpm dev

# Mobile (separate terminal; hot restart after .env changes)
cd apps/mobile
flutter run --dart-define-from-file=.env
```

Or run JS/TS apps individually:

```bash
pnpm --filter @eco-wallet/web dev
pnpm --filter @eco-wallet/api dev
```

### Ports (default)

| Service | URL |
| -------- | ----- |
| Web | <http://localhost:3000> |
| API | <http://localhost:3001> (`GET /health`) |
| Supabase API | <http://127.0.0.1:54321> |
| Supabase Studio | <http://127.0.0.1:54323> |

### Supabase commands (reference)

| Command | Description |
| -------- | ------------- |
| `pnpm dlx supabase start` | Start local stack |
| `pnpm dlx supabase stop` | Stop local stack |
| `pnpm dlx supabase status` | Show URLs and keys |
| `pnpm dlx supabase db reset` | Reapply migrations + `seed.sql` |
| `pnpm dlx supabase test db` | Run SQL tests in `supabase/tests/` |

Cloud setup: [`supabase/docs/cloud-deployment-plan.md`](supabase/docs/cloud-deployment-plan.md) and [`supabase/docs/cloud-env-checklist.md`](supabase/docs/cloud-env-checklist.md).

## Scripts (root)

| Command | Description |
| --------- | ------------- |
| `pnpm dev` | Start web + API in dev mode |
| `pnpm build` | Build web + API |
| `pnpm lint` | Lint web + API |
| `pnpm typecheck` | Typecheck web + API |

## Project layout

```text
eco-wallet/
├── apps/
│   ├── mobile/     # Flutter member app
│   ├── web/        # Next.js admin app
│   └── api/        # Express API
├── supabase/       # migrations, seeds, local config
├── packages/       # shared TS libs (future)
├── package.json
├── pnpm-workspace.yaml
└── turbo.json
```

## Authors

- Luiz Miguel Jarduli Jarduli
- Giovanna Antunes de Campos
- Leonardo Hipolito Trevisi
- Gabriel Ribeiro Lattri
