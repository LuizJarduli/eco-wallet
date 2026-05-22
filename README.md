# eco-wallet

UniFacens project from course UPX 3 — monorepo for mobile, web, and API.

## Stack

| App | Path | Tech |
| ----- | ----- | ----- |
| Mobile | `apps/mobile` | Flutter |
| Web | `apps/web` | Next.js (App Router, TypeScript, Tailwind) |
| API | `apps/api` | Node.js, Express, TypeScript |

## Monorepo tooling

- **[pnpm workspaces](https://pnpm.io/workspaces)** — installs and links the JS/TS packages (`apps/web`, `apps/api`, future `packages/*`).
- **[Turborepo](https://turbo.build)** — runs `dev`, `build`, `lint`, and `typecheck` across those apps with caching.

Flutter lives in the same repo but is **not** part of the pnpm workspace (different toolchain). If you later add multiple Dart packages, consider **[Melos](https://melos.invertase.dev/)** for the Flutter side.

## Prerequisites

- Node.js ≥ 20
- [pnpm](https://pnpm.io) 10+
- [Flutter](https://flutter.dev) SDK
- Xcode / Android Studio (for mobile builds)

## Getting started

```bash
# Install JS/TS dependencies (from repo root)
pnpm install

# Run all JS/TS apps in dev mode (web + api)
pnpm dev

# Or run individually
pnpm --filter @eco-wallet/web dev
pnpm --filter @eco-wallet/api dev
cd apps/mobile && flutter run
```

### Ports (default)

- Web: <http://localhost:3000>
- API: <http://localhost:3001> (`GET /health`)

## Scripts (root)

| Command | Description |
| --------- | ------------- |
| `pnpm dev` | Start web + API in dev mode |
| `pnpm build` | Build web + API |
| `pnpm lint` | Lint web + API |
| `pnpm typecheck` | Typecheck web + API |

## Project layout

```sh
eco-wallet/
├── apps/
│   ├── mobile/     # Flutter app
│   ├── web/        # Next.js app
│   └── api/        # Express API
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
