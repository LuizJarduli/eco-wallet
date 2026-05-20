# Supabase Local Bootstrap

This directory contains the local Supabase foundation for UniFacens EcoWallet.

## Setup

Run the local stack from the repository root:

```bash
pnpm dlx supabase start
pnpm dlx supabase db reset
pnpm dlx supabase seed buckets
pnpm dlx supabase test db
```

`db reset` applies migrations and loads `seed.sql`. `seed buckets` reconciles the
`disposal-photos` bucket declared in `config.toml`.

## App Environment Variables

Frontend and mobile clients need:

```env
SUPABASE_URL=
SUPABASE_ANON_KEY=
```

Server-only code in `apps/api` also needs:

```env
SUPABASE_SERVICE_ROLE_KEY=
```

Never expose `SUPABASE_SERVICE_ROLE_KEY` in Flutter, Next.js browser code, or any
public environment variable.

## Cloud deployment

After local `supabase test db` passes:

1. Read `docs/cloud-deployment-plan.md` (reset vs migrate, rollback, smoke checks).
2. Link the project: `pnpm dlx supabase link --project-ref <ref>`.
3. Push migrations: `pnpm dlx supabase db push`.
4. Seed production defaults: `pnpm dlx supabase db execute --file supabase/seed.production.sql`.
5. Configure apps using `docs/cloud-env-checklist.md` and each app's `.env.example`.
6. Run `scripts/cloud-smoke-check.sql` on the cloud database.
